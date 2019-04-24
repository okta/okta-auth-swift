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

class OktaAuthStatusTests: XCTestCase {

    // MARK: - returnToPreviousStatus
    
    func testReturnToPreviousStatus() {
        guard let response = TestResponse.MFA_ENROLL_ACTIVATE_SMS.parse(),
              let status = try? OktaAuthStatusFactorEnrollActivate(currentState: createUnathenticatedStatus(), model: response) else {
              XCTFail()
              return
        }
        
        status.setupApiMockResponse(.MFA_REQUIRED)
        
        let ex = expectation(description: "Operation should succeed!")
        
        XCTAssertTrue(status.canReturn())
        status.returnToPreviousStatus(
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
        
        XCTAssertTrue(status.apiMock.performCalled)
    }
    
    func testReturnToPreviousStatus_CannotReturn() {
        let status = createUnathenticatedStatus()
        status.setupApiMockResponse(.SUCCESS)
        
        let ex = expectation(description: "Operation should fail!")
        
        XCTAssertFalse(status.canReturn())
        status.returnToPreviousStatus(
            onStatusChange: { status in
                XCTFail("Unexpected status change!")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    OktaError.wrongStatus("Can't find 'prev' link in response").localizedDescription,
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)

        XCTAssertFalse(status.apiMock.performCalled)
    }
    
    func testReturnToPreviousStatus_ApiError() {
        guard let response = TestResponse.MFA_ENROLL_ACTIVATE_SMS.parse(),
              let status = try? OktaAuthStatusFactorEnrollActivate(currentState: createUnathenticatedStatus(), model: response) else {
              XCTFail()
              return
        }
        
        status.setupApiMockFailure()
        
        let ex = expectation(description: "Operation should fail!")
        
        XCTAssertTrue(status.canReturn())
        status.returnToPreviousStatus(
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
        guard let response = TestResponse.MFA_ENROLL_ACTIVATE_SMS.parse(),
              let status = try? OktaAuthStatusFactorEnrollActivate(currentState: createUnathenticatedStatus(), model: response) else {
              XCTFail()
              return
        }
        
        status.setupApiMockResponse(.MFA_REQUIRED)
        
        let ex = expectation(description: "Operation should succeed!")
        
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
    
    func testCancel_Unauthenticated() {
        let status = createUnathenticatedStatus()
        
        status.setupApiMockResponse(.SUCCESS)
        
        let ex = expectation(description: "Operation should fail!")

        XCTAssertFalse(status.canCancel())
        status.cancel(onSuccess: {
            ex.fulfill()
        }, onError: { error in
            XCTFail(error.localizedDescription)
            ex.fulfill()
        })
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertFalse(status.apiMock.cancelTransactionCalled)
    }
    
    func testCancel_cannotCancel() {
        guard let response = TestResponse.SUCCESS.parse(),
              let status = try? OktaAuthStatusSuccess(currentState: createUnathenticatedStatus(), model: response) else {
              XCTFail()
              return
        }
        
        status.setupApiMockResponse(.SUCCESS)
        
        let ex = expectation(description: "Operation should fail!")
        
        XCTAssertFalse(status.canCancel())
        status.cancel(onSuccess: {
            XCTFail("Status should not be canceled!")
            ex.fulfill()
        }, onError: { error in
            XCTAssertEqual(
                OktaError.wrongStatus("Can't find 'cancel' link in response").localizedDescription,
                error.localizedDescription
            )
            ex.fulfill()
        })
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertFalse(status.apiMock.cancelTransactionCalled)
    }
    
    func testCancel_ApiError() {
        guard let response = TestResponse.MFA_ENROLL_ACTIVATE_SMS.parse(),
              let status = try? OktaAuthStatusFactorEnrollActivate(currentState: createUnathenticatedStatus(), model: response) else {
              XCTFail()
              return
        }
        
        status.setupApiMockFailure()
        
        let ex = expectation(description: "Operation should fail!")

        XCTAssertTrue(status.canCancel())
        status.cancel(onSuccess: {
            XCTFail("Status should not be canceled!")
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
    
    // MARK: - poll
    
    func testPoll() {
        guard let response = TestResponse.MFA_CHALLENGE_WAITING_PUSH.parse(),
              let status = try? OktaAuthStatusFactorChallenge(currentState: createUnathenticatedStatus(), model: response) else {
              XCTFail()
              return
        }
        
        status.setupApiMockResponse(.SUCCESS)
        
        let ex = expectation(description: "Operation should succeed!")
        
        status.poll(
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)

        XCTAssertTrue(status.apiMock.verifyFactorCalled)
        XCTAssertEqual(response.links?.next?.href, status.apiMock.factorVerificationLink?.href)
    }
    
    func testPoll_ApiError() {
        guard let response = TestResponse.MFA_CHALLENGE_WAITING_PUSH.parse(),
              let status = try? OktaAuthStatusFactorChallenge(currentState: createUnathenticatedStatus(), model: response) else {
              XCTFail()
              return
        }
        
        status.setupApiMockFailure()
        
        let ex = expectation(description: "Operation should fail!")
        
        status.poll(
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

        XCTAssertTrue(status.apiMock.verifyFactorCalled)
        XCTAssertEqual(response.links?.next?.href, status.apiMock.factorVerificationLink?.href)
    }
    
    // MARK: - fetchStatus
    
    func testFetchStatus() {
        let handlerMock = OktaAuthStatusResponseHandlerMock(
            changedStatus: try! OktaAuthStatusSuccess(
                currentState: createUnathenticatedStatus(),
                model: TestResponse.SUCCESS.parse()!
            )
        )
        let status = createUnathenticatedStatus(handlerMock)
        
        status.setupApiMockResponse(.SUCCESS)
        
        let ex = expectation(description: "Operation should succeed!")
        
        status.fetchStatus(with: "0000",
            onStatusChange: { status in
                XCTAssertEqual(AuthStatus.success, status.statusType)
                ex.fulfill()
            },
            onError: { error in
                XCTFail(error.localizedDescription)
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(status.apiMock.getTransactionStateCalled)
        XCTAssertTrue(handlerMock.handleResponseCalled)
    }
    
    func testFetchStatus_ApiError() {
        let handlerMock = OktaAuthStatusResponseHandlerMock(error: OktaError.internalError("Test"))
        let status = createUnathenticatedStatus(handlerMock)
        
        status.setupApiMockFailure()
        
        let ex = expectation(description: "Operation should failed!")
        
        status.fetchStatus(with: "0000",
            onStatusChange: { status in
                XCTFail("Unexpected status change")
                ex.fulfill()
            },
            onError: { error in
                XCTAssertEqual(
                    OktaError.internalError("Test").localizedDescription,
                    error.localizedDescription
                )
                ex.fulfill()
            }
        )
        
        waitForExpectations(timeout: 5.0)
        
        XCTAssertTrue(status.apiMock.getTransactionStateCalled)
        XCTAssertTrue(handlerMock.handleResponseCalled)
    }
    
    // MARK: - Utils
    
    func createUnathenticatedStatus(_ handler: OktaAuthStatusResponseHandlerMock? = nil) -> OktaAuthStatusUnauthenticated {
        guard let handler = handler else {
            return OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.domain.com")!)
        }
        
        return OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://mock.domain.com")!, responseHandler: handler)
    }
}
