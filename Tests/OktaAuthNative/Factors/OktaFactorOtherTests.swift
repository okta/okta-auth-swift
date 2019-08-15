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

class OktaFactorOtherTests: OktaFactorTestCase {

    func testSendApiRequest() {
        guard let factor: OktaFactorOther = createFactor(from: .MFA_ENROLL_NotEnrolled, type: .unknown("unknown")) else {
            XCTFail()
            return
        }

        XCTAssertEqual(factor.provider, .unknown("Unknown"))
        
        factor.setupApiMockResponse(.SUCCESS)
        let delegate = factor.setupMockDelegate(with: try! OktaAuthStatusSuccess(
            currentState: OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.url")!),
            model: TestResponse.SUCCESS.parse()!
            ))
        
        let ex = expectation(description: "Operation should succeed!")
        
        factor.sendRequest(
            with: factor.factor.links!.enroll!,
            keyValuePayload: [:],
            onStatusChange: { status in
                XCTAssertEqual( AuthStatus.success , status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        verifyDelegateSucceeded(delegate, with: .SUCCESS)
        
        XCTAssertTrue(factor.apiMock.sendApiRequestCalled)
    }

    func testSendApiRequest_ApiFailure() {
        guard let factor: OktaFactorOther = createFactor(from: .MFA_ENROLL_NotEnrolled, type: .unknown("unknown")) else {
            XCTFail()
            return
        }
        
        factor.setupApiMockFailure()
        let delegate = factor.setupMockDelegate(with: OktaError.internalError("Test"))
        
        let ex = expectation(description: "Operation should fail!")

        factor.sendRequest(
            with: factor.factor.links!.enroll!,
            keyValuePayload: [:],
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
        
        XCTAssertTrue(factor.apiMock.sendApiRequestCalled)
    }
}
