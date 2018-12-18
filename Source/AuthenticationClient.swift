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
        api.primaryAuthenication(username: username, password: password)
    }

    public func cancel() {
        guard let stateToken = stateToken else { return }
        api.cancelTransaction(stateToken: stateToken)
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

    private func handleAPICompletion(req: OktaAPIRequest, result: OktaAPIRequest.Result) {
        switch result {
        case .error(let error):
            delegate?.handleError(error)

        case .success(let response):
            print("Okta API Response: \(response)")

            state = AuthState(raw: response.status ?? "<EMPTY>")
            stateToken = response.stateToken
            handleStateChange()
        }
    }

    private func handleStateChange() {
        print("Handling state change: \(state.description)")

        switch state {
        case .success:
            delegate?.loggedIn()

        case .MFARequired:
            delegate?.handleMultifactorAuthenication(callback: { code in
                print("Code: \(code)")
            })

        default:
            delegate?.handleError(.authenicationStateNotSupported(state))
            break
        }
    }
}
