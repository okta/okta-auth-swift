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

    var primaryAuthUser: (username: String, password: String)?
    var factorRequiredUser: (username: String, password: String)?

    override func setUp() {
        
        if let _ = primaryAuthUser,
           let _ = factorRequiredUser {
            return
        }

        let usernames = username.split(separator: ";")
        let passwords = password.split(separator: ";")
        primaryAuthUser = (String(usernames.first!), String(passwords.first!))
        factorRequiredUser = (String(usernames.last!), String(passwords.last!))
    }

    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
    }

    func testPrimaryAuthFlowSuccess() {
        let ex = expectation(description: "Operation should succeed!")
        OktaAuthSdk.authenticate(with: URL(string: urlString)!, username: primaryAuthUser!.username, password: primaryAuthUser!.password, onStatusChange: { status in
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
        OktaAuthSdk.authenticate(with: URL(string: urlString)!, username: primaryAuthUser!.username, password: "Wrong password", onStatusChange: { status in
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
        OktaAuthSdk.authenticate(with: URL(string: urlString)!, username: factorRequiredUser!.username, password: factorRequiredUser!.password, onStatusChange: { status in
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

        var pushFactor: OktaFactorPush?
        var questionFactor: OktaFactorQuestion?
        if let factorRequiredStatus = factorRequiredStatus {
            for factor in factorRequiredStatus.availableFactors {
                if factor.type == .push {
                    pushFactor = factor as? OktaFactorPush
                    continue
                }
                if factor.type == .question {
                    questionFactor = factor as? OktaFactorQuestion
                    continue
                }
                runFactorRequiredForFactor(factor)
            }
        }

        if let pushFactor = pushFactor {
            runFactorRequiredForFactor(pushFactor)
        }

        if let questionFactor = questionFactor {
            runFactorRequiredForFactor(questionFactor)
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
            if factorChallengeStatus.factor.type == .push {
                if let pushFactor = factorChallengeStatus.factor as? OktaFactorPush {
                    runFactorChallengeForPushFactor(pushFactor)
                } else {
                    XCTFail("Internal SDK error")
                }
            } else if factorChallengeStatus.factor.type == .question {
                if let questionFactor = factorChallengeStatus.factor as? OktaFactorQuestion {
                    runFactorChallengeForQuestionFactor(questionFactor)
                } else {
                    XCTFail("Internal SDK error")
                }
            } else {
                runFactorChallengeWithWrongOTPValuesForFactor(factorChallengeStatus.factor)
            }
        }
    }

    func runFactorChallengeWithWrongOTPValuesForFactor(_ factor: OktaFactor) {
        let ex = expectation(description: "Operation should fail!")
        factor.verify(passCode: "1234",
                      answerToSecurityQuestion: nil,
                      onStatusChange:
            { status in
                XCTFail("Unexpected status")
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

    func runFactorChallengeForPushFactor(_ factor: OktaFactorPush) {
        let ex = expectation(description: "Operation should succeed!")
        factor.verify(onStatusChange:
            { status in
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
                ex.fulfill()
        })
        { error in
            
            XCTFail(error.description)
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 30.0)
    }

    func runFactorChallengeForQuestionFactor(_ factor: OktaFactorQuestion) {
        let ex = expectation(description: "Operation should succeed!")
        factor.verify(answerToSecurityQuestion: "ovechkin",
                      onStatusChange:
        { status in
                let successStatus = status as? OktaAuthStatusSuccess
                if let successStatus = successStatus {
                    self.verifyBasicInfoForStatus(status: status)
                    XCTAssertTrue(successStatus.sessionToken!.count > 0)
                } else {
                    XCTFail("Unexpected status")
                }
                ex.fulfill()
        })
        { error in
            
            XCTFail(error.description)
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
