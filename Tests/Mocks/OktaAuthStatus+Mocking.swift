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

extension OktaAuthStatus {
    var apiMock: OktaAPIMock! {
        return self.restApi as? OktaAPIMock
    }

    @discardableResult func setupApiMockFailure(from resourceName: String = "AuthenticationFailedError") -> OktaAPIMock! {
        let mock = OktaAPIMock(successCase: false, resourceName: resourceName)!
        self.restApi = mock
        return mock
    }

    @discardableResult func setupApiMockResponse(_ response: TestResponse ) -> OktaAPIMock! {
        let mock = OktaAPIMock(successCase: true, resourceName: response.rawValue)!
        self.restApi = mock
        return mock
    }
}
