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

open class OktaAuthStatusRecovery : OktaAuthStatus {

    public internal(set) var stateToken: String

    public override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) throws {
        guard let stateToken = model.stateToken else {
            throw OktaError.invalidResponse
        }
        self.stateToken = stateToken
        try super.init(currentState: currentState, model: model)
        statusType = .recovery
    }
    
    open var recoveryQuestion: String? {
        get {
            return model.embedded?.user?.recoveryQuestion?.question
        }
    }

    open var recoveryToken: String? {
        get {
            return model.recoveryToken
        }
    }

    open var recoveryType: OktaAPISuccessResponse.RecoveryType? {
        get {
            return model.recoveryType
        }
    }

    open func canRecover() -> Bool {
        guard model.links?.next != nil else {
            return false
        }
        
        return true
    }

    open func recoverWithAnswer(_ answer: String,
                                onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                onError: @escaping (_ error: OktaError) -> Void) {
        guard canRecover() else {
            onError(.wrongStatus("Can't find 'next' link in response"))
            return
        }
        
        restApi.recoverWith(answer: answer,
                            stateToken: stateToken,
                            recoveryToken: nil, link: model.links!.next!) { result in
                self.handleServerResponse(result,
                                          onStatusChanged: onStatusChange,
                                          onError: onError)
        }
    }

    open func recoverWithToken(_ recoveryToken: String,
                               onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                               onError: @escaping (_ error: OktaError) -> Void) {
        guard canRecover() else {
            onError(.wrongStatus("Can't find 'next' link in response"))
            return
        }
        
        restApi.recoverWith(answer: nil,
                            stateToken: stateToken,
                            recoveryToken: recoveryToken, link: model.links!.next!) { result in
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
    }
}
