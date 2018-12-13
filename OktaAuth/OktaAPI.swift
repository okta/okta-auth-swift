//
//  OktaAPI.swift
//  OktaAuth iOS
//
//  Created by Alex on 13 Dec 18.
//

import Foundation

/// Represents Okta REST API

class OktaAPI {

    init(issuer: URL) {
        self.issuer = issuer
        urlSession = URLSession(configuration: .default)
    }

    var successResponseHandler: ((OktaAPISuccess) -> Void)?
    var errorResponseHandler: ((OktaAPIError) -> Void)?

    private(set) var issuer: URL
    private(set) var urlSession: URLSession

    // Public application
    // Trusted application
    // Activation token
    // Device fingerprinting
    // Password expiration warning

    func primaryAuthenication(username: String, password: String, audience: String, relayState: String) {
        let req = OktaAPIRequest()
        req.path = "/api/v1/authn"
        req.run()
    }

    func changePassword(stateToken: String, oldPassword: String, newPassword: String) {
        let req = OktaAPIRequest()
        req.path = "/api/v1/authn/credentials/change_password"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
    }

    func getTransactionState(stateToken: String) {
        let req = OktaAPIRequest()
        req.path = "/api/v1/authn"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
    }

    func cancelTransaction(stateToken: String) {
        let req = OktaAPIRequest()
        req.path = "/api/v2/authn/cancel"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
    }

    // MARK: - Private

}
