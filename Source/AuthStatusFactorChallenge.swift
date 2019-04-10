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

open class OktaAuthStatusFactorChallenge : OktaAuthStatus {

    override init(oktaDomain: URL, model: OktaAPISuccessResponse, responseHandler: AuthStatusCustomHandlerProtocol? = nil) {
        super.init(oktaDomain: oktaDomain, model: model, responseHandler: responseHandler)
        statusType = .MFAChallenge
    }
    
    override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) {
        super.init(currentState: currentState, model: model)
        statusType = .MFAChallenge
    }

    public var factor: EmbeddedResponse.Factor? {
        get {
            return model.embedded?.factor
        }
    }

    public var factorType: FactorType? {
        get {
            return model.embedded?.factor?.factorType
        }
    }

    public func canVerify() -> Bool {
        guard model.links?.next != nil else {
            return false
        }
        
        return true
    }

    public func canResend() -> Bool {
        guard model.links?.resend?.first != nil else {
            return false
        }
        
        return true
    }

    public func verifySmsOrCallChallenge(with code: String,
                                   onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                   onError: @escaping (_ error: OktaError) -> Void) {
        guard factor?.factorType != nil && factor!.factorType! == .sms ||
              factor?.factorType != nil && factor!.factorType! == .call else {
            onError(OktaError.factorNotAvailable(model))
            return
        }

        guard canVerify() else {
            onError(.wrongState("Can't find 'send' link in response"))
            return
        }

        self.verifyFactor(with: model.links!.next!,
                          answer: nil,
                          passCode: code,
                          completion: { result in
                self.handleServerResponse(result,
                                          onStatusChanged: onStatusChange,
                                          onError: onError)
            })
    }

    public func verifyPushChallenge(with pollRate: TimeInterval = 3,
                                    onPushStateUpdate: @escaping (_ state: OktaAPISuccessResponse.FactorResult) -> Void,
                                    onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                    onError: @escaping (_ error: OktaError) -> Void) {
        guard factor?.factorType != nil && factor!.factorType! == .push else {
            onError(OktaError.factorNotAvailable(model))
            return
        }

        self.pollPushFactor(with: pollRate,
                            link: model.links!.next!,
                            onPushStateUpdate: onPushStateUpdate,
                            onStatusChange: onStatusChange,
                            onError: onError)
    }

    public func verifySecurityQuestionAnswer(answer: String,
                                             onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                             onError: @escaping (_ error: OktaError) -> Void) {
        guard factor?.factorType != nil && factor!.factorType! == .question else {
            onError(OktaError.factorNotAvailable(model))
            return
        }
        
        self.verifyFactor(with: model.links!.next!,
                          answer: answer,
                          passCode: nil,
                          completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }
    
    public func verifyTotpCode(totpCode: String,
                               onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                               onError: @escaping (_ error: OktaError) -> Void) {
        guard factor?.factorType != nil && factor!.factorType! == .TOTP else {
            onError(OktaError.factorNotAvailable(model))
            return
        }

        self.verifyFactor(with: model.links!.next!,
                          answer: nil,
                          passCode: totpCode,
                          completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public func verifySecureIDToken(token: String,
                                    onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                    onError: @escaping (_ error: OktaError) -> Void) {
        guard factor?.factorType != nil && factor!.factorType! == .token else {
            onError(OktaError.factorNotAvailable(model))
            return
        }
        
        self.verifyFactor(with: model.links!.next!,
                          answer: nil,
                          passCode: token,
                          completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void) {
        guard canResend() else {
            onError(.wrongState("Can't find 'resend' link in response"))
            return
        }

        self.api.perform(link: model.links!.resend!.first!,
                         stateToken: model.stateToken!,
                         completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }
}
