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

    public func primaryAuthenication(username: String?,
                                     password: String?,
                                     audience: String? = nil,
                                     relayState: String? = nil,
                                     multiOptionalFactorEnroll: Bool = true,
                                     warnBeforePasswordExpired: Bool = true,
                                     token: String? = nil,
                                     deviceToken: String? = nil,
                                     completion: ((OktaAPIRequest.Result) -> Void)? = nil) {
        let req = buildBaseRequest(completion: completion)
        req.method = .post
        req.path = "/api/v1/authn"

        var bodyParams: [String: Any] = [:]
        bodyParams["username"] = username
        bodyParams["password"] = password
        bodyParams["audience"] = audience
        bodyParams["relayState"] = relayState
        bodyParams["options"] = ["multiOptionalFactorEnroll": multiOptionalFactorEnroll,
                                 "warnBeforePasswordExpired": warnBeforePasswordExpired]
        var context: [String: String] = [:]
        context["deviceToken"] = deviceToken
        bodyParams["context"] = context
        bodyParams["token"] = token
        req.bodyParams = bodyParams
        req.run()
    }

    public func changePassword(stateToken: String,
                               oldPassword: String,
                               newPassword: String,
                               completion: ((OktaAPIRequest.Result) -> Void)? = nil) {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/credentials/change_password"
        req.bodyParams = ["stateToken": stateToken, "oldPassword": oldPassword, "newPassword": newPassword]
        req.run()
    }

    public func getTransactionState(stateToken: String,
                                    completion: ((OktaAPIRequest.Result) -> Void)? =  nil) {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
    }

    public func cancelTransaction(stateToken: String,
                                  completion: ((OktaAPIRequest.Result) -> Void)? = nil) {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/cancel"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
    }

    // MARK: - Private

    private func buildBaseRequest(completion: ((OktaAPIRequest.Result) -> Void)?) -> OktaAPIRequest {
        let req = OktaAPIRequest(urlSession: urlSession,  completion: { [weak self] req, result in
            completion?(result)
            self?.commonCompletion?(req, result)
        })
        req.baseURL = oktaDomain
        return req
    }
}
