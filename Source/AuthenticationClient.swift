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
    
    func handleAccountLockedOut(callback: @escaping (_ username: String, _ factor: FactorType) -> Void)

    func handleRecoveryChallenge(factorType: FactorType?, factorResult: OktaAPISuccessResponse.FactorResult?)

    func transactionCancelled()
}

/// Our SDK provides default state machine implementation,
/// but developer able to implement custom handler by implementing
/// `OktaStateMachineHandler` protocol. If `statusHandler` property set,
/// `AuthenticationClient.handleStatusChange()` will not be called.

public protocol AuthenticationClientStatusHandler: class {
    func handleStatusChange()
}

public protocol AuthenticationClientMFAHandler: class {
    func selectFactor(factors: [EmbeddedResponse.Factor], callback: @escaping (_ factor: EmbeddedResponse.Factor) -> Void)

    func pushStateUpdated(_ state: OktaAPISuccessResponse.FactorResult)

    func requestTOTP(callback: @escaping (_ code: String) -> Void)

    func requestSMSCode(phoneNumber: String?, callback: @escaping (_ code: String) -> Void)

    func securityQuestion(question: String, callback: @escaping (_ answer: String) -> Void)
}

/// AuthenticationClient class is main entry point for developer

public class AuthenticationClient {

    public init(oktaDomain: URL, delegate: AuthenticationClientDelegate, mfaHandler: AuthenticationClientMFAHandler?) {
        self.delegate = delegate
        self.mfaHandler = mfaHandler
        self.api = OktaAPI(oktaDomain: oktaDomain)
    }

    public weak var delegate: AuthenticationClientDelegate?
    public weak var statusHandler: AuthenticationClientStatusHandler? = nil
    public weak var mfaHandler: AuthenticationClientMFAHandler? = nil
    
    public var factorResultPollRate: TimeInterval = 3
    
    // MARK: - Internal
    
    /// Okta REST API client
    public internal(set) var api: OktaAPI
    
    public internal(set) weak var currentRequest: OktaAPIRequest?
    
    /// Current status of the authentication transaction.
    public internal(set) var status: AuthStatus = .unauthenticated
    
    /// Ephemeral token that encodes the current state of an authentication or recovery transaction.
    public internal(set) var stateToken: String?
    
    public internal(set) var factorResult: OktaAPISuccessResponse.FactorResult?
    
    /// Link relations for the current status.
    public internal(set) var links: LinksResponse?
    
    /// Embedded resources for current status
    public internal(set) var embedded: EmbeddedResponse?
    
    /// One-time token issued as recoveryToken response parameter when a recovery transaction transitions to the RECOVERY status.
    public internal(set) var recoveryToken: String?
    
    /// One-time token isuued as `sessionToken` response parameter when an authenication transaction completes with the `SUCCESS` status.
    public internal(set) var sessionToken: String?
    
    /// Factor type that is related to the current state
    public private(set) var factorType: FactorType?

    public func authenticate(username: String, password: String, deviceFingerprint: String? = nil) {
        guard currentRequest == nil else {
            delegate?.handleError(.alreadyInProgress)
            return
        }
        guard case .unauthenticated = status else {
            delegate?.handleError(.wrongState("'unauthenticated' state expected"))
            return
        }
        currentRequest = api.primaryAuthentication(username: username,
                                  password: password,
                                  deviceFingerprint: deviceFingerprint) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }

    public func cancelTransaction() {
        if !Thread.isMainThread {
            DispatchQueue.main.async {
                self.cancelTransaction()
            }
            return
        }

        self.factorResultPollTimer?.invalidate()

        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }

        cancelCurrentRequest()
        currentRequest = api.cancelTransaction(stateToken: stateToken) { [weak self] result in
            guard let _ = self?.checkAPIResultError(result) else { return }
            self?.resetStatus()
            self?.delegate?.transactionCancelled()
        }
    }
    
    public func fetchTransactionState() {
        guard currentRequest == nil else {
            delegate?.handleError(.alreadyInProgress)
            return
        }

        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        currentRequest = api.getTransactionState(stateToken: stateToken) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    public func changePassword(oldPassword: String, newPassword: String) {
        guard currentRequest == nil else {
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
        currentRequest = api.changePassword(stateToken: stateToken, oldPassword: oldPassword, newPassword: newPassword) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    public func unlockAccount(_ username: String, factor: FactorType) {
        guard currentRequest == nil else {
            delegate?.handleError(.alreadyInProgress)
            return
        }
        currentRequest = api.unlockAccount(username: username, factor: factor) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }
    
    public func verify(factor: EmbeddedResponse.Factor,
                       answer: String? = nil,
                       passCode: String? = nil,
                       rememberDevice: Bool? = nil,
                       autoPush: Bool? = nil) {
        guard currentRequest == nil else {
            delegate?.handleError(.alreadyInProgress)
            return
        }
        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        currentRequest = api.verifyFactor(factorId: factor.id!,
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
        guard currentRequest == nil else {
            delegate?.handleError(.alreadyInProgress)
            return
        }
        guard let stateToken = stateToken else {
            delegate?.handleError(.wrongState("No state token"))
            return
        }
        currentRequest = api.perform(link: link, stateToken: stateToken) { [weak self] result in
            guard let response = self?.checkAPIResultError(result) else { return }
            self?.updateStatus(response: response)
        }
    }

    public func resetStatus() {
        status = .unauthenticated
        stateToken = nil
        sessionToken = nil
        factorResult = nil
        links = nil
        embedded = nil
        factorType = nil
        performStatusChangeHandling()
    }

    // MARK: - Private
    
    public func cancelCurrentRequest() {
        guard let currentRequest = currentRequest else {
            return
        }
        currentRequest.cancel()
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

        case .lockedOut:
            delegate?.handleAccountLockedOut { [weak self] username, factor in
                self?.unlockAccount(username, factor: factor)
            }

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
            mfaHandler.selectFactor(factors: factors) { factor in
                if factor.factorType == .TOTP {
                    mfaHandler.requestTOTP() { code in
                        self.verify(factor: factor, passCode: code)
                    }
                } else {
                    self.verify(factor: factor)
                }
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
                mfaHandler?.pushStateUpdated(factorResult)
                switch factorResult {
                case .waiting:
                    let timer = Timer(timeInterval: factorResultPollRate, repeats: false) { [weak self] _ in
                        self?.verify(factor: factor)
                    }
                    RunLoop.main.add(timer, forMode: .common)
                    factorResultPollTimer = timer
                default:
                    break
                }
            } else if factorType == .sms {
                let phoneNumber = factor.profile?.phoneNumber
                mfaHandler?.requestSMSCode(phoneNumber: phoneNumber) { code in
                    self.verify(factor: factor, passCode: code)
                }
            } else if factorType == .question {
                guard let question = factor.profile?.questionText else {
                    delegate?.handleError(.wrongState("Can't find 'question' object in response"))
                    return
                }
                mfaHandler?.securityQuestion(question: question) { answer in
                    self.verify(factor: factor, answer: answer)
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

    // MARK: - Private
    
    private var factorResultPollTimer: Timer? = nil
    
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
            return nil
        case .success(let success):
            return success
        }
    }
    
    private func updateStatus(response: OktaAPISuccessResponse) {
        status = response.status ?? .unauthenticated
        stateToken = response.stateToken
        sessionToken = response.sessionToken
        factorResult = response.factorResult
        links = response.links
        embedded = response.embedded
        factorType = response.factorType
        performStatusChangeHandling()
    }
}
