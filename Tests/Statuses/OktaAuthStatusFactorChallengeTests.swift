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

class OktaAuthStatusFactorChallengeTests: XCTestCase {

    func testFactor_Sms() {
        guard let statusSms = createStatus(withResponse: .MFA_CHALLENGE_SMS) else {
            XCTFail()
            return
        }

        XCTAssertEqual(FactorType.sms, statusSms.factor.type)
        XCTAssertTrue(statusSms === statusSms.factor.responseDelegate)
        XCTAssertTrue(statusSms.restApi === statusSms.factor.restApi)
    }

    func testFactor_Totp() {
        guard let statusSms = createStatus(withResponse: .MFA_CHALLENGE_TOTP) else {
            XCTFail()
            return
        }

        XCTAssertEqual(FactorType.TOTP, statusSms.factor.type)
        XCTAssertTrue(statusSms === statusSms.factor.responseDelegate)
        XCTAssertTrue(statusSms.restApi === statusSms.factor.restApi)
    }

    func testFactor_Push() {
        guard let statusPush = createStatus(withResponse: .MFA_CHALLENGE_WAITING_PUSH) else {
            XCTFail()
            return
        }

        XCTAssertEqual(FactorType.push, statusPush.factor.type)
        XCTAssertEqual(OktaAPISuccessResponse.FactorResult.waiting, statusPush.model.factorResult)
        XCTAssertTrue(statusPush === statusPush.factor.responseDelegate)
        XCTAssertTrue(statusPush.restApi === statusPush.factor.restApi)
    }

    // MARK: - verify

    func testVerifyFactor() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }

        status.setupApiMockResponse(.MFA_CHALLENGE_SMS)

        let ex = expectation(description: "Callback is expected!")

        status.verifyFactor(
            passCode: "1234",
            answerToSecurityQuestion: nil,
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.MFAChallenge, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        XCTAssertTrue(status.apiMock.verifyFactorCalled)
        XCTAssertEqual("1234", status.apiMock.factorVerificationPassCode)
    }

    func testVerifyFactor_ApiFailed() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }

        status.setupApiMockFailure()

        let ex = expectation(description: "Callback is expected!")

        status.verifyFactor(
            passCode: "1234",
            answerToSecurityQuestion: nil,
            onStatusChange: { _ in
                XCTFail("Unexpected status change")
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
        XCTAssertEqual("1234", status.apiMock.factorVerificationPassCode)
    }

    // MARK: - resend

    func testResend() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }

        status.setupApiMockResponse(.MFA_CHALLENGE_SMS)

        let ex = expectation(description: "Callback is expected!")

        status.resendFactor(
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.MFAChallenge, status.statusType)
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

    func testResend_ApiFailed() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }

        status.setupApiMockFailure()

        let ex = expectation(description: "Callback is expected!")

        status.resendFactor(
            onStatusChange: { _ in
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

    // MARK: - cancel

    func testCancel() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }

        status.setupApiMockResponse(.MFA_CHALLENGE_SMS)

        let ex = expectation(description: "Callback is expected!")

        XCTAssertTrue(status.canCancel())
        status.cancel(onSuccess: {
            ex.fulfill()
        }, onError: { error in
            XCTFail(error.localizedDescription)
            ex.fulfill()
        })

        waitForExpectations(timeout: 5.0)

        XCTAssertTrue(status.apiMock.cancelTransactionCalled)
    }

    func testCancel_ApiFailed() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }

        status.setupApiMockFailure()

        let ex = expectation(description: "Callback is expected!")

        XCTAssertTrue(status.canCancel())
        status.cancel(onSuccess: {
            XCTFail("Unexpected callback!")
            ex.fulfill()
        }, onError: { error in
            XCTAssertEqual(
                "Server responded with error: Authentication failed",
                error.localizedDescription
            )
            ex.fulfill()
        })

        waitForExpectations(timeout: 5.0)

        XCTAssertTrue(status.apiMock.cancelTransactionCalled)
    }

    // MARK: - Utils

    func createStatus(
        from currentStatus: OktaAuthStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!),
        withResponse response: TestResponse = .MFA_CHALLENGE_SMS)
        -> OktaAuthStatusFactorChallenge? {

        guard let response = response.parse() else {
            return nil
        }

        return try? OktaAuthStatusFactorChallenge(currentState: currentStatus, model: response)
    }
}
