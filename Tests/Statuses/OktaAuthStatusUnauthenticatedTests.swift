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

class OktaAuthStatusUnauthenticatedTests: XCTestCase {

    // MARK: - authenticate
    
    func testAuthenticate() {
        let status = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!)
        
        status.setupApiMockResponse(.SUCCESS)

        let ex = expectation(description: "Callback is expected!")
        status.authenticate(
            username: "test",
            password: "test",
            deviceToken: "deviceToken",
            deviceFingerprint: "deviceFingerprint",
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)

        XCTAssertTrue(status.apiMock.primaryAuthenticationCalled)
    }
    
    func testAuthenticate_ApiFailure() {
        let status = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!)
        
        status.setupApiMockFailure()

        let ex = expectation(description: "Callback is expected!")
        status.authenticate(
            username: "test",
            password: "test",
            deviceToken: "deviceToken",
            deviceFingerprint: "deviceFingerprint",
            onStatusChange: { status in
                XCTFail("Unexpected status change: \(status)")
                ex.fulfill()
            }, onError: { error in
                XCTAssertEqual(
                    "Server responded with error: Authentication failed",
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(status.apiMock.primaryAuthenticationCalled)
    }
    
    // MARK: - unlockAccount
    
    func testUnlockAccount() {
        let status = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!)
        
        status.setupApiMockResponse(.SUCCESS)

        let ex = expectation(description: "Callback is expected!")
        status.unlockAccount(
            username: "test",
            factorType: .sms,
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(status.apiMock.unlockCalled)
    }
    
    func testUnlockAccount_ApiFailure() {
        let status = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!)
        
        status.setupApiMockFailure()
        
        let ex = expectation(description: "Callback is expected!")
        status.unlockAccount(
            username: "test",
            factorType: .sms,
            onStatusChange: { status in
                XCTFail("Unexpected status change: \(status)")
                ex.fulfill()
            }, onError: { error in
                XCTAssertEqual(
                    "Server responded with error: Authentication failed",
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(status.apiMock.unlockCalled)
    }
    
    // MARK: - recoverPassword
    
    func testRecoverPassword() {
        let status = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!)
        
        status.setupApiMockResponse(.SUCCESS)

        let ex = expectation(description: "Callback is expected!")
        status.recoverPassword(
            username: "test",
            factorType: .call,
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            }, onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(status.apiMock.recoverCalled)
    }
    
    func testRecoverPassword_ApiFailure() {
        let status = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!)
        
        status.setupApiMockFailure()

        let ex = expectation(description: "Callback is expected!")
        status.recoverPassword(
            username: "test",
            factorType: .call,
            onStatusChange: { status in
                XCTFail("Unexpected status change: \(status)")
                ex.fulfill()
            }, onError: { error in
                XCTAssertEqual(
                    "Server responded with error: Authentication failed",
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(status.apiMock.recoverCalled)
    }

}
