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

class OktaAuthStatusFactorEnrollTests: XCTestCase {

    func testAvailableFactors() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        let factors = status.availableFactors
        let expectedFactors: [FactorType] = [
            .question,
            .sms,
            .push,
            .TOTP
        ]
        
        for (index, factor) in factors.enumerated() {
            XCTAssertEqual(expectedFactors[index], factor.type)
            XCTAssertEqual(status.stateToken, factor.stateToken)
            XCTAssertTrue(status === factor.responseDelegate)
            XCTAssertTrue(status.restApi === factor.restApi)
        }
    }
    
    // MARK: - skipEnrollment
    
    func testSkipEnrollment() {
        guard let status = createStatus(withResponse: .MFA_ENROLL_PartiallyEnrolled) else {
            XCTFail()
            return
        }
        
        status.setupApiMockResponse(.MFA_REQUIRED)
        
        let ex = expectation(description: "Callback is expected!")
        
        XCTAssertTrue(status.canSkipEnrollment())
        status.skipEnrollment(
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.MFARequired, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testSkipEnrollment_CannotSkip() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockResponse(.MFA_ENROLL_NotEnrolled)
        
        let ex = expectation(description: "Callback is expected!")
        
        XCTAssertFalse(status.canSkipEnrollment())
        status.skipEnrollment(
            onStatusChange: { status in
                XCTFail("Unexpected status change")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    OktaError.wrongStatus("Can't find 'skip' link in response").localizedDescription,
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testSkipEnrollment_ApiFailed() {
        guard let status = createStatus(withResponse: .MFA_ENROLL_PartiallyEnrolled) else {
            XCTFail()
            return
        }
        
        status.setupApiMockFailure()
        
        let ex = expectation(description: "Callback is expected!")
        
        XCTAssertTrue(status.canSkipEnrollment())
        status.skipEnrollment(
            onStatusChange: { status in
                XCTFail("Unexpected status change")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    "The operation couldn’t be completed. (OktaAuthNative_iOS_Tests.OktaError error 2.)",
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
    }
    
    // MARK: - enrollFactor
    
    func testEnrollFactor() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockResponse(.MFA_REQUIRED)

        guard let factor = status.availableFactors.first else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(status.apiMock === factor.restApi)
        
        let ex = expectation(description: "Callback is expected!")
        
        status.enrollFactor(
            factor: factor,
            questionId: "0000",
            answer: "test",
            credentialId: nil,
            passCode: nil,
            phoneNumber: nil,
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.MFARequired, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)

        XCTAssertTrue(status.apiMock.enrollCalled)
        XCTAssertEqual("0000", status.apiMock.enrollQuestionId)
        XCTAssertEqual("test", status.apiMock.enrollAnswer)
    }
    
    func testEnrollFactor_APiFailed() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockFailure()
        
        guard let factor = status.availableFactors.first else {
            XCTFail()
            return
        }
        
        XCTAssertTrue(status.apiMock === factor.restApi)
        
        let ex = expectation(description: "Callback is expected!")
        
        status.enrollFactor(
            factor: factor,
            questionId: "0000",
            answer: "test",
            credentialId: nil,
            passCode: nil,
            phoneNumber: nil,
            onStatusChange: { status in
                XCTFail("Unexpected status change!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    "The operation couldn’t be completed. (OktaAuthNative_iOS_Tests.OktaError error 2.)",
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)

        XCTAssertTrue(status.apiMock.enrollCalled)
        XCTAssertEqual("0000", status.apiMock.enrollQuestionId)
        XCTAssertEqual("test", status.apiMock.enrollAnswer)
    }
    
    // MARK: - cancel
    
    func testCancel() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockResponse(.MFA_ENROLL_NotEnrolled)
        
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
                "The operation couldn’t be completed. (OktaAuthNative_iOS_Tests.OktaError error 2.)",
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
        withResponse response: TestResponse = .MFA_ENROLL_NotEnrolled)
        -> OktaAuthStatusFactorEnroll? {

        guard let response = response.parse() else {
            return nil
        }
        
        return try? OktaAuthStatusFactorEnroll(currentState: currentStatus, model: response)
    }
}
