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

class OktaAuthStatusPasswordWarningTests: XCTestCase {
    
    func testChangePassword() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        XCTAssertNotNil(status.model.expirationDate)
        XCTAssertNotNil(status.model.links?.next)
        XCTAssertNotNil(status.model.links?.skip)
        XCTAssertNotNil(status.model.links?.cancel)
        XCTAssertNotNil(status.model.embedded)
        XCTAssertNotNil(status.model.embedded?.policy)
        if case .password(let password) = status.model.embedded?.policy {
            XCTAssertNotNil(password.complexity)
            XCTAssertNotNil(password.expiration)
            XCTAssertNotNil(password.age)
        } else {
            XCTFail("Failed to parse policy.")
        }
        
        status.setupApiMockResponse(.SUCCESS)
        
        let ex = expectation(description: "Callback is expected!")
        
        status.changePassword(
            oldPassword: "1234",
            newPassword: "4321",
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(status.apiMock.changePasswordCalled)
    }
    
    func testChangePassword_ApiFailed() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockFailure()
        
        let ex = expectation(description: "Callback is expected!")
        
        status.changePassword(
            oldPassword: "1234",
            newPassword: "4321",
            onStatusChange: { status in
                XCTFail("Unexpected status change!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    "Server responded with error: Authentication failed",
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(status.apiMock.changePasswordCalled)
    }

    func testSkipChangePassword() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockResponse(.SUCCESS)
        
        let ex = expectation(description: "Callback is expected!")
        
        status.skipPasswordChange(
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(status.apiMock.performCalled)
    }
    
    // MARK: - Utils
    
    func createStatus(
        from currentStatus: OktaAuthStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!),
        withResponse response: TestResponse = .PASSWORD_WARNING)
        -> OktaAuthStatusPasswordWarning? {
            
            guard let response = response.parse() else {
                return nil
            }
            
            return try? OktaAuthStatusPasswordWarning(currentState: currentStatus, model: response)
    }
}
