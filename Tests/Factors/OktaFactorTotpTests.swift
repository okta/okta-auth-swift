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

class OktaFactorTotpTests: OktaFactorTestCase {
    
    // MARK: - verify
    
    func testVerify() {
        guard let factor: OktaFactorTotp = createFactor(from: TestResponse.MFA_REQUIRED, type: .TOTP) else {
            XCTFail()
            return
        }
    
        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate = factor.setupMockDelegate(with: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!))
    
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
        guard let factor: OktaFactorTotp = createFactor(from: TestResponse.MFA_REQUIRED, type: .TOTP) else {
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
        
        guard let delegateResponse = delegate.response,
              case .error(_) = delegateResponse else {
            XCTFail("Delegate should be called with error!")
            return
        }
    }
    
    // MARK: - select
    
    func testSelect() {
        guard let factor: OktaFactorTotp = createFactor(from: .MFA_REQUIRED, type: .TOTP) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockResponse(.MFA_REQUIRED)
        let delegate = factor.setupMockDelegate(with: try! OktaAuthStatusFactorChallenge(
            currentState: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!),
            model: TestResponse.MFA_CHALLENGE_TOTP.parse()!
        ))
        
        let ex = expectation(description: "Operation should succeed!")
        
        factor.select(
            passCode: "1234",
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.MFAChallenge, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.description)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        verifyDelegateSucceeded(delegate, with: .MFA_CHALLENGE_TOTP)

        XCTAssertTrue(factor.apiMock.verifyFactorCalled)
        XCTAssertEqual("1234", factor.apiMock.factorVerificationPassCode)
        XCTAssertEqual(factor.verifyLink?.href, factor.apiMock.factorVerificationLink?.href)
    }
    
    func testSelect_ApiFailed() {
        guard let factor: OktaFactorTotp = createFactor(from: .MFA_REQUIRED, type: .TOTP) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))
        
        let ex = expectation(description: "Operation should fail!")
        
        factor.select(
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
}
