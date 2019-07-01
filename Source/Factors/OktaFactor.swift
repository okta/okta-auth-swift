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

public protocol OktaFactorResultProtocol: class {
    func handleFactorServerResponse(response: OktaAPIRequest.Result,
                                    onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                    onError: @escaping (_ error: OktaError) -> Void)
}

open class OktaFactor {

    public class func createFactorWith(_ factor: EmbeddedResponse.Factor,
                                       stateToken: String,
                                       verifyLink: LinksResponse.Link?,
                                       activationLink: LinksResponse.Link?) -> OktaFactor {
        switch factor.factorType {
        case .call:
            return OktaFactorCall(factor: factor,
                                  stateToken: stateToken,
                                  verifyLink: verifyLink,
                                  activationLink: activationLink)
        case .push:
            return OktaFactorPush(factor: factor,
                                  stateToken: stateToken,
                                  verifyLink: verifyLink,
                                  activationLink: activationLink)
        case .question:
            return OktaFactorQuestion(factor: factor,
                                      stateToken: stateToken,
                                      verifyLink: verifyLink,
                                      activationLink: activationLink)
        case .sms:
            return OktaFactorSms(factor: factor,
                                 stateToken: stateToken,
                                 verifyLink: verifyLink,
                                 activationLink: activationLink)
        case .token:
            return OktaFactorToken(factor: factor,
                                   stateToken: stateToken,
                                   verifyLink: verifyLink,
                                   activationLink: activationLink)
        case .TOTP:
            return OktaFactorTotp(factor: factor,
                                  stateToken: stateToken,
                                  verifyLink: verifyLink,
                                  activationLink: activationLink)
            
        default:
            return OktaFactorOther(factor: factor,
                                   stateToken: stateToken,
                                   verifyLink: verifyLink,
                                   activationLink: activationLink)
        }
    }

    public init(factor: EmbeddedResponse.Factor,
                stateToken: String,
                verifyLink: LinksResponse.Link?,
                activationLink: LinksResponse.Link?) {
        self.factor = factor
        self.stateToken = stateToken
        self.verifyLink = verifyLink
        self.activationLink = activationLink
    }

    public weak var responseDelegate: OktaFactorResultProtocol?
    public var restApi: OktaAPI?
    public var factor: EmbeddedResponse.Factor

    // REQUIRED, OPTIONAL
    public var enrollment: String? {
        get {
            return factor.enrollment
        }
    }

    // NOT_SET, ACTIVE
    public var status: String? {
        get {
            return factor.status
        }
    }

    public var provider: FactorProvider? {
        get {
            return factor.provider
        }
    }

    public var profile: EmbeddedResponse.Factor.Profile? {
        get {
            return factor.profile
        }
    }

    public var links: LinksResponse? {
        get {
            return factor.links
        }
    }

    public var type: FactorType {
        get {
            return factor.factorType
        }
    }

    public func canVerify() -> Bool {
        guard verifyLink?.href != nil else {
            return false
        }
        
        return true
    }

    public func canSelect() -> Bool {
        guard links?.verify != nil else {
            return false
        }
        
        return true
    }

    public func canActivate() -> Bool {
        guard activationLink?.href != nil else {
            return false
        }
        
        return true
    }

    public func canEnroll() -> Bool {
        guard factor.links?.enroll?.href != nil else {
            return false
        }
        
        return true
    }

    public func verify(passCode: String?,
                       answerToSecurityQuestion: String?,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        guard canVerify() else {
            onError(OktaError.wrongStatus("Can't find 'verify' link in response"))
            return
        }

        self.verifyFactor(with: verifyLink!,
                          answer: answerToSecurityQuestion,
                          passCode: passCode,
                          onStatusChange: onStatusChange,
                          onError: onError)
    }

    public func activate(passCode: String?,
                         onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void) {
        guard canActivate() else {
            onError(OktaError.wrongStatus("Can't find 'activate' link in response"))
            return
        }

        self.verifyFactor(with: activationLink!,
                          answer: nil,
                          passCode: passCode,
                          onStatusChange: onStatusChange,
                          onError: onError)
    }

    public func enroll(questionId: String?,
                       answer: String?,
                       credentialId: String?,
                       passCode: String?,
                       phoneNumber: String?,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        guard canEnroll() else {
            onError(OktaError.wrongStatus("Can't find 'enroll' link in response"))
            return
        }

        restApi?.enrollFactor(factor,
                              with: factor.links!.enroll!,
                              stateToken: stateToken,
                              phoneNumber: phoneNumber,
                              questionId: questionId,
                              answer: answer,
                              credentialId: credentialId,
                              passCode: passCode,
                              completion: { result in
                                self.handleServerResponse(response: result,
                                                          onStatusChange:  onStatusChange,
                                                          onError: onError)
        })
    }

    public func select(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        guard canSelect() else {
            onError(OktaError.wrongStatus("Can't find 'verify' link in response"))
            return
        }

        self.verifyFactor(with: links!.verify!,
                          answer: nil,
                          passCode: nil,
                          onStatusChange: onStatusChange,
                          onError: onError)
    }

    var stateToken: String
    var verifyLink: LinksResponse.Link?
    var activationLink: LinksResponse.Link?
    var cancelled = false

    func cancel() {
        cancelled = true
        responseDelegate = nil
    }

    func verifyFactor(with link: LinksResponse.Link,
                      answer: String?,
                      passCode: String?,
                      onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                      onError: @escaping (_ error: OktaError) -> Void) {
            restApi?.verifyFactor(with: link,
                                  stateToken: stateToken,
                                  answer: answer,
                                  passCode: passCode,
                                  rememberDevice: nil,
                                  autoPush: nil,
                                  completion:  { result in
                                    self.handleServerResponse(response: result,
                                                              onStatusChange: onStatusChange,
                                                              onError: onError)
        })
    }

    func handleServerResponse(response: OktaAPIRequest.Result,
                              onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                              onError: @escaping (_ error: OktaError) -> Void) {
        if cancelled {
            return
        }

        self.responseDelegate?.handleFactorServerResponse(response: response,
                                                          onStatusChange: onStatusChange,
                                                          onError: onError)
    }
}
