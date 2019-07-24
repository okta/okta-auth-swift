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

class E2ETests: XCTestCase {
    
    let username = ProcessInfo.processInfo.environment["USERNAME"]!
    let password = ProcessInfo.processInfo.environment["PASSWORD"]!
    let urlString = ProcessInfo.processInfo.environment["DOMAIN_URL"]!

    var user1: String?
    var user2: String?
    var password1: String?
    var password2: String?

    override func setUp() {
        
        if let _ = user1,
           let _ = user2,
           let _ = password1,
           let _ = password2 {
            return
        }
        
        let usernames = username.split(separator: ";")
        user1 = String(usernames.first!)
        user2 = String(usernames.last!)
        let passwords = password.split(separator: ";")
        password1 = String(passwords.first!)
        password2 = String(passwords.last!)
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPrimaryAuthFlowSuccess() {
        let ex = expectation(description: "Operation should succeed!")
        OktaAuthSdk.authenticate(with: URL(string: urlString)!, username: user1!, password: password1!, onStatusChange: { status in
            XCTAssertTrue(status.statusType == .success)
            self.verifyBasicInfoForStatus(status: status)
            let successStatus = status as! OktaAuthStatusSuccess
            XCTAssertTrue(successStatus.sessionToken!.count > 0)
            ex.fulfill()
        }) { error in
            XCTFail(error.description)
            ex.fulfill()
        }

        waitForExpectations(timeout: 30.0)
    }

    func testPrimaryAuthFlowFailure() {
        let ex = expectation(description: "Operation should fail!")
        OktaAuthSdk.authenticate(with: URL(string: urlString)!, username: user1!, password: "Wrong password", onStatusChange: { status in
            XCTFail("Unexpected status")
            ex.fulfill()
        }) { error in
            if case .serverRespondedWithError(let errorResponse) = error {
                XCTAssertEqual(errorResponse.errorSummary, "Authentication failed")
                XCTAssertEqual(errorResponse.errorCode, "E0000004")
            }
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 30.0)
    }

    func testFactorChallengeSuccess() {
        var factorRequiredStatus: OktaAuthStatusFactorRequired?
        let ex = expectation(description: "Operation should succeed!")
        OktaAuthSdk.authenticate(with: URL(string: urlString)!, username: user2!, password: password2!, onStatusChange: { status in
            XCTAssertTrue(status.statusType == .MFARequired)
            factorRequiredStatus = status as? OktaAuthStatusFactorRequired
            if let factorRequiredStatus = factorRequiredStatus {
                self.verifyBasicInfoForStatus(status: status)
                XCTAssertTrue(factorRequiredStatus.stateToken.count > 0)
                XCTAssertTrue(factorRequiredStatus.canCancel())
                XCTAssertTrue(factorRequiredStatus.availableFactors.count > 0)
                for factor in factorRequiredStatus.availableFactors {
                    XCTAssertTrue(factor.canSelect())
                    XCTAssertTrue(factor.factor.vendorName!.count > 0)
                }
            } else {
                XCTFail("Unexpected status")
            }
            ex.fulfill()
        }) { error in
            XCTFail(error.description)
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 30.0)

        if let factorRequiredStatus = factorRequiredStatus {
            for factor in factorRequiredStatus.availableFactors {
                runFactorRequiredForFactor(factor)
            }
        }
    }

    func runFactorRequiredForFactor(_ factor: OktaFactor) {
        var factorChallengeStatus: OktaAuthStatusFactorChallenge?
        let ex = expectation(description: "Operation should succeed!")
        factor.select(onStatusChange: { status in
            XCTAssertTrue(status.statusType == .MFAChallenge)
            factorChallengeStatus = status as? OktaAuthStatusFactorChallenge
            if let factorChallengeStatus = factorChallengeStatus {
                self.verifyBasicInfoForStatus(status: status)
                XCTAssertTrue(factorChallengeStatus.factor.type == factor.type)
                XCTAssertTrue(factorChallengeStatus.factor.canVerify())
                XCTAssertTrue(factorChallengeStatus.canReturn())
                XCTAssertTrue(factorChallengeStatus.canCancel())
            } else {
                XCTFail("Unexpected status")
            }
            ex.fulfill()
        }) { error in
            XCTFail(error.description)
            ex.fulfill()
        }

        waitForExpectations(timeout: 30.0)

        if let factorChallengeStatus = factorChallengeStatus {
            runFactorChallengeForFactor(factorChallengeStatus.factor)
        }
    }

    func runFactorChallengeForFactor(_ factor: OktaFactor) {
        let ex = expectation(description: "Operation should succeed!")
        factor.verify(passCode: "1234",
                      answerToSecurityQuestion: "answer",
                      onStatusChange:
            { status in
                if factor.type == .push {
                    let factorChallengeStatus = status as? OktaAuthStatusFactorChallenge
                    if let factorChallengeStatus = factorChallengeStatus {
                        self.verifyBasicInfoForStatus(status: status)
                        XCTAssertTrue(factorChallengeStatus.factor.type == factor.type)
                        XCTAssertTrue(factorChallengeStatus.factor.canVerify())
                        XCTAssertTrue(factorChallengeStatus.canReturn())
                        XCTAssertTrue(factorChallengeStatus.canCancel())
                    } else {
                        XCTFail("Unexpected status")
                    }
                } else {
                    XCTFail("Unexpected status")
                }
                ex.fulfill()
        })
            { error in
                if case .serverRespondedWithError(let errorResponse) = error {
                    XCTAssert(errorResponse.errorSummary!.count > 0)
                    XCTAssertEqual(errorResponse.errorCode, "E0000068")
                }
                ex.fulfill()
        }

        waitForExpectations(timeout: 30.0)
    }

    func verifyBasicInfoForStatus(status: OktaAuthStatus) {
        XCTAssertTrue(status.model.embedded!.user!.id!.count > 0)
        XCTAssertTrue(status.model.embedded!.user!.profile!.firstName!.count > 0)
        XCTAssertTrue(status.model.embedded!.user!.profile!.lastName!.count > 0)
    }
}
