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
    
    public internal(set) var stateToken: String
    
    public override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) throws {
        guard let stateToken = model.stateToken else {
            throw OktaError.invalidResponse
        }
        guard let factors = model.embedded?.factors else {
            throw OktaError.invalidResponse
        }
        self.stateToken = stateToken
        self.factors = factors
        try super.init(currentState: currentState, model: model)
        statusType = .MFAEnroll
    }

    open lazy var availableFactors: [OktaFactor] = {
        var oktaFactors = Array<OktaFactor>()
        for factor in self.factors {
            var createdFactor = OktaFactor.createFactorWith(factor,
                                                            stateToken: stateToken,
                                                            verifyLink: nil,
                                                            activationLink: nil)
            createdFactor.restApi = restApi
            createdFactor.responseDelegate = self
            oktaFactors.append(createdFactor)
        }
        
        return oktaFactors
    }()

    open func canEnrollFactor(factor: OktaFactor) -> Bool {
        return factor.canEnroll()
    }

    open func canSkipEnrollment() -> Bool {
        guard model.links?.skip?.href != nil else {
            return false
        }
        
        return true
    }

    open func skipEnrollment(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void) {
        guard canSkipEnrollment() else {
            onError(.wrongStatus("Can't find 'skip' link in response"))
            return
        }
        
        restApi.perform(link: model.links!.skip!, stateToken: stateToken) { result in
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
    }

    open func enrollFactor(factor: OktaFactor,
                           questionId: String?,
                           answer: String?,
                           credentialId: String?,
                           passCode: String?,
                           phoneNumber: String?,
                           onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                           onError: @escaping (_ error: OktaError) -> Void) {
        selectedFactor = factor
        factor.enroll(questionId: questionId,
                      answer: answer,
                      credentialId: credentialId,
                      passCode: passCode,
                      phoneNumber: phoneNumber,
                      onStatusChange: onStatusChange,
                      onError: onError)
    }

    override open func cancel(onSuccess: (() -> Void)? = nil,
                              onError: ((OktaError) -> Void)? = nil) {
        selectedFactor?.cancel()
        super.cancel(onSuccess: onSuccess, onError: onError)
    }

    var factors: [EmbeddedResponse.Factor]
    var selectedFactor: OktaFactor?
}

extension OktaAuthStatusFactorEnroll: OktaFactorResultProtocol {
    public func handleFactorServerResponse(response: OktaAPIRequest.Result,
                                           onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                           onError: @escaping (_ error: OktaError) -> Void) {
        self.handleServerResponse(response, onStatusChanged: onStatusChange, onError: onError)
    }
}
