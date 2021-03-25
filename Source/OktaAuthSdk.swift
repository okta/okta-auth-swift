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

public class OktaAuthSdk {

    public class func authenticate(with url: URL,
                                   username: String,
                                   password: String?,
                                   deviceToken: String? = nil,
                                   onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                   onError: @escaping (_ error: OktaError) -> Void) {
        
        let unauthenticatedStatus = OktaAuthStatusUnauthenticated(oktaDomain: url)
        unauthenticatedStatus.authenticate(username: username,
                                           password: password ?? "",
                                           deviceToken: deviceToken,
                                           onStatusChange:onStatusChange,
                                           onError:onError)
    }

    public class func unlockAccount(with url: URL,
                                    username: String,
                                    factorType: OktaRecoveryFactors,
                                    onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                    onError: @escaping (_ error: OktaError) -> Void) {
        
        let unauthenticatedStatus = OktaAuthStatusUnauthenticated(oktaDomain: url)
        unauthenticatedStatus.unlockAccount(username: username,
                                            factorType: factorType,
                                            onStatusChange:onStatusChange,
                                            onError: onError)
    }

    public class func recoverPassword(with url: URL,
                                      username: String,
                                      factorType: OktaRecoveryFactors,
                                      onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                      onError: @escaping (_ error: OktaError) -> Void) {
        
        let unauthenticatedStatus = OktaAuthStatusUnauthenticated(oktaDomain: url)
        unauthenticatedStatus.recoverPassword(username: username,
                                              factorType: factorType,
                                              onStatusChange: onStatusChange,
                                              onError: onError)
    }

    public class func fetchStatus(with stateToken: String,
                                  using url: URL,
                                  onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                  onError: @escaping (_ error: OktaError) -> Void) {
        let authState = OktaAuthStatus(oktaDomain: url)
        authState.fetchStatus(with: stateToken, onStatusChange: onStatusChange, onError: onError)
    }
}
