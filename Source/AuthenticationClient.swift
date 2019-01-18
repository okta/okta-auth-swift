//
//  OktaAuth.swift
//  OktaAuth iOS
//
//  Created by Alex Lebedev on 12 Dec 18.
//

import Foundation

public protocol AuthenticationClientDelegate: class {
    func handleSuccess(sessionToken: String)

    func handleError(_ error: OktaError)

    func handleChangePassword(canSkip: Bool, callback: @escaping (_ old: String?, _ new: String?, _ skip: Bool) -> Void)

    func handleMultifactorAuthenication(callback: @escaping (_ code: String) -> Void)
    
    func handleAccountLockedOut(callback: @escaping (_ username: String, _ factor: FactorType) -> Void)
    
    func handleRecoveryChallenge(factorType: FactorType?, factorResult: FactorResult?)
    
    func transactionCancelled()
}

/// Our SDK provides default state machine implementation,
/// but developer able to implement custom handler by implementing
/// `OktaStateMachineHandler` protocol. If `statusHandler` property set,
/// `AuthenticationClient.handleStatusChange()` will not be called.

public protocol AuthenticationClientStatusHandler: class {
    func handleStatusChange()
}

/// AuthenticationClient class is main entry point for developer

public class AuthenticationClient {

    public init(oktaDomain: URL, delegate: AuthenticationClientDelegate) {
        self.delegate = delegate
        self.api = OktaAPI(oktaDomain: oktaDomain)
    }

    public weak var delegate: AuthenticationClientDelegate?
    public weak var statusHandler: AuthenticationClientStatusHandler? = nil

    public func authenticate(username: String, password: String, deviceFingerprint: String? = nil) {
        guard !inProgress else {
            delegate?.handleError(.alreadyInProgress)
            return
        }
        guard case .unauthenticated = status else {
            delegate?.handleError(.wrongState("'unauthenticated' state expected"))
            return
        }
        inProgress = true
        api.primaryAuthentication(username: username,
                                  password: password,
                                  deviceFingerprint: deviceFingerprint) { [weak self] result in
            self?.inProgress = false
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }

    public func cancel() {
        guard !inProgress else {
            delegate?.handleError(.alreadyInProgress)
            return
        }
        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        inProgress = true
        api.cancelTransaction(stateToken: stateToken) { [weak self] result in
            self?.inProgress = false
            guard let _ = self?.checkAPIResultError(result) else { return }
            self?.resetStatus()
            self?.delegate?.transactionCancelled()
        }
    }
    
    public func updateStatus() {
        guard !inProgress else {
            delegate?.handleError(.alreadyInProgress)
            return
        }
        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        inProgress = true
        api.getTransactionState(stateToken: stateToken) { [weak self] result in
            self?.inProgress = false
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    public func changePassword(oldPassword: String, newPassword: String) {
        guard !inProgress else {
            delegate?.handleError(.alreadyInProgress)
            return
        }
        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        switch status {
            case .passwordExpired, .passwordWarning:
                break
            default:
                delegate?.handleError(.wrongState("'passwordExpired' or 'passwordWarning' state expected"))
                return
        }
        inProgress = true
        api.changePassword(stateToken: stateToken, oldPassword: oldPassword, newPassword: newPassword) { [weak self] result in
            self?.inProgress = false
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    public func unlockAccount(_ username: String, factor: FactorType) {
        api.unlockAccount(username: username, factor: factor) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    public func perform(link: LinksResponse.Link) {
        guard !inProgress else {
            delegate?.handleError(.alreadyInProgress)
            return
        }
        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        inProgress = true
        api.perform(link: link, stateToken: stateToken) { [weak self] result in
            self?.inProgress = false
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    private func updateStatus(response: OktaAPISuccessResponse) {
        status = response.status ?? .unauthenticated
        stateToken = response.stateToken
        sessionToken = response.sessionToken
        links = response.links
        embedded = response.embedded
        factorType = response.factorType
        factorResult = response.factorResult
        performStatusChangeHandling()
    }
    
    public func resetStatus() {
        status = .unauthenticated
        stateToken = nil
        sessionToken = nil
        links = nil
        embedded = nil
        factorResult = nil
        factorType = nil
        performStatusChangeHandling()
    }
    
    public func handleStatusChange() {
        switch status {
            
        case .passwordWarning:
            delegate?.handleChangePassword(canSkip: true, callback: { [weak self] old, new, skip in
                if skip {
                    guard let next = self?.links?.next else {
                        self?.delegate?.handleError(.wrongState("Can't find 'next' link in response"))
                        return
                    }
                    self?.perform(link: next)
                } else {
                    self?.changePassword(oldPassword: old ?? "", newPassword: new ?? "")
                }
            })
            
        case .recoveryChallenge:
            self.delegate?.handleRecoveryChallenge(factorType: self.factorType, factorResult: self.factorResult)
            
        case .passwordExpired:
            delegate?.handleChangePassword(canSkip: false, callback: { [weak self] old, new, skip in
                self?.changePassword(oldPassword: old ?? "", newPassword: new ?? "")
            })
            
        case .MFARequired:
            delegate?.handleMultifactorAuthenication(callback: { code in
                print("Code: \(code)")
            })
            
        case .success:
            guard let sessionToken = sessionToken else {
                delegate?.handleError(.unexpectedResponse)
                return
            }
            delegate?.handleSuccess(sessionToken: sessionToken)
            
        case .lockedOut:
            delegate?.handleAccountLockedOut { [weak self] username, factor in
                self?.unlockAccount(username, factor: factor)
            }
            
        case .unauthenticated:
            break
            
        default:
            delegate?.handleError(.authenicationStatusNotSupported(status))
        }
    }
    
    // MARK: - Internal

    /// Okta REST API client
    public private(set) var api: OktaAPI
    
    public private(set) var inProgress: Bool = false

    /// Current status of the authentication transaction.
    public private(set) var status: AuthStatus = .unauthenticated

    /// Ephemeral token that encodes the current state of an authentication or recovery transaction.
    public private(set) var stateToken: String?

    /// Link relations for the current status.
    public private(set) var links: LinksResponse?

    // Embedded resources for current status
    public private(set) var embedded: EmbeddedResponse?

    /// One-time token issued as recoveryToken response parameter when a recovery transaction transitions to the RECOVERY status.
    public private(set) var recoveryToken: String?

    /// One-time token isuued as `sessionToken` response parameter when an authenication transaction completes with the `SUCCESS` status.
    public private(set) var sessionToken: String?

    /// Factor type that is related to the current state
    public private(set) var factorType: FactorType?
    
    /// Provides additional context for the last factor verification attempt.
    public private(set) var factorResult: FactorResult?

    // MARK: - Private
    
    private func performStatusChangeHandling() {
        if let statusHandler = statusHandler {
            statusHandler.handleStatusChange()
        } else {
            handleStatusChange()
        }
    }
    
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
}
