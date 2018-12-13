//
//  OktaAuth.swift
//  OktaAuth iOS
//
//  Created by Alex Lebedev on 12 Dec 18.
//

import Foundation

protocol OktaAuthDelegate: class {

    func loggedIn()

    func handleError(_ error: OktaError)

    func handleChangePassword(callback: (_ oldPassword: String, _ newPassword: String) -> Void)

    func handleMultifactorAuthenication(callback: (_ code: String) -> Void)

}

/// Our SDK provides default state machine implementation,
/// but developer able to implement custom handler by implementing
/// `OktaStateMachineHandler` protocol

protocol OktaStateMachineHandler: class {

    func handleState()

}

/// OktaAuth class is main entry point for developer

class OktaAuth {

    init(issuer: URL, delegate: OktaAuthDelegate) {
        self.delegate = delegate
        self.api = OktaAPI(issuer: issuer)
    }

    weak var delegate: OktaAuthDelegate?
    weak var stateMachineHandler: OktaStateMachineHandler? = nil

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

    enum State: String {
        case unauthenticated = "UNAUTHENICATED"
        case passwordWarning = "PASSWORD_WARN"
        case passwordExpired = "PASSWORD_EXPIRED"
        case recovery = "RECOVERY"
        case recoveryChallenge = "RECOVERY_CHALLENGE"
        case passwordReset = "PASSWORD_RESET"
        case lockedOut = "LOCAKED_OUT"
        case MFAEnroll = "MFA_ENROLL"
        case MFAEnrollActivate = "MFA_ENROLL_ACTIVATE"
        case MFARequired = "MFA_REQUIRED"
        case MFAChallenge = "MFA_CHALLENGE"
        case success = "SUCCESS"
    }

    // MARK: - Private

    private func handleAPIError(_ error: OktaAPIError) {
        
    }

    private func handleAPISuccess(_ response: OktaAPISuccess) {

    }

    private func handleStateChange() {

    }

}
