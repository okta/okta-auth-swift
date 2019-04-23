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

class OktaFactorQuestionTests: OktaFactorTestCase {
    
    func testFactorQuestionId() {
        var factor: OktaFactorQuestion? = createFactor(from: .MFA_ENROLL_NotEnroller, type: .question)
        XCTAssertNil(factor?.factorQuestionId)
        
        factor = createFactor(from: .MFA_REQUIRED, type: .question)
        XCTAssertEqual("favorite_security_question", factor?.factorQuestionId)
    }
    
    func testFactorQuestionText() {
        var factor: OktaFactorQuestion? = createFactor(from: .MFA_ENROLL_NotEnroller, type: .question)
        XCTAssertNil(factor?.factorQuestionText)
        
        factor = createFactor(from: .MFA_REQUIRED, type: .question)
        XCTAssertEqual("What is your favorite security question?", factor?.factorQuestionText)
    }
    
    // MARK: - enroll
    
    func testEnroll() {
        guard let factor: OktaFactorQuestion = createFactor(from: .MFA_ENROLL_NotEnroller, type: .question) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockResponse(.MFA_ENROLL_ACTIVATE_Push)
        let delegate = factor.setupMockDelegate(with: try! OktaAuthStatusFactorEnrollActivate(
            currentState: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!),
            model: TestResponse.MFA_ENROLL_ACTIVATE_SMS.parse()!
        ))
        
        let ex = expectation(description: "Operation should succeed!")
        
        factor.enroll(
            questionId: "0001",
            answer: "test",
            onStatusChange: { status in
                XCTAssertEqual( AuthStatus.MFAEnrollActivate , status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        verifyDelegateSucceeded(delegate, with: .MFA_ENROLL_ACTIVATE_SMS)
        
        XCTAssertTrue(factor.apiMock.enrollCalled)
        XCTAssertEqual("0001", factor.apiMock.enrollQuestionId)
        XCTAssertEqual("test", factor.apiMock.enrollAnswer)
    }
    
    func testEnroll_ApiFailure() {
         guard let factor: OktaFactorQuestion = createFactor(from: .MFA_ENROLL_NotEnroller, type: .question) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))
        
        let ex = expectation(description: "Operation should fail!")
        
        factor.enroll(
            questionId: "0001",
            answer: "test",
            onStatusChange: { status in
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
        XCTAssertEqual("0001", factor.apiMock.enrollQuestionId)
        XCTAssertEqual("test", factor.apiMock.enrollAnswer)
    }
    
    // MARK: - verify
    
    func testVerify() {
        guard let factor: OktaFactorQuestion = createFactor(from: TestResponse.MFA_REQUIRED, type: .question) else {
            XCTFail()
            return
        }

        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate = factor.setupMockDelegate(with: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!))
    
        let ex = expectation(description: "Operation should succeed!")
        
        factor.verify(
            answerToSecurityQuestion: "test",
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
        XCTAssertEqual("test", factor.apiMock.factorVerificationAnswer)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }

    func testVerify_ApiFailed() {
        guard let factor: OktaFactorQuestion = createFactor(from: TestResponse.MFA_REQUIRED, type: .question) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))
        
        let ex = expectation(description: "Operation should fail!")
        
        factor.verify(
            answerToSecurityQuestion: "test",
            onStatusChange: { status in
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
        XCTAssertEqual("test", factor.apiMock.factorVerificationAnswer)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }
    
    // MARK: - select
    
    func testSelect() {
        guard let factor: OktaFactorQuestion = createFactor(from: .MFA_REQUIRED, type: .question) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate = factor.setupMockDelegate(with: try! OktaAuthStatusSuccess(
            currentState: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!),
            model: TestResponse.SUCCESS.parse()!
        ))
        
        let ex = expectation(description: "Operation should succeed!")
        
        factor.select(
            answerToSecurityQuestion: "test",
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.description)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        verifyDelegateSucceeded(delegate, with: .SUCCESS)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual("test", factor.apiMock.factorVerificationAnswer)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }
    
    func testSelect_ApiFailed() {
        guard let factor: OktaFactorQuestion = createFactor(from: .MFA_REQUIRED, type: .question) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))
        
        let ex = expectation(description: "Operation should fail!")
        
        factor.select(
            answerToSecurityQuestion: "test",
            onStatusChange: { status in
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
        XCTAssertEqual("test", factor.apiMock.factorVerificationAnswer)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }
}
