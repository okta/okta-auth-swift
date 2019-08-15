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

open class OktaFactorTotp : OktaFactor {

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

    public func enroll(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        self.enroll(questionId: nil,
                    answer: nil,
                    credentialId: nil,
                    passCode: nil,
                    phoneNumber: nil,
                    onStatusChange: onStatusChange,
                    onError: onError)
    }

    public func activate(passCode: String,
                         onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void) {
        super.activate(passCode: passCode, onStatusChange: onStatusChange, onError: onError)
    }

    public func select(passCode: String,
                       onStatusChange: @escaping (OktaAuthStatus) -> Void,
                       onError: @escaping (OktaError) -> Void) {
        self.verifyFactor(with: links!.verify!,
                          answer: nil,
                          passCode: passCode,
                          onStatusChange: onStatusChange,
                          onError: onError)
    }
    
    public func verify(passCode: String,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        super.verify(passCode: passCode,
                     answerToSecurityQuestion: nil,
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
