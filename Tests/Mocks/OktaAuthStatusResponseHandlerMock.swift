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
import OktaAuthNative

class OktaAuthStatusResponseHandlerMock: OktaAuthStatusResponseHandler {

    var changedStatus: OktaAuthStatus?
    var error: OktaError?
    var statusUpdate: OktaAPISuccessResponse.FactorResult?

    var handleResponseCalled: Bool = false
    var response: OktaAPIRequest.Result?

    init(changedStatus: OktaAuthStatus? = nil, error: OktaError? = nil, statusUpdate: OktaAPISuccessResponse.FactorResult? = nil) {
        super.init()
        self.changedStatus = changedStatus
        self.error = error
        self.statusUpdate = statusUpdate
    }

    override func handleServerResponse(_ response: OktaAPIRequest.Result,
                              currentStatus: OktaAuthStatus,
                              onStatusChanged: @escaping (OktaAuthStatus) -> Void,
                              onError: @escaping (OktaError) -> Void) {
        self.handleResponseCalled = true
        self.response = response

        if let changedStatus = changedStatus {
            onStatusChanged(changedStatus)
            return
        }

        if let error = error {
            onError(error)
            return
        }
    }
}
