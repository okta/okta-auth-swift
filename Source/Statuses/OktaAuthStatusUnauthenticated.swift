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

public enum OktaRecoveryFactors {
    case email
    case sms
    case call
}

open class OktaAuthStatusUnauthenticated : OktaAuthStatus {

    open func authenticate(username: String,
                           password: String,
                           onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                           onError: @escaping (_ error: OktaError) -> Void) {

        restApi.primaryAuthentication(username: username,
                                      password: password,
                                      deviceFingerprint: nil)
        { result in
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
    }

    open func unlockAccount(username: String,
                            factorType: OktaRecoveryFactors,
                            onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                            onError: @escaping (_ error: OktaError) -> Void) {
        // implement
    }
    
    open func recoverPassword(username: String,
                              factorType: OktaRecoveryFactors,
                              onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                              onError: @escaping (_ error: OktaError) -> Void) {
        var internalFactorType: FactorType = .email
        if factorType == .sms {
            internalFactorType = .sms
        } else if factorType == .call {
            internalFactorType = .call
        }

        restApi.recoverPassword(username: username, factor: internalFactorType) { result in
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
    }

    override init(oktaDomain: URL, responseHandler: OktaAuthStatusResponseHandler = OktaAuthStatusResponseHandler()) {
        super.init(oktaDomain: oktaDomain, responseHandler: responseHandler)
        statusType = .unauthenticated
    }
}
