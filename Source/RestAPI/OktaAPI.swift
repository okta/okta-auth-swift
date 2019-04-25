/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

/// Represents Okta REST API

open class OktaAPI {

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

    @discardableResult open func primaryAuthentication(username: String?,
                                                       password: String?,
                                                       audience: String? = nil,
                                                       relayState: String? = nil,
                                                       multiOptionalFactorEnroll: Bool = true,
                                                       warnBeforePasswordExpired: Bool = true,
                                                       token: String? = nil,
                                                       deviceToken: String? = nil,
                                                       deviceFingerprint: String? = nil,
                                                       completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
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

    @discardableResult open func changePassword(stateToken: String,
                                                oldPassword: String,
                                                newPassword: String,
                                                completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/credentials/change_password"
        req.bodyParams = ["stateToken": stateToken, "oldPassword": oldPassword, "newPassword": newPassword]
        req.run()
        return req
    }

    @discardableResult open func changePassword(link: LinksResponse.Link,
                                                stateToken: String,
                                                oldPassword: String,
                                                newPassword: String,
                                                completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
        req.bodyParams = ["stateToken": stateToken, "oldPassword": oldPassword, "newPassword": newPassword]
        req.run()
        return req
    }

    @discardableResult open func getTransactionState(stateToken: String,
                                                     completion: ((OktaAPIRequest.Result) -> Void)? =  nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
        return req
    }
    
    @discardableResult open func unlockAccount(username: String,
                                               factor: FactorType,
                                               completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/recovery/unlock"
        req.bodyParams = ["username": username, "factorType": factor.rawValue]
        req.run()
        return req
    }

    @discardableResult open func recoverPassword(username: String,
                                                 factor: FactorType,
                                                 completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/recovery/password"
        req.bodyParams = ["username": username, "factorType": factor.rawValue]
        req.run()
        return req
    }

    @discardableResult open func recoverWith(answer: String?,
                                             stateToken: String,
                                             recoveryToken: String?,
                                             link: LinksResponse.Link,
                                             completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
        req.bodyParams = [:]
        req.bodyParams = ["stateToken": stateToken]
        req.bodyParams?["answer"] = answer
        req.bodyParams?["recoveryToken"] = recoveryToken
        req.run()
        return req
    }

    @discardableResult open func resetPassword(newPassword: String,
                                               stateToken: String,
                                               link: LinksResponse.Link,
                                               completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
        req.bodyParams = ["newPassword": newPassword]
        req.bodyParams?["stateToken"] = stateToken
        req.run()
        return req
    }

    @discardableResult open func cancelTransaction(stateToken: String,
                                                   completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.path = "/api/v1/authn/cancel"
        req.bodyParams = ["stateToken": stateToken]
        req.run()
        return req
    }

    @discardableResult open func cancelTransaction(with link: LinksResponse.Link,
                                                   stateToken: String,
                                                   completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
        req.bodyParams = ["stateToken": stateToken]
        req.run()
        return req
    }
    
    @discardableResult open func perform(link: LinksResponse.Link,
                                         stateToken: String,
                                         completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
        req.method = .post
        req.bodyParams = ["stateToken": stateToken]
        req.run()
        return req
    }
    
    @discardableResult open func verifyFactor(factorId: String,
                                              stateToken: String,
                                              answer: String? = nil,
                                              passCode: String? = nil,
                                              rememberDevice: Bool? = nil,
                                              autoPush: Bool? = nil,
                                              completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
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
        return req
    }

    @discardableResult open func verifyFactor(with link: LinksResponse.Link,
                                              stateToken: String,
                                              answer: String? = nil,
                                              passCode: String? = nil,
                                              recoveryToken: String? = nil,
                                              rememberDevice: Bool? = nil,
                                              autoPush: Bool? = nil,
                                              completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
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
        req.bodyParams?["recoveryToken"] = recoveryToken
        req.run()
        return req
    }

    @discardableResult open func enrollFactor(_ factor: EmbeddedResponse.Factor,
                                              with link: LinksResponse.Link,
                                              stateToken: String,
                                              phoneNumber: String?,
                                              questionId: String?,
                                              answer: String?,
                                              credentialId: String?,
                                              passCode: String?,
                                              completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
        req.method = .post
        req.urlParams = [:]
        req.bodyParams = ["stateToken": stateToken]
        req.bodyParams?["factorType"] = factor.factorType.rawValue
        req.bodyParams?["provider"] = factor.provider?.rawValue
        var profile: [String: String] = [:]
        if let answer = answer, let questionId = questionId {
            profile["question"] = questionId
            profile["answer"] = answer
        }
        if let phoneNumber = phoneNumber {
            profile["phoneNumber"] = phoneNumber
        }
        if let credentialId = credentialId, let passCode = passCode {
            profile["credentialId"] = credentialId
            req.bodyParams?["passCode"] = passCode
        }
        req.bodyParams?["profile"] = profile
        req.run()
        return req
    }

    @discardableResult open func sendActivationLink(link: LinksResponse.Link,
                                                    stateToken: String,
                                                    phoneNumber: String? = nil,
                                                    completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
        req.method = .post
        req.urlParams = [:]
        req.bodyParams = ["stateToken": stateToken]
        var profile: [String: String] = [:]
        if let phoneNumber = phoneNumber {
            profile["phoneNumber"] = phoneNumber
        }
        req.bodyParams?["profile"] = profile
        req.run()
        return req
    }

    @discardableResult open func downloadSecurityQuestions(with link: LinksResponse.Link,
                                                           onCompletion: (([SecurityQuestion]) -> Void)? = nil,
                                                           onError: ((OktaError) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: nil)
        req.baseURL = link.href
        req.method = .get
        req.customSuccessHandler = { request, data, decoder, error in
            guard error == nil else {
                onError?(error!)
                return
            }
            guard let dataUnwrapped = data else {
                onError?(.internalError("Required parameters are nil"))
                return
            }
            do {
                let questions = try decoder.decode([SecurityQuestion].self, from: dataUnwrapped)
                onCompletion?(questions)
            } catch let e {
                onError?(.responseSerializationError(e, dataUnwrapped))
            }
        }
        req.run()
        return req
    }

    @discardableResult open func sendApiRequest(with link: LinksResponse.Link,
                                                bodyParams: Dictionary<String, Any>?,
                                                method: OktaAPIRequest.Method,
                                                completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: completion)
        req.baseURL = link.href
        req.method = .post
        req.urlParams = [:]
        req.bodyParams = bodyParams
        req.run()
        return req
    }

    @discardableResult open func sendHttpRequest(with url: URL,
                                                 method: OktaAPIRequest.Method,
                                                 onCompletion: @escaping ((Data) -> Void),
                                                 onError: @escaping ((OktaError) -> Void)) -> OktaAPIRequest {
        let req = buildBaseRequest(completion: nil)
        req.baseURL = url
        req.method = method
        req.customSuccessHandler = { request, data, decoder, error in
            guard error == nil else {
                onError(error!)
                return
            }
            guard let dataUnwrapped = data else {
                onError(.internalError("Required parameters are nil"))
                return
            }
            onCompletion(dataUnwrapped)
        }
        req.run()
        return req
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
