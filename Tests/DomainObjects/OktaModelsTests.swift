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

class OktaModelsTests: XCTestCase {

    var decoder: JSONDecoder!

    override func setUp() {
        decoder = JSONDecoder()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(formatter)
    }

    override func tearDown() {
        decoder = nil
    }

    func testSuccessResponse_PrimaryAuth() {
        guard let jsonData = readResponse(named: "PrimaryAuthResponse") else {
            XCTFail("Test resource missing.")
            return
        }
        
        let response: OktaAPISuccessResponse
        do {
            response = try decoder.decode(OktaAPISuccessResponse.self, from: jsonData)
        } catch let e {
            XCTFail("JSON parsing failed with error: \(e)")
            return
        }

        XCTAssertEqual(AuthStatus.success, response.status)
        XCTAssertNil(response.stateToken)
        XCTAssertEqual("test_session_token", response.sessionToken)
        XCTAssertNotNil(response.expirationDate)
        XCTAssertNil(response.relayState)
        XCTAssertNil(response.factorResult)

        XCTAssertNotNil(response.embedded)
        
        // User
        XCTAssertEqual("test_user_id", response.embedded?.user?.id)
        XCTAssertNotNil(response.embedded?.user?.passwordChanged)
        XCTAssertEqual("testname.testlastname@okta.com", response.embedded?.user?.profile?.login)
        XCTAssertEqual("TestName", response.embedded?.user?.profile?.firstName)
        XCTAssertEqual("TestLastName", response.embedded?.user?.profile?.lastName)
        XCTAssertEqual("America/Los_Angeles", response.embedded?.user?.profile?.timeZone)
        
        XCTAssertNil(response.embedded?.policy)
        XCTAssertNil(response.embedded?.target)
        XCTAssertNil(response.embedded?.authentication)
        
        XCTAssertNil(response.links)
    }
    
    func testSuccessResponse_PrimaryAuthWithFactors() {
        guard let jsonData = readResponse(named: "PrimaryAuthFactorsResponse") else {
            XCTFail("Test resource missing.")
            return
        }
        
        let response: OktaAPISuccessResponse
        do {
            response = try decoder.decode(OktaAPISuccessResponse.self, from: jsonData)
        } catch let e {
            XCTFail("JSON parsing failed with error: \(e)")
            return
        }

        XCTAssertEqual(AuthStatus.MFARequired, response.status)
        XCTAssertEqual("test_state_token", response.stateToken)
        XCTAssertNil(response.sessionToken)
        XCTAssertNotNil(response.expirationDate)
        XCTAssertNil(response.relayState)
        XCTAssertNil(response.factorResult)

        XCTAssertNotNil(response.embedded)
        
        // User
        XCTAssertEqual("test_user_id", response.embedded?.user?.id)
        XCTAssertNotNil(response.embedded?.user?.passwordChanged)
        XCTAssertEqual("testname.testlastname@okta.com", response.embedded?.user?.profile?.login)
        XCTAssertEqual("TestName", response.embedded?.user?.profile?.firstName)
        XCTAssertEqual("TestLastName", response.embedded?.user?.profile?.lastName)
        XCTAssertEqual("America/Los_Angeles", response.embedded?.user?.profile?.timeZone)
        
        // Policy
        XCTAssertNotNil(response.embedded?.policy)
        if case .rememberDevice(let rememberDevice)? = response.embedded?.policy {
            XCTAssertEqual(false, rememberDevice.allowRememberDevice)
            XCTAssertEqual(0, rememberDevice.rememberDeviceLifetimeInMinutes)
            XCTAssertEqual(false, rememberDevice.rememberDeviceByDefault)
        } else {
            XCTFail("Failed to parse policy.")
        }
        
        XCTAssertNil(response.embedded?.target)
        XCTAssertNil(response.embedded?.authentication)
        
        XCTAssertNotNil(response.links)
        XCTAssertNotNil(response.links?.cancel)
        XCTAssertEqual(URL(string: "https://test_link/cancel")!, response.links?.cancel?.href)
        XCTAssertNil(response.links?.next)
        XCTAssertNil(response.links?.prev)
        XCTAssertNil(response.links?.resend)
        XCTAssertNil(response.links?.skip)
    }

    func testSuccessResponse_UnknownStatus() {
        guard let jsonData = readResponse(named: "Unknown_State_And_FactorResult") else {
            XCTFail("Test resource missing.")
            return
        }
        
        let response: OktaAPISuccessResponse
        do {
            response = try decoder.decode(OktaAPISuccessResponse.self, from: jsonData)
        } catch let e {
            XCTFail("JSON parsing failed with error: \(e)")
            return
        }
        
        XCTAssertEqual(AuthStatus.unknown("SOME_STATUS"), response.status)
        XCTAssertEqual(OktaAPISuccessResponse.FactorResult.unknown("SOME_FACTOR_RESULT"), response.factorResult)
    }
    
    func testErrorResponse_AuthenticationFailed() {
        guard let jsonData = readResponse(named: "AuthenticationFailedError") else {
            XCTFail("Test resource missing.")
            return
        }
        
        let response: OktaAPIErrorResponse
        do {
            response = try decoder.decode(OktaAPIErrorResponse.self, from: jsonData)
        } catch let e {
            XCTFail("JSON parsing failed with error: \(e)")
            return
        }
        
        XCTAssertEqual("E0000004", response.errorCode)
        XCTAssertEqual("Authentication failed", response.errorSummary)
        XCTAssertEqual("E0000004", response.errorLink)
        XCTAssertEqual("oaep_fwxUiwQjSHsMRpsv4pMg", response.errorId)
        XCTAssertEqual(0, response.errorCauses?.count ?? 0)
    }

    func testErrorResponse_OperationNotAllowed() {
        guard let jsonData = readResponse(named: "OperationNotAllowedError") else {
            XCTFail("Test resource missing.")
            return
        }
        
        let response: OktaAPIErrorResponse
        do {
            response = try decoder.decode(OktaAPIErrorResponse.self, from: jsonData)
        } catch let e {
            XCTFail("JSON parsing failed with error: \(e)")
            return
        }
        
        XCTAssertEqual("E0000079", response.errorCode)
        XCTAssertEqual("This operation is not allowed in the current authentication state.", response.errorSummary)
        XCTAssertEqual("E0000079", response.errorLink)
        XCTAssertEqual("oae601OOxRbRImSztKcjduZ2w", response.errorId)
        XCTAssertNotNil(response.errorCauses)
        XCTAssertEqual("This operation is not allowed in the current authentication state.", response.errorCauses?.first?.errorSummary)
    }

    // MARK: - Utils
    
    private func readResponse(named name: String) -> Data? {
        guard let url = Bundle.init(for: self.classForCoder).url(forResource: name, withExtension: nil) else {
            return nil
        }
        
        return try? Data(contentsOf: url)
    }
}
