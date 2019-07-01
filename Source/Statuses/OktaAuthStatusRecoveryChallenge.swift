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

open class OktaAuthStatusRecoveryChallenge : OktaAuthStatus {

    public override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) throws {
        try super.init(currentState: currentState, model: model)
        statusType = .recoveryChallenge
    }

    open var recoveryType: OktaAPISuccessResponse.RecoveryType? {
        get {
            return model.recoveryType
        }
    }

    open var factorType: FactorType? {
        get {
            return model.factorType
        }
    }

    open func canVerify() -> Bool {
        guard model.links?.next != nil else {
            return false
        }
        
        return true
    }

    open func canResend() -> Bool {
        guard model.links?.resend != nil else {
            return false
        }
        
        return true
    }

    open func verifyFactor(passCode: String,
                           onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                           onError: @escaping (_ error: OktaError) -> Void) {
        guard let stateToken = model.stateToken else {
            onError(.invalidResponse)
            return
        }
        guard canVerify() else {
            onError(.wrongStatus("Can't find 'next' link in response"))
            return
        }

        restApi.verifyFactor(with: model.links!.next!,
                             stateToken: stateToken,
                             answer: nil,
                             passCode: passCode,
                             recoveryToken: nil,
                             rememberDevice: nil,
                             autoPush: nil) { result in
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
    }

    open func verifyFactor(recoveryToken: String,
                           onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                           onError: @escaping (_ error: OktaError) -> Void) {
        guard let stateToken = model.stateToken else {
            onError(.invalidResponse)
            return
        }
        guard canVerify() else {
            onError(.wrongStatus("Can't find 'next' link in response"))
            return
        }
        
        restApi.verifyFactor(with: model.links!.next!,
                             stateToken: stateToken,
                             answer: nil,
                             passCode: nil,
                             recoveryToken: recoveryToken,
                             rememberDevice: nil,
                             autoPush: nil) { result in
                                self.handleServerResponse(result,
                                                          onStatusChanged: onStatusChange,
                                                          onError: onError)
        }
    }

    open func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                           onError: @escaping (_ error: OktaError) -> Void) {
        guard let stateToken = model.stateToken else {
            onError(.invalidResponse)
            return
        }
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
        
        restApi.perform(link: link,
                        stateToken: stateToken,
                        completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }
}
