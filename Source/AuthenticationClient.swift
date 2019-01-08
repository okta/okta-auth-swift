//
//  OktaAuth.swift
//  OktaAuth iOS
//
//  Created by Alex Lebedev on 12 Dec 18.
//

import Foundation

public protocol AuthenticationClientDelegate: class {
    func handleSuccess()

    func handleError(_ error: OktaError)

    func handleChangePassword(canSkip: Bool, callback: @escaping (_ old: String?, _ new: String?, _ skip: Bool) -> Void)

    func handleMultifactorAuthenication(callback: @escaping (_ code: String) -> Void)
    
    func transactionCancelled()
}

/// Our SDK provides default state machine implementation,
/// but developer able to implement custom handler by implementing
/// `OktaStateMachineHandler` protocol

public protocol AuthenticationClientStatusHandler: class {
    func handleStatus() // to be extended
}

/// AuthenticationClient class is main entry point for developer

public class AuthenticationClient {

    public init(oktaDomain: URL, delegate: AuthenticationClientDelegate) {
        self.delegate = delegate
        self.api = OktaAPI(oktaDomain: oktaDomain)
    }

    public weak var delegate: AuthenticationClientDelegate?
    public weak var statusHandler: AuthenticationClientStatusHandler? = nil

    public func logIn(username: String, password: String) {
        guard case .unauthenticated = status else { return }
        api.primaryAuthentication(username: username, password: password) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }

    public func cancel() {
        guard let stateToken = stateToken else { return }
        api.cancelTransaction(stateToken: stateToken) { [weak self] result in
            guard let _ = self?.checkAPIResultError(result) else { return }
            self?.resetStatus()
            self?.delegate?.transactionCancelled()
        }
    }
    
    public func updateStatus() {
        guard let stateToken = stateToken else { return }
        api.getTransactionState(stateToken: stateToken) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    public func changePassword(oldPassword: String, newPassword: String) {
        guard let stateToken = stateToken else { return }
        switch status {
            case .passwordExpired, .passwordWarning: break
            default: return
        }
        api.changePassword(stateToken: stateToken, oldPassword: oldPassword, newPassword: newPassword) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }

    // MARK: - Internal

    /// Okta REST API client
    public private(set) var api: OktaAPI

    /// Current status of the authentication transaction.
    public private(set) var status: AuthStatus = .unauthenticated

    /// Ephemeral token that encodes the current state of an authentication or recovery transaction.
    public private(set) var stateToken: String?

    /// Link relations for the current status.
    public private(set) var links: [String: String] = [:]

    // Embedded resources for current status
    public private(set) var embedded: [String: String] = [:]

    /// One-time token issued as recoveryToken response parameter when a recovery transaction transitions to the RECOVERY status.
    public private(set) var recoveryToken: String?

    /// One-time token isuued as `sessionToken` response parameter when an authenication transaction completes with the `SUCCESS` status.
    public private(set) var sessionToken: String?

    // MARK: - Private
    
    private func checkAPIResultError(_ result: OktaAPIRequest.Result) -> OktaAPISuccessResponse? {
        switch result {
        case .error(let error):
            delegate?.handleError(error)
            resetStatus()
            return nil
        case .success(let success):
            return success
        }
    }

    private func updateStatus(response: OktaAPISuccessResponse) {
        print("Updating status with: \(response)")
        status = response.status ?? AuthStatus(raw: "<EMPTY>")
        stateToken = response.stateToken
        handleStatusChange()
    }
    
    private func resetStatus() {
        status = .unauthenticated
        stateToken = nil
        handleStatusChange()
    }

    private func handleStatusChange() {
        print("Handling status change: \(status.description)")

        switch status {
            
        case .passwordWarning:
            delegate?.handleChangePassword(canSkip: true, callback: { [weak self] old, new, skip in
                if skip {
                    // TBD Process `next` link
                    print("*** SKIP ***")
                } else {
                    guard let old = old, let new = new else { return }
                    self?.changePassword(oldPassword: old, newPassword: new)
                }
            })
            
        case .passwordExpired:
            delegate?.handleChangePassword(canSkip: false, callback: { [weak self] old, new, skip in
                guard let old = old, let new = new else { return }
                self?.changePassword(oldPassword: old, newPassword: new)
            })

        case .MFARequired:
            delegate?.handleMultifactorAuthenication(callback: { code in
                print("Code: \(code)")
            })

        case .success:
            delegate?.handleSuccess()

        default:
            delegate?.handleError(.authenicationStatusNotSupported(status))
        }
    }
}
