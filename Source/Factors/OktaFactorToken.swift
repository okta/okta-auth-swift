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

open class OktaFactorToken : OktaFactor {

    public var credentialId: String? {
        get {
            return factor.profile?.credentialId
        }
    }

    public var factorProvider: FactorProvider? {
        get {
            return factor.provider
        }
    }

    public func enroll(credentialId: String,
                       passCode: String,
                       onStatusChange: @escaping (OktaAuthStatus) -> Void,
                       onError: @escaping (OktaError) -> Void) {
        super.enroll(questionId: nil,
                     answer: nil,
                     credentialId: credentialId,
                     passCode: passCode,
                     phoneNumber:  nil,
                     onStatusChange: onStatusChange,
                     onError: onError)
    }

    public func select(passCode: String,
                       onStatusChange: @escaping (OktaAuthStatus) -> Void,
                       onError: @escaping (OktaError) -> Void) {
        self.verify(passCode: passCode,
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
