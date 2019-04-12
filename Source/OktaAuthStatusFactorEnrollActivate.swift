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

open class OktaAuthStatusFactorEnrollActivate : OktaAuthStatus, OktaFactorResultProtocol {
    
    public internal(set) var stateToken: String

    public lazy var factor: OktaFactor = {
        var createdFactor = OktaFactor.createFactorWith(internalFactor,
                                                        stateToken: stateToken,
                                                        verifyLink: nil,
                                                        activationLink: model.links?.next)
        createdFactor.responseDelegate = self
        createdFactor.restApi = self.restApi
        return createdFactor
    }()
    
    public let activateLink: LinksResponse.Link

    public var factorResult: OktaAPISuccessResponse.FactorResult? {
        get {
            return model.factorResult
        }
    }

    public func canResend() -> Bool {
        guard model.links?.resend?.first != nil else {
            return false
        }
        
        return true
    }

    public func activateFactor(passCode: String?,
                               onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                               onError: @escaping (_ error: OktaError) -> Void,
                               onFactorStatusUpdate: ((_ state: OktaAPISuccessResponse.FactorResult) -> Void)? = nil) {
        self.factor.activate(with: activateLink,
                             passCode: passCode,
                             onStatusChange: onStatusChange,
                             onError: onError,
                             onFactorStatusUpdate: onFactorStatusUpdate)
    }

    public func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void) {
        guard canResend() else {
            onError(.wrongStatus("Can't find 'resend' link in response"))
            return
        }

        restApi.perform(link: model.links!.resend!.first!,
                        stateToken: stateToken,
                        completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    override public func cancel(onSuccess: @escaping () -> Void, onError: @escaping (OktaError) -> Void) {
        self.factor.cancel()
        self.factor.responseDelegate = nil
        super.cancel(onSuccess: onSuccess, onError: onError)
    }

    var internalFactor: EmbeddedResponse.Factor

    override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) throws {
        guard let stateToken = model.stateToken else {
            throw OktaError.invalidResponse
        }
        guard let factor = model.embedded?.factor else {
            throw OktaError.invalidResponse
        }
        guard let activateLink = model.links?.next else {
            throw OktaError.invalidResponse
        }
        self.stateToken = stateToken
        self.internalFactor = factor
        self.activateLink = activateLink
        
        try super.init(currentState: currentState, model: model)
        
        statusType = .MFAEnrollActivate
    }

    func handleFactorServerResponse(response: OktaAPIRequest.Result,
                                    onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                    onError: @escaping (_ error: OktaError) -> Void,
                                    onFactorStatusUpdate: ((_ state: OktaAPISuccessResponse.FactorResult) -> Void)? = nil) {
        var authResponse : OktaAPISuccessResponse
        
        switch response {
        case .error(let error):
            onError(error)
            return
        case .success(let success):
            authResponse = success
        }
        
        if authResponse.factorResult != nil &&
            authResponse.status == self.statusType {
            onFactorStatusUpdate?(authResponse.factorResult!)
            
            if case .waiting = authResponse.factorResult! {
                guard let pollLink = authResponse.links?.next else {
                    onError(OktaError.invalidResponse)
                    return
                }
                self.factor.activate(with: pollLink,
                                     passCode: nil,
                                     onStatusChange: onStatusChange,
                                     onError: onError,
                                     onFactorStatusUpdate: onFactorStatusUpdate)
            }
        } else {
            self.handleServerResponse(response, onStatusChanged: onStatusChange, onError: onError)
        }
    }
}
