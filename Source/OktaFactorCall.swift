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

open class OktaFactorCall : OktaFactor {

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
                                onFactorStatusUpdate: @escaping (OktaAPISuccessResponse.FactorResult) -> Void,
                                onStatusChange: @escaping (OktaAuthStatus) -> Void,
                                onError: @escaping (OktaError) -> Void) {
        guard canEnroll() else {
            onError(OktaError.wrongStatus("Can't find 'enroll' link in response"))
            return
        }
        
        self.enroll(phoneNumber: phoneNumber,
                    onFactorStatusUpdate: onFactorStatusUpdate,
                    onStatusChange: onStatusChange,
                    onError: onError)
    }
    
    public func enroll(phoneNumber: String?,
                       onFactorStatusUpdate: @escaping (OktaAPISuccessResponse.FactorResult) -> Void,
                       onStatusChange: @escaping (OktaAuthStatus) -> Void,
                       onError: @escaping (OktaError) -> Void) {
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
                                                          onFactorStatusUpdate: onFactorStatusUpdate,
                                                          onStatusChange: onStatusChange,
                                                          onError: onError)
        })
    }

    // MARK: - Internal
    override init(factor: EmbeddedResponse.Factor,
                  stateToken:String,
                  verifyLink: LinksResponse.Link?,
                  activationLink: LinksResponse.Link?) {
        super.init(factor: factor, stateToken: stateToken, verifyLink: verifyLink, activationLink: activationLink)
    }
}