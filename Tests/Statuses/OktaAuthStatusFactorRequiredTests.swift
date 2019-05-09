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

class OktaAuthStatusFactorRequiredTests: XCTestCase {
    
    func testAvailableFactors() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        let factors = status.availableFactors
        let expectedFactors: [FactorType] = [
            .call,
            .token,
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
    
    // MARK: - select
    
    func testSelect() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockResponse(.MFA_CHALLENGE_SMS)
        
        guard let factor = status.availableFactors.first else {
            XCTFail()
            return
        }
        
        let ex = expectation(description: "Callback is expected!")

        status.selectFactor(
            factor,
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.MFAChallenge, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                ex.fulfill()
                XCTFail(error.localizedDescription)
            }
        )
        
        waitForExpectations(timeout: 5.0)
    }
    
    func testSelect_ApiFailed() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockFailure()
        
        guard let factor = status.availableFactors.first else {
            XCTFail()
            return
        }
        
        let ex = expectation(description: "Callback is expected!")

        status.selectFactor(
            factor,
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
    }
    
    // MARK: - cancel
    
    func testCancel() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }
        
        status.setupApiMockResponse(.MFA_REQUIRED)
        
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
        withResponse response: TestResponse = .MFA_REQUIRED)
        -> OktaAuthStatusFactorRequired? {

        guard let response = response.parse() else {
            return nil
        }
        
        return try? OktaAuthStatusFactorRequired(currentState: currentStatus, model: response)
    }
}
