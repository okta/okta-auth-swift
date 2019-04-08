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

open class OktaAuthStatusPasswordWarning : OktaAuthStatus {

    override init(oktaDomain: URL, model: OktaAPISuccessResponse, responseHandler: AuthStatusCustomHandlerProtocol? = nil) {
        super.init(oktaDomain: oktaDomain, model: model, responseHandler: responseHandler)
        statusType = .passwordWarning
    }
    
    override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) {
        super.init(currentState: currentState, model: model)
        statusType = .passwordWarning
    }

    public func changePassword(oldPassword: String,
                               newPassword: String,
                               onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                               onError: @escaping (_ error: OktaError) -> Void) {

        let changePasswordStatus = OktaAuthStatusPasswordExpired(currentState: self, model: self.model)
        changePasswordStatus.changePassword(oldPassword: oldPassword,
                                            newPassword: newPassword,
                                            onStatusChange: onStatusChange,
                                            onError: onError)
    }

    public func skipPasswordChange(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                   onError: @escaping (_ error: OktaError) -> Void) {

        guard canSkip() else {
            onError(.wrongState("Can't find 'skip' link in response"))
            return
        }

        api.perform(link: model.links!.skip!, stateToken: model.stateToken!) { result in

            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
    }

    public func canSkip() -> Bool {
        
        guard (model.links?.skip?.href) != nil else {
            return false
        }

        return true
    }
}
