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
        guard let sendLinkArray = activationLinks?.send else {
            return false
        }
        
        guard let _ = sendLinkArray.first(where: { $0.name == "sms" }) else {
            return false
        }
        
        return true
    }

    public func codeViaSmsLink() -> LinksResponse.Link? {
        guard let sendLinkArray = activationLinks?.send else {
            return nil
        }

        guard let link = sendLinkArray.first(where: { $0.name == "sms" }) else {
            return nil
        }
        
        return link
    }
    
    public func canSendPushCodeViaEmail() -> Bool {
        guard let sendLinkArray = activationLinks?.send else {
            return false
        }
        
        guard let _ = sendLinkArray.first(where: { $0.name == "email" }) else {
            return false
        }
        
        return true
    }

    public func codeViaEmailLink() -> LinksResponse.Link? {
        guard let sendLinkArray = activationLinks?.send else {
            return nil
        }

        guard let link = sendLinkArray.first(where: { $0.name == "email" }) else {
            return nil
        }
        
        return link
    }

    public func sendActivationLinkViaSms(with phoneNumber:String,
                                         onSuccess: @escaping () -> Void,
                                         onError: @escaping (_ error: OktaError) -> Void) {
        guard canSendPushCodeViaSms() else {
            onError(OktaError.wrongStatus("Can't find 'send' link in response"))
            return
        }

        restApi?.sendActivationLink(link: codeViaSmsLink()!,
                                    stateToken: stateToken,
                                    phoneNumber: phoneNumber,
                                    completion: { result in
                                        switch result {

                                        case .error(let error):
                                            onError(error)
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

        restApi?.sendActivationLink(link: codeViaEmailLink()!,
                                    stateToken: stateToken,
                                    phoneNumber: nil,
                                    completion: { result in
                                        
                                        switch result {
                                        case .error(let error):
                                            onError(error)
                                        case .success(_):
                                            onSuccess()
                                        }
        })
    }

    public func enroll(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        super.enroll(questionId: nil,
                     answer: nil,
                     credentialId: nil,
                     passCode: nil,
                     phoneNumber: nil,
                     onStatusChange: onStatusChange,
                     onError: onError)
    }

    public func activate(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void) {
        super.activate(passCode: nil, onStatusChange: onStatusChange, onError: onError)
    }

    public func verify(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        super.verify(passCode: nil,
                     answerToSecurityQuestion: nil,
                     onStatusChange: onStatusChange,
                     onError: onError)
    }

    public func checkFactorResult(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                  onError: @escaping (_ error: OktaError) -> Void) {
        guard canActivate() || canVerify() else {
            onError(OktaError.wrongStatus("Can't find 'poll' link in response"))
            return
        }
        
        let pollLink: LinksResponse.Link?
        if activationLink != nil {
            pollLink = activationLink
        } else {
            pollLink = verifyLink
        }
        
        self.verifyFactor(with: pollLink!,
                          answer: nil,
                          passCode: nil,
                          onStatusChange: onStatusChange,
                          onError: onError)
    }

    // MARK: - Internal
    override init(factor: EmbeddedResponse.Factor,
                  stateToken:String,
                  verifyLink: LinksResponse.Link?,
                  activationLink: LinksResponse.Link?) {
        super.init(factor: factor, stateToken: stateToken, verifyLink: verifyLink, activationLink: activationLink)
    }
}
