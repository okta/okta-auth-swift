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

open class OktaAuthStatusFactorEnroll : OktaAuthStatus {

    override init(oktaDomain: URL, model: OktaAPISuccessResponse, responseHandler: AuthStatusCustomHandlerProtocol? = nil) {
        super.init(oktaDomain: oktaDomain, model: model, responseHandler: responseHandler)
        statusType = .MFAEnroll
    }
    
    override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) {
        super.init(currentState: currentState, model: model)
        statusType = .MFAEnroll
    }

    public var availableFactors: [EmbeddedResponse.Factor]? {
        get {
            return model.embedded?.factors
        }
    }

    public func canEnrollFactor(factor: EmbeddedResponse.Factor) -> Bool {
        guard factor.links?.enroll?.href != nil else {
            return false
        }
        
        return true
    }

    public func canSkipEnrollment() -> Bool {
        guard model.links?.skip?.href != nil else {
            return false
        }
        
        return true
    }

    public func skipEnrollment(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                               onError: @escaping (_ error: OktaError) -> Void) {
        guard canSkipEnrollment() else {
            onError(.wrongState("Can't find 'skip' link in response"))
            return
        }
        
        api.perform(link: model.links!.skip!, stateToken: model.stateToken!) { result in
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
    }

    public func downloadSecurityQuestionsForFactor(_ factor: EmbeddedResponse.Factor,
                                                   onDownloadComplete: @escaping ([SecurityQuestion]) -> Void,
                                                   onError: @escaping (_ error: OktaError) -> Void) {
        guard factor.links?.questions?.href != nil else {
            onError(.wrongState("Can't find 'questions' link in response"))
            return
        }

        api.downloadSecurityQuestions(with: factor.links!.questions!, onCompletion: onDownloadComplete, onError: onError)
    }

    public func enrollSecurityQuestionFactor(_ factor: EmbeddedResponse.Factor,
                                             questionId: String,
                                             answer: String,
                                             onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                             onError: @escaping (_ error: OktaError) -> Void) {
        guard canEnrollFactor(factor: factor) else {
            onError(.wrongState("Can't find 'enroll' link in response"))
            return
        }

        api.enrollFactor(factor,
                         with: factor.links!.enroll!,
                         stateToken: model.stateToken!,
                         phoneNumber: nil,
                         questionId: questionId,
                         answer: answer,
                         credentialId: nil,
                         passCode: nil,
                         completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public func enrollSmsFactor(factor: EmbeddedResponse.Factor,
                                phoneNumber: String,
                                onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                onError: @escaping (_ error: OktaError) -> Void) {
        guard canEnrollFactor(factor: factor) else {
            onError(.wrongState("Can't find 'enroll' link in response"))
            return
        }
        
        api.enrollFactor(factor,
                         with: factor.links!.enroll!,
                         stateToken: model.stateToken!,
                         phoneNumber: phoneNumber,
                         questionId: nil,
                         answer: nil,
                         credentialId: nil,
                         passCode: nil,
                         completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public func enrollCallFactor(factor: EmbeddedResponse.Factor,
                                 phoneNumber: String,
                                 onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                 onError: @escaping (_ error: OktaError) -> Void) {
        guard canEnrollFactor(factor: factor) else {
            onError(.wrongState("Can't find 'enroll' link in response"))
            return
        }
        
        api.enrollFactor(factor,
                         with: factor.links!.enroll!,
                         stateToken: model.stateToken!,
                         phoneNumber: phoneNumber,
                         questionId: nil,
                         answer: nil,
                         credentialId: nil,
                         passCode: nil,
                         completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public func enrollTOTPFactor(factor: EmbeddedResponse.Factor,
                                 onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                 onError: @escaping (_ error: OktaError) -> Void) {
        guard canEnrollFactor(factor: factor) else {
            onError(.wrongState("Can't find 'enroll' link in response"))
            return
        }
        
        api.enrollFactor(factor,
                         with: factor.links!.enroll!,
                         stateToken: model.stateToken!,
                         phoneNumber: nil,
                         questionId: nil,
                         answer: nil,
                         credentialId: nil,
                         passCode: nil,
                         completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public func enrollPushFactor(factor: EmbeddedResponse.Factor,
                                 onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                 onError: @escaping (_ error: OktaError) -> Void) {
        guard canEnrollFactor(factor: factor) else {
            onError(.wrongState("Can't find 'enroll' link in response"))
            return
        }
        
        api.enrollFactor(factor,
                         with: factor.links!.enroll!,
                         stateToken: model.stateToken!,
                         phoneNumber: nil,
                         questionId: nil,
                         answer: nil,
                         credentialId: nil,
                         passCode: nil,
                         completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public func enrollSecureIDFactor(factor: EmbeddedResponse.Factor,
                                     credentialId: String,
                                     passCode: String,
                                     onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                     onError: @escaping (_ error: OktaError) -> Void) {
        guard canEnrollFactor(factor: factor) else {
            onError(.wrongState("Can't find 'enroll' link in response"))
            return
        }
        
        api.enrollFactor(factor,
                         with: factor.links!.enroll!,
                         stateToken: model.stateToken!,
                         phoneNumber: nil,
                         questionId: nil,
                         answer: nil,
                         credentialId: credentialId,
                         passCode: passCode,
                         completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }
}
