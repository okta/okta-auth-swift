//
//  OktaAuth.swift
//  OktaAuth iOS
//
//  Created by Alex Lebedev on 12 Dec 18.
//

import Foundation

public protocol AuthenticationClientDelegate: class {
    func loggedIn()

    func handleError(_ error: OktaError)

    func handleChangePassword(canSkip: Bool, callback: @escaping (_ old: String?, _ new: String?, _ skip: Bool) -> Void)

    func handleMultifactorAuthenication(callback: @escaping (_ code: String) -> Void)
    
    func transactionCancelled()
}

/// Our SDK provides default state machine implementation,
/// but developer able to implement custom handler by implementing
/// `OktaStateMachineHandler` protocol

public protocol AuthenticationClientStateHandler: class {
    func handleState() // to be extended
}

/// AuthenticationClient class is main entry point for developer

public class AuthenticationClient {

    public init(oktaDomain: URL, delegate: AuthenticationClientDelegate) {
        self.delegate = delegate
        self.api = OktaAPI(oktaDomain: oktaDomain)
    }

    public weak var delegate: AuthenticationClientDelegate?
    public weak var stateHandler: AuthenticationClientStateHandler? = nil

    public func logIn(username: String, password: String) {
        guard case .unauthenticated = state else { return }
        api.primaryAuthenication(username: username, password: password) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateState(response: response)
        }
    }

    public func cancel() {
        guard let stateToken = stateToken else { return }
        api.cancelTransaction(stateToken: stateToken) { [weak self] result in
            guard let _ = self?.checkAPIResultError(result) else { return }
            self?.resetState()
        }
    }
    
    public func updateState() {
        guard let stateToken = stateToken else { return }
        api.getTransactionState(stateToken: stateToken) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateState(response: response)
        }
    }
    
    public func changePassword(oldPassword: String, newPassword: String) {
        guard let stateToken = stateToken else { return }
        switch state {
            case .passwordExpired, .passwordWarning: break
            default: return
        }
        api.changePassword(stateToken: stateToken, oldPassword: oldPassword, newPassword: newPassword) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateState(response: response)
        }
    }

    // MARK: - Internal

    /// Okta REST API client
    public private(set) var api: OktaAPI

    /// Current state of the authentication transaction.
    public private(set) var state: AuthState = .unauthenticated

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
            resetState()
            return nil
        case .success(let success):
            return success
        }
    }

    private func updateState(response: OktaAPISuccessResponse) {
        print("Updating state with: \(response)")
        state = AuthState(raw: response.status ?? "<EMPTY>")
        stateToken = response.stateToken
        handleStateChange()
    }
    
    private func resetState() {
        state = .unauthenticated
        stateToken = nil
        handleStateChange()
    }

    private func handleStateChange() {
        print("Handling state change: \(state.description)")

        switch state {
        case .unauthenticated:
            delegate?.transactionCancelled()
            break
            
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
            delegate?.loggedIn()

        default:
            delegate?.handleError(.authenicationStateNotSupported(state))
        }
    }
}
