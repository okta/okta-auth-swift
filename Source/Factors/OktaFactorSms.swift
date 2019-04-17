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

open class OktaFactorSms : OktaFactor {

    public var phoneNumber: String? {
        get {
            return factor.profile?.phoneNumber
        }
    }

    override public func enroll(questionId: String?,
                                answer: String?,
                                credentialId: String?,
                                passCode: String?,
                                phoneNumber: String?,
                                onStatusChange: @escaping (OktaAuthStatus) -> Void,
                                onError: @escaping (OktaError) -> Void) {
        guard canEnroll() else {
            onError(OktaError.wrongStatus("Can't find 'enroll' link in response"))
            return
        }

        self.enroll(phoneNumber: phoneNumber,
                    onStatusChange: onStatusChange,
                    onError: onError,
                    onFactorStatusUpdate: nil)
    }

    public func enroll(phoneNumber: String?,
                       onStatusChange: @escaping (OktaAuthStatus) -> Void,
                       onError: @escaping (OktaError) -> Void,
                       onFactorStatusUpdate: ((_ state: OktaAPISuccessResponse.FactorResult) -> Void)? = nil) {
        guard canEnroll() else {
            onError(OktaError.wrongStatus("Can't find 'enroll' link in response"))
            return
        }

        restApi?.enrollFactor(factor,
                              with: factor.links!.enroll!,
                              stateToken: stateToken,
                              phoneNumber: phoneNumber,
                              questionId: nil,
                              answer: nil,
                              credentialId: nil,
                              passCode: nil,
                              completion: { result in
                                self.handleServerResponse(response: result,
                                                          onStatusChange: onStatusChange,
                                                          onError: onError,
                                                          onFactorStatusUpdate: onFactorStatusUpdate)
        })
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
        
        self.verify(passCode: passCode,
                    onStatusChange: onStatusChange,
                    onError: onError,
                    onFactorStatusUpdate: onFactorStatusUpdate)
    }
    
    public func verify(passCode: String?,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void,
                       onFactorStatusUpdate: ((_ state: OktaAPISuccessResponse.FactorResult) -> Void)? = nil) {
        guard canVerify() else {
            onError(OktaError.wrongStatus("Can't find 'verify' link in response"))
            return
        }
        self.verifyFactor(with: verifyLink!,
                          answer: nil,
                          passCode: passCode,
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
