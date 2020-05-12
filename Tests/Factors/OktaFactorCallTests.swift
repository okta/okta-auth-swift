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

class OktaFactorCallTests: OktaFactorTestCase {
    
    func testPhoneNumber() {
        var factor: OktaFactorCall? = createFactor(from: .MFA_ENROLL_NotEnrolled, type: .call)
        XCTAssertNil(factor?.phoneNumber)
        
        factor = createFactor(from: .MFA_REQUIRED, type: .call)
        XCTAssertEqual("OKTA_VERIFY", factor?.profile?.name)
        XCTAssertEqual("some@email.com", factor?.profile?.email)
        XCTAssertEqual("+1 XXX-XXX-1337", factor?.phoneNumber)
    }
    
    // MARK: - enroll
    
    func testEnroll() {
        guard let factor: OktaFactorCall = createFactor(from: .MFA_ENROLL_NotEnrolled, type: .call) else {
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
            phoneNumber: "12345678",
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
        XCTAssertEqual("12345678", factor.apiMock.enrollPhoneNumber)
    }
    
    func testEnroll_ApiFailure() {
        guard let factor: OktaFactorCall = createFactor(from: .MFA_ENROLL_NotEnrolled, type: .call) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))
        
        let ex = expectation(description: "Operation should fail!")
        
        factor.enroll(
            phoneNumber: "12345678",
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
        XCTAssertEqual("12345678", factor.apiMock.enrollPhoneNumber)
    }
    
    // MARK: - activate
    
    func testActivate() {
        guard let factor: OktaFactorCall = createFactor(from: .MFA_ENROLL_ACTIVATE_CALL, type: .call) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate = factor.setupMockDelegate(with: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!))
        
        let ex = expectation(description: "Operation should succeed!")
        
        factor.activate(passCode: "1234",
                        onStatusChange: { status in
                            XCTAssertEqual( AuthStatus.unauthenticated , status.statusType)
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
        guard let factor: OktaFactorCall = createFactor(from: .MFA_ENROLL_ACTIVATE_CALL, type: .call) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))
        
        let ex = expectation(description: "Operation should fail!")
        
        factor.activate(
            passCode: "1234",
            onStatusChange: { status in
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
        guard let factor: OktaFactorCall = createFactor(from: TestResponse.MFA_REQUIRED, type: .call) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate =  factor.setupMockDelegate(with: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!))
        
        let ex = expectation(description: "Operation should succeed!")
        
        factor.verify(
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
        
        verifyDelegateSucceeded(delegate, with: .MFA_REQUIRED)
        
        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual("1234", factor.apiMock.factorVerificationPassCode)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }
    
    func testVerify_ApiFailed() {
        guard let factor: OktaFactorCall = createFactor(from: TestResponse.MFA_REQUIRED, type: .call) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))
        
        let ex = expectation(description: "Operation should fail!")
        
        factor.verify(
            passCode: "1234",
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
        XCTAssertEqual("1234", factor.apiMock.factorVerificationPassCode)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }
    
    // MARK: - select
    
    func testSelect() {
        guard let factor: OktaFactorCall = createFactor(from: .MFA_REQUIRED, type: .call) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate = factor.setupMockDelegate(with: try! OktaAuthStatusFactorChallenge(
            currentState: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!),
            model: TestResponse.MFA_CHALLENGE_SMS.parse()!
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
        
        verifyDelegateSucceeded(delegate, with: .MFA_CHALLENGE_SMS)
        
        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }
    
    func testSelect_ApiFailed() {
        guard let factor: OktaFactorCall = createFactor(from: .MFA_REQUIRED, type: .call) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))
        
        let ex = expectation(description: "Operation should fail!")
        
        factor.select(
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
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }
}
