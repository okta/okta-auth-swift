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

class OktaAuthStatusResponseHandlerTests: XCTestCase {

    func testHandleServerResponse_Success() {
        verifyHandleServerResponse(.SUCCESS, expectedStatus: .success)
    }

    func testHandleServerResponse_PasswordWarning() {
       verifyHandleServerResponse(.PASSWORD_WARNING, expectedStatus: .passwordWarning)
    }

    func testHandleServerResponse_PasswordExpired() {
        verifyHandleServerResponse(.PASSWORD_EXPIRED, expectedStatus: .passwordExpired)
    }

    func testHandleServerResponse_PasswordReset() {
        verifyHandleServerResponse(.PASSWORD_RESET, expectedStatus: .passwordReset)
    }

    func testHandleServerResponse_MFAEnroll() {
        verifyHandleServerResponse(.MFA_ENROLL_NotEnrolled, expectedStatus: .MFAEnroll)
    }

    func testHandleServerResponse_MFAEnrollActivate() {
        verifyHandleServerResponse(.MFA_ENROLL_ACTIVATE_SMS, expectedStatus: .MFAEnrollActivate)
    }

    func testHandleServerResponse_MFARequired() {
        verifyHandleServerResponse(.MFA_REQUIRED, expectedStatus: .MFARequired)
    }

    func testHandleServerResponse_MFAChallenge_SMS() {
        verifyHandleServerResponse(.MFA_CHALLENGE_SMS, expectedStatus: .MFAChallenge)
    }

    func testHandleServerResponse_MFAChallenge_WaitingPush() {
        verifyHandleServerResponse(.MFA_CHALLENGE_WAITING_PUSH, expectedStatus: .MFAChallenge)
    }

    func testHandleServerResponse_MFAChallenge_WaitingPush_alreadyWaiting() {
        let unauthenticatedStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.domain.url")!)
        guard let model = TestResponse.MFA_CHALLENGE_WAITING_PUSH.parse(),
              let challengeStatus = try? OktaAuthStatusFactorChallenge(currentState: unauthenticatedStatus, model: model) else {
              XCTFail()
              return
        }

        challengeStatus.setupApiMockResponse(.MFA_CHALLENGE_WAITING_PUSH)

        var ex = expectation(description: "Callback should be called")

        let handler = OktaAuthStatusResponseHandler()
        handler.handleServerResponse(
            OktaAPIRequest.Result.success(model),
            currentStatus: challengeStatus,
            onStatusChanged: { status in
                XCTAssertEqual(challengeStatus.statusType, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        waitForExpectations(timeout: 5.0)

        challengeStatus.setupApiMockResponse(.MFA_CHALLENGE_WAITING_PUSH)
        ex = expectation(description: "Callback should be called")
        handler.handleServerResponse(
            OktaAPIRequest.Result.success(model),
            currentStatus: challengeStatus,
            onStatusChanged: { status in
                XCTAssertEqual(challengeStatus.statusType, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)
    }

    func testHandleServerResponse_LockedOut() {
        verifyHandleServerResponse(.LOCKED_OUT, expectedStatus: .lockedOut)
    }

    func testHandleServerResponse_Recovery() {
        verifyHandleServerResponse(.RECOVERY, expectedStatus: .recovery)
    }

    func testHandleServerResponse_RecoveryChallenge() {
        verifyHandleServerResponse(.RECOVERY_CHALLENGE_SMS, expectedStatus: .recoveryChallenge)
    }

    func testHandleServerResponse_Error() {
        let initialStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.domain.url")!)
        let expectedError = OktaError.emptyServerResponse

        let ex = expectation(description: "Callback should be called")

        let handler = OktaAuthStatusResponseHandler()
        handler.handleServerResponse(
            OktaAPIRequest.Result.error(expectedError),
            currentStatus: initialStatus,
            onStatusChanged: { _ in
                XCTFail("Unexpected status change!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(expectedError.localizedDescription, error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)
    }

    // MARK: - Utils

    func verifyHandleServerResponse(
        _ testResponse: TestResponse,
        expectedStatus: AuthStatus,
        initialStatus: OktaAuthStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.domain.url")!)) {
        guard let response = testResponse.parse() else {
            XCTFail()
            return
        }

        initialStatus.setupApiMockResponse(testResponse)

        let ex = expectation(description: "Callback should be called")

        let handler = OktaAuthStatusResponseHandler()
        handler.handleServerResponse(
            OktaAPIRequest.Result.success(response),
            currentStatus: initialStatus,
            onStatusChanged: { status in
                XCTAssertEqual(expectedStatus, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)
    }

}
