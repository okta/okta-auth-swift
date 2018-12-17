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

    func handleChangePassword(callback: @escaping (_ oldPassword: String, _ newPassword: String) -> Void)

    func handleMultifactorAuthenication(callback: @escaping (_ code: String) -> Void)

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
        self.api.commonCompletion = handleAPICompletion
    }

    public weak var delegate: AuthenticationClientDelegate?
    public weak var stateHandler: AuthenticationClientStateHandler? = nil

    public func logIn(username: String, password: String) {
        guard case .unauthenticated = state else { return }

        api.primaryAuthenication(username: username, password: password, audience: "test", relayState: "test")
    }

    public func cancel() {
        guard let _ = sessionToken else { return }

    }

    // MARK: - Internal

    public private(set) var api: OktaAPI

    /// Current state of the authentication transaction.
    public private(set) var state: State = .unauthenticated

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

    public enum State {
        case unauthenticated
        case passwordWarning
        case passwordExpired
        case recovery
        case recoveryChallenge
        case passwordReset
        case lockedOut
        case MFAEnroll
        case MFAEnrollActivate
        case MFARequired
        case MFAChallenge
        case success
        case unknown(String)
    }

    // MARK: - Private

    private func handleAPICompletion(req: OktaAPIRequest, result: OktaAPIRequest.Result) {
        switch result {
        case .error(let error):
            delegate?.handleError(error)
        case .success(_):
            delegate?.loggedIn()
        }
    }

    private func handleAPIError(req: OktaAPIRequest, error: OktaError) {

    }

    private func handleAPISuccess(req: OktaAPIRequest, response: OktaAPISuccessResponse) {

    }

    private func handleStateChange() {

    }
}
