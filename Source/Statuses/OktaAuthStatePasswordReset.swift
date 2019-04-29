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

open class OktaAuthStatusPasswordReset : OktaAuthStatus {

    public internal(set) var stateToken: String

    public override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) throws {
        guard let stateToken = model.stateToken else {
            throw OktaError.invalidResponse
        }
        self.stateToken = stateToken
        if let policy = model.embedded?.policy {
            switch policy {
            case .password(let password):
                passwordExpiration = password.expiration
                passwordComplexity = password.complexity
            default:
                break
            }
        }
        try super.init(currentState: currentState, model: model)
        statusType = .passwordReset
    }

    open var passwordExpiration: EmbeddedResponse.Policy.Password.PasswordExpiration?

    open var passwordComplexity: EmbeddedResponse.Policy.Password.PasswordComplexity?

    open func canReset() -> Bool {
        
        guard model.links?.next?.href != nil else {
            return false
        }
        
        return true
    }

    open func resetPassword(newPassword: String,
                            onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                            onError: @escaping (_ error: OktaError) -> Void) {
        guard canReset() else {
            onError(.wrongStatus("Can't find 'next' link in response"))
            return
        }

        restApi.resetPassword(newPassword: newPassword, stateToken: stateToken, link: model.links!.next!) { result in
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
    }
}
