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

class OktaFactorTokenTests: OktaFactorTestCase {

    func testProperties() {
        guard let factor: OktaFactorToken = createFactor(from: .MFA_REQUIRED, type: .token) else {
            XCTFail()
            return
        }

        XCTAssertNotNil(factor.credentialId)
        XCTAssertNotNil(factor.factorProvider)
        XCTAssertEqual(factor.credentialId, "dade.murphy@example.com")
        XCTAssertEqual(factor.factorProvider, .rsa)
    }

    // MARK: - enroll

    func testEnroll() {
        guard let factor: OktaFactorToken = createFactor(from: .MFA_ENROLL_NotEnrolled, type: .token) else {
            XCTFail()
            return
        }

        factor.setupApiMockResponse(.SUCCESS)
        let delegate = factor.setupMockDelegate(with: try! OktaAuthStatusSuccess(
            currentState: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!),
            model: TestResponse.SUCCESS.parse()!
            ))

        let ex = expectation(description: "Operation should succeed!")

        factor.enroll(
            credentialId: "dade.murphy@example.com",
            passCode: "1234",
            onStatusChange: { status in
                XCTAssertEqual( AuthStatus.success, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )

        waitForExpectations(timeout: 5.0)

        verifyDelegateSucceeded(delegate, with: .SUCCESS)
        XCTAssertTrue(factor.apiMock.enrollCalled)
    }

    func testEnroll_ApiFailure() {
        guard let factor: OktaFactorToken = createFactor(from: .MFA_ENROLL_NotEnrolled, type: .token) else {
            XCTFail()
            return
        }

        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))

        let ex = expectation(description: "Operation should fail!")

        factor.enroll(
            credentialId: "dade.murphy@example.com",
            passCode: "1234",
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

        XCTAssertTrue(factor.apiMock.enrollCalled)
    }

    // MARK: - verify

    func testVerify() {
        guard let factor: OktaFactorToken = createFactor(from: .MFA_REQUIRED, type: .token) else {
            XCTFail()
            return
        }

        factor.setupApiMockResponse(.SUCCESS)
        let delegate =  factor.setupMockDelegate(with: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!))

        let ex = expectation(description: "Operation should succeed!")

        factor.select(
            passCode: "1234",
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

        verifyDelegateSucceeded(delegate, with: .SUCCESS)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual("1234", factor.apiMock.factorVerificationPassCode)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }

    func testVerify_ApiFailed() {
        guard let factor: OktaFactorToken = createFactor(from: .MFA_REQUIRED, type: .token) else {
            XCTFail()
            return
        }

        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))

        let ex = expectation(description: "Operation should fail!")

        factor.select(
            passCode: "1234",
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
        XCTAssertEqual("1234", factor.apiMock.factorVerificationPassCode)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }
}
