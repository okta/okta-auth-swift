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

open class OktaAuthStatusUnauthenticated : OktaAuthStatus {

    override init(oktaDomain: URL, responseHandler: AuthStatusResponseHandler = AuthStatusResponseHandler()) {
        super.init(oktaDomain: oktaDomain, responseHandler: responseHandler)
        statusType = .unauthenticated
    }

    public func authenticate(username: String,
                             password: String,
                             onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void) {

        api.primaryAuthentication(username: username,
                                  password: password,
                                  deviceFingerprint: nil)
        { result in
            
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
    }

    public func unlockAccount(username: String,
                              factorType: FactorType,
                              onRecoveryChallenge: @escaping (_ recoveryChallengeStatus: OktaAuthStatusRecoveryChallenge) -> Void,
                              onError: @escaping (_ error: OktaError) -> Void) {
        // implement
    }
    
    public func recoverPassword(username: String,
                                factorType: FactorType,
                                onRecoveryChallenge: @escaping (_ recoveryChallengeStatus: OktaAuthStatusRecoveryChallenge) -> Void,
                                onError: @escaping (_ error: OktaError) -> Void) {
        // implement
    }
}