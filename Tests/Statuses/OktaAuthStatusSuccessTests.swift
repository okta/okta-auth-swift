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

import XCTest
@testable import OktaAuthNative

class OktaAuthStatusSuccessTests: XCTestCase {
    
    func testSuccessSignIn() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        XCTAssertNotNil(status.sessionToken)
        XCTAssertNil(status.recoveryType)
    }
    
    func testSuccessUnlock() {
        guard let status = createStatus(from: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!),
                                        withResponse: .SUCCESS_UNLOCK) else {
            XCTFail()
            return
        }
        
        XCTAssertNil(status.sessionToken)
        XCTAssertNotNil(status.recoveryType)
    }
    
    // MARK: - Utils
    
    func createStatus(
        from currentStatus: OktaAuthStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!),
        withResponse response: TestResponse = .SUCCESS)
        -> OktaAuthStatusSuccess? {
            
            guard let response = response.parse() else {
                return nil
            }
            
            return try? OktaAuthStatusSuccess(currentState: currentStatus, model: response)
    }
}
