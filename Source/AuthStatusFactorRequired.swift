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

public class OktaAuthStatusFactorRequired : OktaAuthStatus {
    
    init(oktaDomain: URL, model: OktaAPISuccessResponse) {
        super.init(oktaDomain: oktaDomain)
        self.model = model
        statusType = .MFARequired
    }

    public var availableFactors: [EmbeddedResponse.Factor]? {
        get {
            return model?.embedded?.factors
        }
    }

    public func selectFactor(factor: EmbeddedResponse.Factor,
                             onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void) {
        self.triggerFactor(factor: factor,
                           stateToken: model!.stateToken!,
                           answer: nil,
                           passCode: nil,
                           completion: { result in
                            
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }
/*
    public func verifySecurityQuestionAnswer(answer: String,
                                             onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                             onError: @escaping (_ error: OktaError) -> Void) {
        guard let factors :[EmbeddedResponse.Factor] = model?.embedded?.factors else {
            onError(OktaError.invalidResponse)
            return
        }

        var foundFactor: EmbeddedResponse.Factor?
        for factor in factors {
            if (factor.factorType == .question) {
                foundFactor = factor
                break
            }
        }

        guard foundFactor != nil else {
            onError(OktaError.factorNotAvailable(model!))
            return
        }

        let completion = { result in
            
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }

        self.verifyFactor(factor: foundFactor!,
                          stateToken: model!.stateToken!,
                          answer: answer,
                          passCode: nil,
                          completion: completion)
    }

    public func verifyTotpCode(totpCode: String,
                               onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                               onError: @escaping (_ error: OktaError) -> Void) {
        guard let factors :[EmbeddedResponse.Factor] = model?.embedded?.factors else {
            onError(OktaError.invalidResponse)
            return
        }
        
        var foundFactor: EmbeddedResponse.Factor?
        for factor in factors {
            if (factor.factorType == .TOTP) {
                foundFactor = factor
                break
            }
        }
        
        guard foundFactor != nil else {
            onError(OktaError.factorNotAvailable(model!))
            return
        }
        
        let completion = { result in
            
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
        
        self.verifyFactor(factor: foundFactor!,
                          stateToken: model!.stateToken!,
                          answer: nil,
                          passCode: totpCode,
                          completion: completion)
    }
*/
    func triggerFactor(factor: EmbeddedResponse.Factor,
                       stateToken: String,
                       answer: String?,
                       passCode: String?,
                       completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> Void {
        if let link = factor.links?.verify {
            self.api.verifyFactor(with: link,
                                  stateToken: model!.stateToken!,
                                  answer: nil,
                                  passCode: nil,
                                  rememberDevice: nil,
                                  autoPush: nil,
                                  completion: completion)
        } else {
            self.api.verifyFactor(factorId: factor.id!,
                                  stateToken: model!.stateToken!,
                                  answer: nil,
                                  passCode: nil,
                                  rememberDevice: nil,
                                  autoPush: nil,
                                  completion: completion)
        }
    }
}
