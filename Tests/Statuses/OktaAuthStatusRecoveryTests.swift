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

class OktaAuthStatusRecoveryTests: XCTestCase {
    
    func testRecoveryChallenge() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }

        XCTAssertNotNil(status.stateToken)
        XCTAssertNotNil(status.recoveryQuestion)
        XCTAssertNil(status.recoveryToken)
        XCTAssertNotNil(status.recoveryType)
        XCTAssert(status.canRecover())
        XCTAssert(status.canCancel())
        
        var ex = expectation(description: "Callback is expected!")
        status.setupApiMockResponse(.SUCCESS)
        status.recoverWithAnswer(
            "Answer",
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        XCTAssertTrue(status.apiMock.recoverCalled)
        waitForExpectations(timeout: 5.0)
        
        ex = expectation(description: "Callback is expected!")
        status.setupApiMockResponse(.SUCCESS)
        status.recoverWithToken(
            "Token",
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        XCTAssertTrue(status.apiMock.recoverCalled)
        waitForExpectations(timeout: 5.0)
    }

    func testChangePassword_ApiFailed() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockFailure()
        
        var ex = expectation(description: "Callback is expected!")
        
        status.recoverWithAnswer(
            "Answer",
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
        
        XCTAssertTrue(status.apiMock.recoverCalled)
        
        status.setupApiMockFailure()

        ex = expectation(description: "Callback is expected!")

        status.recoverWithToken(
            "Token",
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
        
        XCTAssertTrue(status.apiMock.recoverCalled)
    }

    // MARK: - Utils
    
    func createStatus(
        from currentStatus: OktaAuthStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!),
        withResponse response: TestResponse = .RECOVERY)
        -> OktaAuthStatusRecovery? {
            
            guard let response = response.parse() else {
                return nil
            }
            
            return try? OktaAuthStatusRecovery(currentState: currentStatus, model: response)
    }
}
