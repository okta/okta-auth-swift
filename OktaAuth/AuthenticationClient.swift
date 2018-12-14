//
//  OktaAuth.swift
//  OktaAuth iOS
//
//  Created by Alex Lebedev on 12 Dec 18.
//

import Foundation

protocol AuthenticationClientDelegate: class {

    func loggedIn()

    func handleError(_ error: OktaError)

    func handleChangePassword(callback: @escaping (_ oldPassword: String, _ newPassword: String) -> Void)

    func handleMultifactorAuthenication(callback: @escaping (_ code: String) -> Void)

}

/// Our SDK provides default state machine implementation,
/// but developer able to implement custom handler by implementing
/// `OktaStateMachineHandler` protocol

protocol AuthenticationClientStateHandler: class {

    func handleState() // to be extended

}

/// AuthenticationClient class is main entry point for developer

class AuthenticationClient {

    init(oktaDomain: URL, delegate: AuthenticationClientDelegate) {
        self.delegate = delegate
        self.api = OktaAPI(oktaDomain: oktaDomain)
    }

    weak var delegate: AuthenticationClientDelegate?
    weak var stateHandler: AuthenticationClientStateHandler? = nil

    func logIn(username: String, password: String) {
        guard case .unauthenticated = state else { return }

    }

    func cancel() {
        guard let _ = sessionToken else { return }

    }

    // MARK: - Internal

    private(set) var api: OktaAPI

    /// Current state of the authentication transaction.
    private(set) var state: State = .unauthenticated

    /// Ephemeral token that encodes the current state of an authentication or recovery transaction.
    private(set) var stateToken: String?

    /// Link relations for the current status.
    private(set) var links: [String: String] = [:]

    // Embedded resources for current status
    private(set) var embedded: [String: String] = [:]

    /// One-time token issued as recoveryToken response parameter when a recovery transaction transitions to the RECOVERY status.
    private(set) var recoveryToken: String?

    /// One-time token isuued as `sessionToken` response parameter when an authenication transaction completes with the `SUCCESS` status.
    private(set) var sessionToken: String?

    enum State {
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

    private func handleAPIError(_ error: OktaAPIError) {
        
    }

    private func handleAPISuccess(_ response: OktaAPISuccess) {

    }

    private func handleStateChange() {

    }
}
