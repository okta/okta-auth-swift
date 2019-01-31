//
//  OktaAPI.swift
//  OktaAuth iOS
//
//  Created by Alex on 13 Dec 18.
//

import Foundation

/// Represents Okta REST API

public class OktaAPI {

    public init(oktaDomain: URL, urlSession: URLSession? = nil) {
        self.oktaDomain = oktaDomain
        if let urlSession = urlSession {
            self.urlSession = urlSession
        } else {
            self.urlSession = URLSession(configuration: .default)
        }
    }

    public var commonCompletion: ((OktaAPIRequest, OktaAPIRequest.Result) -> Void)?

    public private(set) var oktaDomain: URL
    public private(set) var urlSession: URLSession

    public func primaryAuthentication(username: String?,
                                      password: String?,
                                      audience: String? = nil,
                                      relayState: String? = nil,
                                      multiOptionalFactorEnroll: Bool = true,
                                      warnBeforePasswordExpired: Bool = true,
                                      token: String? = nil,
                                      deviceToken: String? = nil,
                                      deviceFingerprint: String? = nil,
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
        
        if let deviceFingerprint = deviceFingerprint {
            req.additionalHeaders = ["X-Device-Fingerprint": deviceFingerprint]
        }
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
    
    public func unlockAccount(username: String,
                              factor: FactorType,
                              completion: ((OktaAPIRequest.Result) -> Void)? = nil) {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/recovery/unlock"
        req.bodyParams = ["username": username, "factorType": factor.rawValue]
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
    
    public func perform(link: LinksResponse.Link,
                        stateToken: String,
                        completion: ((OktaAPIRequest.Result) -> Void)? = nil) {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
        req.method = .post
        req.bodyParams = ["stateToken": stateToken]
        req.run()
    }
    
    public func verify(factorId: String,
                       stateToken: String,
                       answer: String? = nil,
                       passCode: String? = nil,
                       rememberDevice: Bool? = nil,
                       autoPush: Bool? = nil,
                       completion: ((OktaAPIRequest.Result) -> Void)? = nil) {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/factors/\(factorId)/verify"
        req.method = .post
        req.urlParams = [:]
        if let rememberDevice = rememberDevice {
            req.urlParams?["rememberDevice"] = rememberDevice ? "true" : "false"
        }
        if let autoPush = autoPush {
            req.urlParams?["autoPush"] = autoPush ? "true" : "false"
        }
        req.bodyParams = ["stateToken": stateToken]
        req.bodyParams?["answer"] = answer
        req.bodyParams?["passCode"] = passCode
        req.run()
    }                       

    // MARK: - Private

    private func buildBaseRequest(url: URL? = nil,
                                  completion: ((OktaAPIRequest.Result) -> Void)?) -> OktaAPIRequest {
        let req = OktaAPIRequest(baseURL: url ?? oktaDomain,
                                 urlSession: urlSession,
                                 completion: { [weak self] req, result in
            completion?(result)
            self?.commonCompletion?(req, result)
        })
        return req
    }
}
