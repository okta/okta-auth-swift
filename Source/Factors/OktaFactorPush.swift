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

open class OktaFactorPush : OktaFactor {

    public var activation: EmbeddedResponse.Factor.Embedded.Activation? {
        get {
            return factor.embedded?.activation
        }
    }

    public var activationLinks: LinksResponse? {
        get {
            return factor.embedded?.activation?.links
        }
    }

    public var qrCodeLink: LinksResponse.QRCode? {
        get {
            return factor.embedded?.activation?.links?.qrcode
        }
    }

    public var sendLinks: [LinksResponse.Link]? {
        get {
            return factor.embedded?.activation?.links?.send
        }
    }

    public func canSendPushCodeViaSms() -> Bool {
        guard let sendLinkArray = factor.links?.send else {
            return false
        }
        
        for link in sendLinkArray {
            if link.name == "sms" {
                return true
            }
        }
        
        return false
    }

    public func codeViaSmsLink() -> LinksResponse.Link? {
        guard let sendLinkArray = factor.links?.send else {
            return nil
        }
        
        for link in sendLinkArray {
            if link.name == "sms" {
                return link
            }
        }
        
        return nil
    }
    
    public func canSendPushCodeViaEmail() -> Bool {
        guard let sendLinkArray = factor.links?.send else {
            return false
        }
        
        for link in sendLinkArray {
            if link.name == "email" {
                return true
            }
        }
        
        return false
    }

    public func codeViaEmailLink() -> LinksResponse.Link? {
        guard let sendLinkArray = factor.links?.send else {
            return nil
        }
        
        for link in sendLinkArray {
            if link.name == "email" {
                return link
            }
        }
        
        return nil
    }

    public func sendActivationLinkViaSms(with phoneNumber:String,
                                         onSuccess: @escaping () -> Void,
                                         onError: @escaping (_ error: OktaError) -> Void) {
        guard canSendPushCodeViaSms() else {
            onError(OktaError.wrongStatus("Can't find 'send' link in response"))
            return
        }

        guard responseDelegate != nil else {
            onError(OktaError.invalidParameters("Empty responseDelegate"))
            return
        }

        restApi?.sendActivationLink(link: codeViaSmsLink()!,
                                    stateToken: stateToken,
                                    phoneNumber: phoneNumber,
                                    completion: { result in
                                        switch result {

                                        case .error(let error):
                                            onError(error)
                                            return
                                        case .success(_):
                                            onSuccess()
                                        }
        })
    }
    
    public func sendActivationLinkViaEmail(onSuccess: @escaping () -> Void,
                                           onError: @escaping (_ error: OktaError) -> Void) {
        guard canSendPushCodeViaEmail() else {
            onError(OktaError.wrongStatus("Can't find 'send' link in response"))
            return
        }

        guard responseDelegate != nil else {
            onError(OktaError.invalidParameters("Empty responseDelegate"))
            return
        }

        restApi?.sendActivationLink(link: codeViaEmailLink()!,
                                    stateToken: stateToken,
                                    phoneNumber: nil,
                                    completion: { result in
                                        
                                        switch result {
                                        case .error(let error):
                                            onError(error)
                                            return
                                        case .success(_):
                                            onSuccess()
                                        }
        })
    }

    override public func activate(with link: LinksResponse.Link,
                                  passCode: String?,
                                  onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                  onError: @escaping (_ error: OktaError) -> Void,
                                  onFactorStatusUpdate: ((_ state: OktaAPISuccessResponse.FactorResult) -> Void)? = nil) {
            self.activate(with: link,
                          onStatusChange: onStatusChange,
                          onError: onError,
                          onFactorStatusUpdate: onFactorStatusUpdate)
    }

    public func activate(with link: LinksResponse.Link,
                         onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void,
                         onFactorStatusUpdate: ((_ state: OktaAPISuccessResponse.FactorResult) -> Void)? = nil) {
        self.verifyFactor(with: link,
                          answer: nil,
                          passCode: nil,
                          onStatusChange: onStatusChange,
                          onError: onError,
                          onFactorStatusUpdate: onFactorStatusUpdate)
    }

    override public func verify(passCode: String?,
                                answerToSecurityQuestion: String?,
                                onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                onError: @escaping (_ error: OktaError) -> Void,
                                onFactorStatusUpdate: ((_ state: OktaAPISuccessResponse.FactorResult) -> Void)? = nil) {
        guard canVerify() else {
            onError(OktaError.wrongStatus("Can't find 'verify' link in response"))
            return
        }
        
        self.verify(onStatusChange: onStatusChange, onError: onError, onFactorStatusUpdate: onFactorStatusUpdate)
    }

    public func verify(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void,
                       onFactorStatusUpdate: ((_ state: OktaAPISuccessResponse.FactorResult) -> Void)? = nil) {
        guard canVerify() else {
            onError(OktaError.wrongStatus("Can't find 'verify' link in response"))
            return
        }
        self.verifyFactor(with: verifyLink!,
                          answer: nil,
                          passCode: nil,
                          onStatusChange: onStatusChange,
                          onError: onError,
                          onFactorStatusUpdate: onFactorStatusUpdate)
    }

    // MARK: - Internal
    override init(factor: EmbeddedResponse.Factor,
                  stateToken:String,
                  verifyLink: LinksResponse.Link?,
                  activationLink: LinksResponse.Link?) {
        super.init(factor: factor, stateToken: stateToken, verifyLink: verifyLink, activationLink: activationLink)
    }
}
