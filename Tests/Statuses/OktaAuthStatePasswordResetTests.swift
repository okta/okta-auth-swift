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

class OktaAuthStatePasswordResetTests: XCTestCase {

    func testResetPassword() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }

        status.setupApiMockResponse(.SUCCESS)

        let ex = expectation(description: "Callback is expected!")

        status.resetPassword(
            newPassword: "1234",
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

        XCTAssertTrue(status.apiMock.resetPasswordCalled)
    }

    func testResetPassword_ApiFailed() {
        guard let status = createStatus() else {
            XCTFail()
            return
        }

        status.setupApiMockFailure()

        let ex = expectation(description: "Callback is expected!")

        status.resetPassword(
            newPassword: "1234",
            onStatusChange: { _ in
                XCTFail("Unexpected status change!")
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

        XCTAssertTrue(status.apiMock.resetPasswordCalled)
    }

    // MARK: - Utils

    func createStatus(
        from currentStatus: OktaAuthStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "http://test.com")!),
        withResponse response: TestResponse = .PASSWORD_RESET)
        -> OktaAuthStatusPasswordReset? {

        guard let response = response.parse() else {
            return nil
        }

        return try? OktaAuthStatusPasswordReset(currentState: currentStatus, model: response)
    }
}
