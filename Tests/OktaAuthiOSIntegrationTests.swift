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

class OktaAuthiOSIntegrationTests: XCTestCase {

    var domainURL = ProcessInfo.processInfo.environment["DOMAIN_URL"]!
    var username = ProcessInfo.processInfo.environment["USERNAME"]!
    var password = ProcessInfo.processInfo.environment["PASSWORD"]!

    var oktaAPI: OktaAPI!

    override func setUp() {
        oktaAPI = OktaAPI(oktaDomain: URL(string: domainURL)!)
    }

    override func tearDown() {
        oktaAPI = nil
    }

    func testPrimaryAuth_Success() {
        let exp = expectation(description: "Primary auth request should complete.")
        
        _ = oktaAPI.primaryAuthentication(
            username: username,
            password: password,
            audience: nil,
            relayState: nil,
            multiOptionalFactorEnroll: false,
            warnBeforePasswordExpired: false,
            token: nil,
            deviceToken: nil)
        { result in
            switch result {
                case .error(let error):
                    XCTFail("Unexpected error: \(error)")
                case .success(let response):
                    XCTAssertEqual(.success, response.status)
                    // TODO: extend response verification once model is implemented
                    break
            }
        
            exp.fulfill()
        }

        waitForExpectations(timeout: 5.0) { err in
            if let err = err {
                XCTFail(err.localizedDescription)
            }
        }
    }
    
    func testPrimaryAuth_InvalidPassword() {
        let exp = expectation(description: "Primary auth request should complete.")
    
        _ = oktaAPI.primaryAuthentication(
            username: username,
            // generate invalid password
            password: UUID().uuidString,
            audience: nil,
            relayState: nil,
            multiOptionalFactorEnroll: false,
            warnBeforePasswordExpired: false,
            token: nil, deviceToken: nil)
        { result in
            switch result {
                case .error(let error):
                    guard case let .serverRespondedWithError(oktaError) = error else {
                        XCTFail("Okta error expected!")
                        break
                    }
                    XCTAssertEqual("E0000004", oktaError.errorCode)
                    XCTAssertEqual("Authentication failed", oktaError.errorSummary)
                
                case .success(_):
                    XCTFail("Authentication with invalid password should fail!")
                    break
            }
        
            exp.fulfill()
        }

        waitForExpectations(timeout: 5.0) { err in
            if let err = err {
                XCTFail(err.localizedDescription)
            }
        }
    }
}
