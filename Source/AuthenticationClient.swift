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
    
    func transactionCancelled()
}

public protocol AuthenticationClientMFAHandler: class {
    func mfaSelecFactor(factors: [EmbeddedResponse.Factor], callback: @escaping (_ index: Int) -> Void)
    
    func mfaPushStateUpdated(_ state: OktaAPISuccessResponse.FactorResult)
    
    func mfaRequestCode(factor: EmbeddedResponse.Factor, callback: @escaping (_ passCode: String) -> Void)
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
    public weak var mfaHandler: AuthenticationClientMFAHandler? = nil
    
    public var factorResultPollRate: TimeInterval = 3

    public func authenticate(username: String, password: String, deviceFingerprint: String? = nil) {
        guard case .unauthenticated = status else {
            delegate?.handleError(.wrongState("'unauthenticated' state expected"))
            return
        }
        api.primaryAuthentication(username: username,
                                  password: password,
                                  deviceFingerprint: deviceFingerprint) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }

    public func cancel() {
        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        api.cancelTransaction(stateToken: stateToken) { [weak self] result in
            guard let _ = self?.checkAPIResultError(result) else { return }
            self?.resetStatus()
            self?.delegate?.transactionCancelled()
        }
    }
    
    public func updateStatus() {
        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        api.getTransactionState(stateToken: stateToken) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    public func changePassword(oldPassword: String, newPassword: String) {
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
        api.changePassword(stateToken: stateToken, oldPassword: oldPassword, newPassword: newPassword) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    public func verify(factor: EmbeddedResponse.Factor,
                       answer: String? = nil,
                       passCode: String? = nil,
                       rememberDevice: Bool? = nil,
                       autoPush: Bool? = nil) {
        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        api.verify(factorId: factor.id!,
                   stateToken: stateToken,
                   answer: answer,
                   passCode: passCode,
                   rememberDevice: rememberDevice,
                   autoPush: autoPush) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    public func perform(link: LinksResponse.Link) {
        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        api.perform(link: link, stateToken: stateToken) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    private func updateStatus(response: OktaAPISuccessResponse) {
        status = response.status ?? .unauthenticated
        stateToken = response.stateToken
        sessionToken = response.sessionToken
        factorResult = response.factorResult
        links = response.links
        embedded = response.embedded
        performStatusChangeHandling()
    }
    
    public func resetStatus() {
        status = .unauthenticated
        stateToken = nil
        sessionToken = nil
        factorResult = nil
        links = nil
        embedded = nil
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
            
        case .passwordExpired:
            delegate?.handleChangePassword(canSkip: false, callback: { [weak self] old, new, skip in
                self?.changePassword(oldPassword: old ?? "", newPassword: new ?? "")
            })
            
        case .MFARequired:
            guard let mfaHandler = mfaHandler else {
                delegate?.handleError(.authenicationStatusNotSupported(status))
                return
            }
            guard let factors = embedded?.factors else {
                delegate?.handleError(.wrongState("Can't find 'factor' object in response"))
                return
            }
            mfaHandler.mfaSelecFactor(factors: factors) { index in
                let factor = factors[index]
                self.verify(factor: factor)
            }
            
        case .MFAChallenge:
            guard let factor = embedded?.factor, let factorType = factor.factorType else {
                delegate?.handleError(.wrongState("Can't find 'factor' object in response"))
                return
            }
            if factorType == .push {
                guard let factorResult = factorResult else {
                    return
                }
                mfaHandler?.mfaPushStateUpdated(factorResult)
                switch factorResult {
                case .waiting:
                    DispatchQueue.main.asyncAfter(deadline: .now() + factorResultPollRate) {
                        self.verify(factor: factor)
                        return
                    }
                default:
                    cancel()
                }
            } else if factorType == .TOTP {
                mfaHandler?.mfaRequestCode(factor: factor) { code in
                    self.verify(factor: factor, passCode: code)
                }
            } else {
                delegate?.handleError(.factorNotSupported(factor))
            }
            
        case .success:
            guard let sessionToken = sessionToken else {
                delegate?.handleError(.unexpectedResponse)
                return
            }
            delegate?.handleSuccess(sessionToken: sessionToken)
            
        case .unauthenticated:
            break
            
        default:
            delegate?.handleError(.authenicationStatusNotSupported(status))
        }
    }
    
    // MARK: - Internal

    /// Okta REST API client
    public private(set) var api: OktaAPI

    /// Current status of the authentication transaction.
    public private(set) var status: AuthStatus = .unauthenticated

    /// Ephemeral token that encodes the current state of an authentication or recovery transaction.
    public private(set) var stateToken: String?
    
    public private(set) var factorResult: OktaAPISuccessResponse.FactorResult?

    /// Link relations for the current status.
    public private(set) var links: LinksResponse?

    // Embedded resources for current status
    public private(set) var embedded: EmbeddedResponse?

    /// One-time token issued as recoveryToken response parameter when a recovery transaction transitions to the RECOVERY status.
    public private(set) var recoveryToken: String?

    /// One-time token isuued as `sessionToken` response parameter when an authenication transaction completes with the `SUCCESS` status.
    public private(set) var sessionToken: String?

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
