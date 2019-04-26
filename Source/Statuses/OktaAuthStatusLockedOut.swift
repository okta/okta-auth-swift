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

open class OktaAuthStatusLockedOut : OktaAuthStatus {

    public override init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) throws {
        try super.init(currentState: currentState, model: model)
        statusType = .lockedOut
    }

    open func canUnlock() -> Bool {
        guard model.links?.next?.href != nil else {
            return false
        }
        
        return true
    }

    open func unlock(username: String,
                     factorType: OktaRecoveryFactors,
                     onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                     onError: @escaping (_ error: OktaError) -> Void) {
        guard canUnlock() else {
            onError(.wrongStatus("Can't find 'next' link in response"))
            return
        }

        do {
            let unauthenticated = try OktaAuthStatusUnauthenticated(currentState: self, model: self.model)
            unauthenticated.unlockAccount(username: username,
                                          factorType: factorType,
                                          onStatusChange: onStatusChange,
                                          onError: onError)
        } catch let error {
            onError(error as! OktaError)
        }
    }
}
