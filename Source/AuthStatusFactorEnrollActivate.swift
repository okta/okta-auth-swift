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

open class OktaAuthStatusFactorEnrollActivate : OktaAuthStatus {
    
    override init(oktaDomain: URL, model: OktaAPISuccessResponse, responseHandler: AuthStatusCustomHandlerProtocol? = nil) {
        super.init(oktaDomain: oktaDomain, model: model, responseHandler: responseHandler)
        statusType = .MFAEnrollActivate
    }
    
    override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) {
        super.init(currentState: currentState, model: model)
        statusType = .MFAEnrollActivate
    }

    public var factor: EmbeddedResponse.Factor? {
        get {
            return model.embedded?.factor
        }
    }

    public var pushFactorQRCode: LinksResponse.QRCode? {
        get {
            return model.embedded?.factor?.links?.qrcode
        }
    }

    public func canActivate() -> Bool {
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

    public func canSendPushCodeViaSms() -> Bool {
        guard let sendLinkArray = factor?.links?.send else {
            return false
        }

        for link in sendLinkArray {
            if link.name == "sms" {
                return true
            }
        }
        
        return false
    }

    public func canSendPushCodeViaEmail() -> Bool {
        guard let sendLinkArray = factor?.links?.send else {
            return false
        }
        
        for link in sendLinkArray {
            if link.name == "email" {
                return true
            }
        }
        
        return false
    }

    // passCode is used for SMS, Call and TOTP factors
    public func activate(with passCode: String,
                         onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void) {
        guard canActivate() else {
            onError(.wrongState("Can't find 'next' link in response"))
            return
        }
        
        self.verifyFactor(with: model.links!.next!,
                          answer: nil,
                          passCode: passCode,
                          completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public func activatePush(with pollRate: TimeInterval = 3,
                             onPushStateUpdate: @escaping (_ state: OktaAPISuccessResponse.FactorResult) -> Void,
                             onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void) {
        guard canActivate() else {
            onError(.wrongState("Can't find 'next' link in response"))
            return
        }

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

    public func sendPushCodeViaSms(with phoneNumber:String,
                                   onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                   onError: @escaping (_ error: OktaError) -> Void) {
        guard canSendPushCodeViaSms() else {
            onError(.wrongState("Can't find 'send' link in response"))
            return
        }

        let sendLinkArray = factor!.links!.send!
        
        for link in sendLinkArray {
            if link.name == "sms" {
                self.api.sendActivationLink(link: model.links!.next!,
                                            stateToken: model.stateToken!,
                                            phoneNumber: phoneNumber,
                                            completion: { result in
                                                self.handleServerResponse(result,
                                                                          onStatusChanged: onStatusChange,
                                                                          onError: onError)
                })
                break
            }
        }
    }

    public func sendPushCodeViaEmail(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                     onError: @escaping (_ error: OktaError) -> Void) {
        guard canSendPushCodeViaEmail() else {
            onError(.wrongState("Can't find 'send' link in response"))
            return
        }
        
        let sendLinkArray = factor!.links!.send!
        
        for link in sendLinkArray {
            if link.name == "email" {
                self.api.sendActivationLink(link: model.links!.next!,
                                            stateToken: model.stateToken!,
                                            phoneNumber: nil,
                                            completion: { result in
                                                self.handleServerResponse(result,
                                                                          onStatusChanged: onStatusChange,
                                                                          onError: onError)
                })
                break
            }
        }
    }

    public func resend(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        guard canReturn() else {
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
