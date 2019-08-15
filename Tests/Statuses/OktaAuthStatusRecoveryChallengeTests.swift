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

class OktaAuthStatusRecoveryChallengeTests: XCTestCase {

    func testRecoveryChallenge_Email() {
        guard let status = createStatusForEmailChallenge() else {
            XCTFail()
            return
        }
        
        XCTAssertFalse(status.canResend())
        XCTAssertFalse(status.canVerify())
        XCTAssertNil(status.model.stateToken)
        XCTAssertNotNil(status.factorResult)
        XCTAssertEqual(status.factorResult, .waiting)
        XCTAssertNotNil(status.factorType)
        XCTAssertEqual(status.factorType, .email)
        XCTAssertNotNil(status.recoveryType)
        XCTAssertEqual(status.recoveryType, .password)
        
        var ex = expectation(description: "Callback is expected!")

        status.resendFactor(
            onStatusChange: { status in
                XCTFail("Unexpected status change!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    "Invalid server response",
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)

        ex = expectation(description: "Callback is expected!")
        
        status.verifyFactor(
            passCode: "1234",
            onStatusChange: { status in
                XCTFail("Unexpected status change!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    "Invalid server response",
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
    }

    func testRecoveryChallenge_Sms() {
        guard let status = createStatusForSMSChallenge() else {
            XCTFail()
            return
        }

        XCTAssert(status.canResend())
        XCTAssert(status.canVerify())
        XCTAssertNotNil(status.model.stateToken)
        XCTAssertNotNil(status.factorType)
        XCTAssertEqual(status.factorType, .sms)
        XCTAssertNotNil(status.recoveryType)
        XCTAssertEqual(status.recoveryType, .password)
        
        status.setupApiMockResponse(.SUCCESS)
        
        var ex = expectation(description: "Callback is expected!")
        
        status.verifyFactor(
            passCode: "1234",
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        XCTAssertTrue(status.apiMock.verifyFactorCalled)
        waitForExpectations(timeout: 5.0)

        ex = expectation(description: "Callback is expected!")
        status.setupApiMockResponse(.SUCCESS)
        status.resendFactor(
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        XCTAssertTrue(status.apiMock.performCalled)
        waitForExpectations(timeout: 5.0)
    }

    func testChangePassword_ApiFailed() {
        guard let status = createStatusForSMSChallenge() else {
            XCTFail()
            return
        }
        
        status.setupApiMockFailure()
        
        var ex = expectation(description: "Callback is expected!")
        
        status.verifyFactor(
            passCode: "1234",
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
        
        XCTAssertTrue(status.apiMock.verifyFactorCalled)

        status.setupApiMockFailure()
        
        ex = expectation(description: "Callback is expected!")
        
        status.resendFactor(
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
        
        XCTAssertTrue(status.apiMock.performCalled)
    }
    
    func testVerifyWithRecoveryTonken() {
        guard let status = createStatusForSMSChallenge() else {
            XCTFail()
            return
        }
        
        status.setupApiMockResponse(.SUCCESS)
        
        let ex = expectation(description: "Callback is expected!")
        status.verifyFactor(
            recoveryToken: "test_token",
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
        
        XCTAssertTrue(status.apiMock.verifyFactorCalled)
    }

    // MARK: - Utils
    
    func createStatusForSMSChallenge(
        from currentStatus: OktaAuthStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!),
        withResponse response: TestResponse = .RECOVERY_CHALLENGE_SMS)
        -> OktaAuthStatusRecoveryChallenge? {
            
            guard let response = response.parse() else {
                return nil
            }
            
            return try? OktaAuthStatusRecoveryChallenge(currentState: currentStatus, model: response)
    }

    func createStatusForEmailChallenge(
        from currentStatus: OktaAuthStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!),
        withResponse response: TestResponse = .RECOVERY_CHALLENGE_EMAIL)
        -> OktaAuthStatusRecoveryChallenge? {
            
            guard let response = response.parse() else {
                return nil
            }
            
            return try? OktaAuthStatusRecoveryChallenge(currentState: currentStatus, model: response)
    }
}
