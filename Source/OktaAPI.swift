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

    public var commonCompletion: ((OktaAuthRequest, OktaAuthRequest.Result) -> Void)?

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
                                      completion: ((OktaAuthRequest.Result) -> Void)? = nil) -> OktaAuthRequest {
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
        return req
    }

    public func changePassword(stateToken: String,
                               oldPassword: String,
                               newPassword: String,
                               completion: ((OktaAuthRequest.Result) -> Void)? = nil) -> OktaAuthRequest {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/credentials/change_password"
        req.bodyParams = ["stateToken": stateToken, "oldPassword": oldPassword, "newPassword": newPassword]
        req.run()
        return req
    }
    
    public func unlockAccount(username: String,
                              factor: FactorType,
                              completion: ((OktaAuthRequest.Result) -> Void)? = nil) {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/recovery/unlock"
        req.bodyParams = ["username": username, "factorType": factor.rawValue]
        req.run()
    }

    public func getTransactionState(stateToken: String,
                                    completion: ((OktaAuthRequest.Result) -> Void)? =  nil) -> OktaAuthRequest {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
        return req
    }

    public func cancelTransaction(stateToken: String,
                                  completion: ((OktaAuthRequest.Result) -> Void)? = nil) -> OktaAuthRequest {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/cancel"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
        return req
    }
    
    public func enrollMFAFactor(stateToken: String,
                                factor: FactorType,
                                provider: FactorProvider,
                                profile: FactorProfile,
                                completion: ((OktaAuthRequest.Result) -> Void)? = nil) -> OktaAuthRequest {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/factors"
        req.bodyParams = [
            "stateToken" : stateToken,
            "factorType" : factor.rawValue,
            "provider" : provider.rawValue,
            "profile": profile.toDictionary()
        ]
        req.run()
        return req
    }
    
    public func activateMFAFactor(url: URL,
                                  stateToken: String,
                                  factorId: String,
                                  code: String,
                                  completion: ((OktaAuthRequest.Result) -> Void)? = nil) -> OktaAuthRequest {
        let req = buildBaseRequest(url: url, completion: completion)
        req.bodyParams = [
            "stateToken" : stateToken,
            "factorId" : factorId,
            "passCode" : code
        ]
        req.run()
        return req
    }
    
    public func perform(link: LinksResponse.Link,
                        stateToken: String,
                        completion: ((OktaAuthRequest.Result) -> Void)? = nil) -> OktaAuthRequest {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
        req.method = .post
        req.bodyParams = ["stateToken": stateToken]
        req.run()
        return req
    }
    
    public func getSecurityQuestions(for userId: String,
                                     completion: @escaping ((SecurityQuestionsRequest.Result) -> Void))
                                     -> SecurityQuestionsRequest {
        let req = SecurityQuestionsRequest(baseURL: oktaDomain,
                                           urlSession: urlSession,
                                           completion: { req, result in
            completion(result)
        })
        
        req.path = "/api/v1/users/\(userId)/factors/questions"
        req.method = .get
        req.run()
        return req
    }

    // MARK: - Private

    private func buildBaseRequest(url: URL? = nil,
                                  completion: ((OktaAuthRequest.Result) -> Void)?) -> OktaAuthRequest {
        let req = OktaAuthRequest(baseURL: url ?? oktaDomain,
                                  urlSession: urlSession,
                                  completion: { [weak self] req, result in
            completion?(result)
            self?.commonCompletion?(req, result)
        })
        return req
    }
}
