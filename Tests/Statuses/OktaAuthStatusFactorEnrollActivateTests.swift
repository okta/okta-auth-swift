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

class OktaAuthStatusFactorEnrollActivateTests: XCTestCase {
    
    func testFactor_Sms() {
        guard let statusSms = createStatus(withResponse: .MFA_ENROLL_ACTIVATE_SMS) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(FactorType.sms, statusSms.factor.type)
        XCTAssertTrue(statusSms === statusSms.factor.responseDelegate)
        XCTAssertTrue(statusSms.restApi === statusSms.factor.restApi)
    }
    
    func testFactor_Push() {
        guard let statusSms = createStatus(withResponse: .MFA_ENROLL_ACTIVATE_Push) else {
            XCTFail()
            return
        }
        
        XCTAssertEqual(FactorType.push, statusSms.factor.type)
        XCTAssertTrue(statusSms === statusSms.factor.responseDelegate)
        XCTAssertTrue(statusSms.restApi === statusSms.factor.restApi)
    }
    
    // MARK: - resend
    
    func testResend() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockResponse(.MFA_ENROLL_ACTIVATE_SMS)
        
        let ex = expectation(description: "Callback is expected!")
        
        status.resendFactor(
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.MFAEnrollActivate, status.statusType)
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
        
        XCTAssertTrue(status.apiMock.performCalled)
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
        withResponse response: TestResponse = .MFA_ENROLL_ACTIVATE_SMS)
        -> OktaAuthStatusFactorEnrollActivate? {

        guard let response = response.parse() else {
            return nil
        }
        
        return try? OktaAuthStatusFactorEnrollActivate(currentState: currentStatus, model: response)
    }
}
