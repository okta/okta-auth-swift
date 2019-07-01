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

open class OktaAuthStatusFactorChallenge : OktaAuthStatus {
    
    public internal(set) var stateToken: String

    public override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) throws {
        guard let stateToken = model.stateToken else {
            throw OktaError.invalidResponse
        }
        guard let factor = model.embedded?.factor else {
            throw OktaError.invalidResponse
        }
        self.stateToken = stateToken
        internalFactor = factor
        
        try super.init(currentState: currentState, model: model)
        
        statusType = .MFAChallenge
    }

    open lazy var factor: OktaFactor = {
        var createdFactor = OktaFactor.createFactorWith(internalFactor,
                                                        stateToken: stateToken,
                                                        verifyLink: model.links?.next,
                                                        activationLink: nil)
        createdFactor.responseDelegate = self
        createdFactor.restApi = self.restApi
        return createdFactor
    }()

    open func canVerify() -> Bool {
        return factor.canVerify()
    }

    open func canResend() -> Bool {
        guard model.links?.resend != nil else {
            return false
        }
        
        return true
    }

    override open func canPoll() -> Bool {
        return model.links?.next?.name == "poll" || factor.type == .push
    }

    open func verifyFactor(passCode: String?,
                           answerToSecurityQuestion: String?,
                           onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                           onError: @escaping (_ error: OktaError) -> Void) {
        self.factor.verify(passCode: passCode,
                           answerToSecurityQuestion: answerToSecurityQuestion,
                           onStatusChange: onStatusChange,
                           onError: onError)
    }

    open func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                           onError: @escaping (_ error: OktaError) -> Void) {
        guard canResend() else {
            onError(.wrongStatus("Can't find 'resend' link in response"))
            return
        }

        let link :LinksResponse.Link
        let resendLink = self.model.links!.resend!
        switch resendLink {
        case .resend(let rawLink):
            link = rawLink
        case .resendArray(let rawArray):
            link = rawArray.first!
        }

        self.restApi.perform(link: link,
                             stateToken: stateToken,
                             completion: { result in
                                self.handleServerResponse(result,
                                                          onStatusChanged: onStatusChange,
                                                          onError: onError)
        })
    }

    override open func cancel(onSuccess: (() -> Void)? = nil,
                              onError: ((OktaError) -> Void)? = nil) {
        self.factor.cancel()
        super.cancel(onSuccess: onSuccess, onError: onError)
    }

    var internalFactor: EmbeddedResponse.Factor
}

extension OktaAuthStatusFactorChallenge: OktaFactorResultProtocol {
    public func handleFactorServerResponse(response: OktaAPIRequest.Result,
                                           onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                           onError: @escaping (_ error: OktaError) -> Void) {
        self.handleServerResponse(response, onStatusChanged: onStatusChange, onError: onError)
    }
}

