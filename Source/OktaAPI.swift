//
//  OktaAPI.swift
//  OktaAuth iOS
//
//  Created by Alex on 13 Dec 18.
//

import Foundation

/// Represents Okta REST API

public class OktaAPI {

    public init(oktaDomain: URL) {
        self.oktaDomain = oktaDomain
        urlSession = URLSession(configuration: .default)
    }

    public var commonCompletion: ((OktaAPIRequest, OktaAPIRequest.Result) -> Void)?

    public private(set) var oktaDomain: URL
    public private(set) var urlSession: URLSession

    // Public application
    // Trusted application
    // Activation token
    // Device fingerprinting
    // Password expiration warning

    public func primaryAuthenication(username: String, password: String, audience: String, relayState: String) {
        let req = buildBaseRequest()
        req.method = .post
        req.path = "/api/v1/authn"
        req.bodyParams = ["username": username,
                          "password": password,
                          "relayState": relayState,
                          "options": ["multiOptionalFactorEnroll": false,
                                      "warnBeforePasswordExpired": false]]
        req.run()
    }

    public func changePassword(stateToken: String, oldPassword: String, newPassword: String) {
        let req = buildBaseRequest()
        req.path = "/api/v1/authn/credentials/change_password"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
    }

    public func getTransactionState(stateToken: String) {
        let req = buildBaseRequest()
        req.path = "/api/v1/authn"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
    }

    public func cancelTransaction(stateToken: String) {
        let req = buildBaseRequest()
        req.path = "/api/v2/authn/cancel"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
    }

    // MARK: - Private

    private func buildBaseRequest() -> OktaAPIRequest {
        let req = OktaAPIRequest(urlSession: urlSession,  completion: { [weak self] req, result in
            DispatchQueue.main.async {
                self?.commonCompletion?(req, result)
            }
        })
        req.baseURL = oktaDomain
        return req
    }

}
