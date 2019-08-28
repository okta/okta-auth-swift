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

class OktaFactorPushTests: OktaFactorTestCase {

    func testActivation() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_ENROLL_ACTIVATE_Push, type: .push) else {
            XCTFail()
            return
        }

        XCTAssertNotNil(factor.activation)
        XCTAssertNotNil(factor.activationLinks)
        XCTAssertNotNil(factor.activationLinks?.send)
        XCTAssertNotNil(factor.activationLinks?.qrcode)
        XCTAssertEqual(
            "https://test.domain.com.com/api/v1/authn/factors/lifecycle/activate/sms",
            factor.codeViaSmsLink()?.href.absoluteString
        )
        XCTAssertEqual(
            "https://test.domain.com.com/api/v1/authn/factors/lifecycle/activate/email",
            factor.codeViaEmailLink()?.href.absoluteString
        )
        XCTAssertEqual(
            "https://test.domain.com.com/api/v1/users/factors/qr/cQYp5xpm",
            factor.qrCodeLink?.href.absoluteString
        )
    }

    func testCanSendPushCodeViaSms() {
        guard let enrollActivateFactor: OktaFactorPush = createFactor(from: .MFA_ENROLL_ACTIVATE_Push, type: .push) else {
            XCTFail()
            return
        }

        XCTAssertNotNil(enrollActivateFactor.codeViaSmsLink())
        XCTAssertTrue(enrollActivateFactor.canSendPushCodeViaSms())

        guard let mfaChallangeFactor: OktaFactorPush = createFactor(from: .MFA_CHALLENGE_WAITING_PUSH, type: .push) else {
            XCTFail()
            return
        }

        XCTAssertNil(mfaChallangeFactor.codeViaSmsLink())
        XCTAssertFalse(mfaChallangeFactor.canSendPushCodeViaSms())
    }

    func testCanSendPushCodeViaEmail() {
        guard let enrollActivateFactor: OktaFactorPush = createFactor(from: .MFA_ENROLL_ACTIVATE_Push, type: .push) else {
            XCTFail()
            return
        }

        XCTAssertNotNil(enrollActivateFactor.codeViaEmailLink())
        XCTAssertTrue(enrollActivateFactor.canSendPushCodeViaEmail())

        guard let mfaChallangeFactor: OktaFactorPush = createFactor(from: .MFA_CHALLENGE_WAITING_PUSH, type: .push) else {
            XCTFail()
            return
        }

        XCTAssertNil(mfaChallangeFactor.codeViaEmailLink())
        XCTAssertFalse(mfaChallangeFactor.canSendPushCodeViaEmail())
    }

    // MARK: - sendActivationLinkViaSms

    func testSendActivationLinkViaSms() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_ENROLL_ACTIVATE_Push, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockResponse(.MFA_REQUIRED)
        let ex = expectation(description: "Operation should succeed!")

        factor.sendActivationLinkViaSms(
            with: "012345678",
            onSuccess: {
                ex.fulfill()
            },
            onError: { error in
                XCTFail("Unexpected error: \(error)")
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        XCTAssertTrue(factor.apiMock.sendActivationLinkCalled)
        XCTAssertEqual("sms", factor.apiMock.sentActivationLink?.name)
    }

    func testSendActivationLinkViaSms_NoActivationLink() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_CHALLENGE_WAITING_PUSH, type: .push) else {
            XCTFail()
            return
        }

        let ex = expectation(description: "Operation should fail!")

        factor.sendActivationLinkViaSms(
            with: "012345678",
            onSuccess: {
                XCTFail("Operation should fail!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    OktaError.wrongStatus("Can't find 'send' link in response").localizedDescription,
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)
    }

    func testSendActivationLinkViaSms_ApiFailed() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_ENROLL_ACTIVATE_Push, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockFailure()
        let ex = expectation(description: "Operation should succeed!")

        factor.sendActivationLinkViaSms(
            with: "012345678",
            onSuccess: {
                XCTFail("Operation should succeed!")
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

        XCTAssertTrue(factor.apiMock.sendActivationLinkCalled)
        XCTAssertEqual("sms", factor.apiMock.sentActivationLink?.name)
    }

    // MARK: - sendActivationLinkViaEmail

    func testSendActivationLinkViaEmail() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_ENROLL_ACTIVATE_Push, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockResponse(.MFA_REQUIRED)
        let ex = expectation(description: "Operation should succeed!")

        factor.sendActivationLinkViaEmail(
            onSuccess: {
                ex.fulfill()
            },
            onError: { error in
                XCTFail("Unexpected error: \(error)")
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        XCTAssertTrue(factor.apiMock.sendActivationLinkCalled)
        XCTAssertEqual("email", factor.apiMock.sentActivationLink?.name)
    }

    func testSendActivationLinkViaEmail_NoActivationLink() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_CHALLENGE_WAITING_PUSH, type: .push) else {
            XCTFail()
            return
        }

        let ex = expectation(description: "Operation should fail!")

        factor.sendActivationLinkViaEmail(
            onSuccess: {
                XCTFail("Operation should fail!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    OktaError.wrongStatus("Can't find 'send' link in response").localizedDescription,
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)
    }

    func testSendActivationLinkViaEmail_ApiFailed() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_ENROLL_ACTIVATE_Push, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockFailure()
        let ex = expectation(description: "Operation should succeed!")

        factor.sendActivationLinkViaEmail(
            onSuccess: {
                XCTFail("Operation should succeed!")
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

        XCTAssertTrue(factor.apiMock.sendActivationLinkCalled)
        XCTAssertEqual("email", factor.apiMock.sentActivationLink?.name)
    }

    // MARK: - activate

    func testActivate() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_ENROLL_ACTIVATE_Push, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate = factor.setupMockDelegate(with: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!))

        let ex = expectation(description: "Operation should succeed!")

        factor.activate(
            onStatusChange: { status in
                XCTAssertEqual( AuthStatus.unauthenticated, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        verifyDelegateSucceeded(delegate, with: .MFA_REQUIRED)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual(factor.activationLink?.href, factor.apiMock.factorVerificationLink?.href)
    }

    func testActivate_ApiFailed() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_ENROLL_ACTIVATE_Push, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))

        let ex = expectation(description: "Operation should fail!")

        factor.activate(
            onStatusChange: { _ in
                XCTFail("API failure expected!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(delegate.error?.localizedDescription, error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        verifyDelegateFailed(delegate)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual(factor.activationLink?.href, factor.apiMock.factorVerificationLink?.href)
    }

    // MARK: - verify

    func testVerify() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_REQUIRED, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate = factor.setupMockDelegate(with: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!))

        let ex = expectation(description: "Operation should succeed!")

        factor.verify(
            onStatusChange: { status in
                XCTAssertEqual(delegate.changedStatus?.statusType, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        verifyDelegateSucceeded(delegate, with: .MFA_REQUIRED)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }

    func testVerify_ApiFailed() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_REQUIRED, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))

        let ex = expectation(description: "Operation should fail!")

        factor.verify(
            onStatusChange: { _ in
                XCTFail("Operation should fail!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(delegate.error?.localizedDescription, error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        verifyDelegateFailed(delegate)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }

    // MARK: - checkFactorResult

    func testCheckFactorResult() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_REQUIRED, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate = factor.setupMockDelegate(with: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!))

        let ex = expectation(description: "Operation should succeed!")

        factor.checkFactorResult(
            onStatusChange: { status in
                XCTAssertEqual(delegate.changedStatus?.statusType, status.statusType)
                ex.fulfill()
        },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        verifyDelegateSucceeded(delegate, with: .MFA_REQUIRED)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }

    func testCheckFactorResult_ApiFailed() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_REQUIRED, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))

        let ex = expectation(description: "Operation should fail!")

        factor.checkFactorResult(
            onStatusChange: { _ in
                XCTFail("Operation should fail!")
                ex.fulfill()
        },
            onError: { error in
                XCTAssertEqual(delegate.error?.localizedDescription, error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        verifyDelegateFailed(delegate)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }

    // MARK: - select

    func testSelect() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_REQUIRED, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate = factor.setupMockDelegate(with: try! OktaAuthStatusFactorChallenge(
            currentState: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!),
            model: TestResponse.MFA_CHALLENGE_WAITING_PUSH.parse()!
        ))

        let ex = expectation(description: "Operation should succeed!")

        factor.select(
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

        verifyDelegateSucceeded(delegate, with: .MFA_CHALLENGE_WAITING_PUSH)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }

    func testSelect_ApiFailed() {
        guard let factor: OktaFactorPush = createFactor(from: .MFA_REQUIRED, type: .push) else {
            XCTFail()
            return
        }

        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))

        let ex = expectation(description: "Operation should fail!")

        factor.select(
            onStatusChange: { _ in
                XCTFail("Operation should fail!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(delegate.error?.localizedDescription, error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        verifyDelegateFailed(delegate)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }
}
