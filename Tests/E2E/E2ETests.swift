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
    
    let username = ProcessInfo.processInfo.environment["USERNAME"] ?? ""
    let password = ProcessInfo.processInfo.environment["PASSWORD"] ?? ""
    let urlString = ProcessInfo.processInfo.environment["DOMAIN_URL"] ?? ""
    let phoneNumber = ProcessInfo.processInfo.environment["PHONE"] ?? ""
    let answer = ProcessInfo.processInfo.environment["ANSWER"] ?? ""

    var primaryAuthUser: (username: String, password: String)?
    var factorRequiredUser: (username: String, password: String)?
    var factorEnrollmentUser: (username: String, password: String)?

    override func setUpWithError() throws {
        try super.setUpWithError()
        
        try XCTSkipIf(username.count == 0 ||
                        password.count == 0 ||
                        urlString.count == 0 ||
                        phoneNumber.count == 0 ||
                        answer.count == 0,
                      file: "Environment settings not configured")

        if let _ = primaryAuthUser,
           let _ = factorRequiredUser {
            return
        }

        let usernames = username.split(separator: ":")
        primaryAuthUser = (String(usernames[0]), password)
        factorRequiredUser = (String(usernames[1]), password)
        factorEnrollmentUser = (String(usernames[2]), password)
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
        var totpFactor: OktaFactorTotp?
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
                if factor.type == .TOTP {
                    totpFactor = factor as? OktaFactorTotp
                    continue
                }
            }
        }

        guard let _ = pushFactor, let _ = questionFactor, let _ = totpFactor else {
            XCTFail("Can't find Okta Verify and Question factors")
            return
        }

        if let totpFactor = totpFactor {
            runFactorRequiredForOktaVerifyFactor(totpFactor)
        }

        if let pushFactor = pushFactor {
            runFactorRequiredForOktaVerifyFactor(pushFactor)
        }

        if let questionFactor = questionFactor {
            runFactorChallengeForQuestionFactor(questionFactor)
        }
    }

    func testPushFactorEnrollmentSuccess() {
        var factorEnrollStatus: OktaAuthStatusFactorEnroll?
        var pushFactor: OktaFactorPush?
        let ex = expectation(description: "Operation should succeed!")
        OktaAuthSdk.authenticate(with: URL(string: urlString)!, username: factorEnrollmentUser!.username, password: factorEnrollmentUser!.password, onStatusChange: { status in
            XCTAssertTrue(status.statusType == .MFAEnroll)
            factorEnrollStatus = status as? OktaAuthStatusFactorEnroll
            if let factorEnrollStatus = factorEnrollStatus {
                self.verifyBasicInfoForStatus(status: status)
                XCTAssertTrue(factorEnrollStatus.stateToken.count > 0)
                XCTAssertTrue(factorEnrollStatus.canCancel())
                XCTAssertTrue(factorEnrollStatus.availableFactors.count > 0)
                for factor in factorEnrollStatus.availableFactors {
                    XCTAssertTrue(factor.canEnroll())
                    XCTAssertTrue(factor.factor.vendorName!.count > 0)
                    if factor.type == .push {
                        pushFactor = factor as? OktaFactorPush
                    }
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

        if let pushFactor = pushFactor {
            runFactorEnrollForPushFactor(pushFactor)
        } else {
            XCTFail("Push factor has not been found")
        }

        cancelTransactionWithStatus(factorEnrollStatus!)
    }

    func testRecoverPasswordSmsSuccess() {
        var recoveryChallengeStatus: OktaAuthStatusRecoveryChallenge?
        let ex = expectation(description: "Operation should succeed!")
        OktaAuthSdk.recoverPassword(with: URL(string: urlString)!, username: factorRequiredUser!.username, factorType: .sms, onStatusChange: { status in
            XCTAssertTrue(status.statusType == .recoveryChallenge)
            recoveryChallengeStatus = status as? OktaAuthStatusRecoveryChallenge
            if let recoveryChallengeStatus = recoveryChallengeStatus {
                XCTAssertTrue(recoveryChallengeStatus.stateToken!.count > 0)
                XCTAssertTrue(recoveryChallengeStatus.canCancel())
                XCTAssertTrue(recoveryChallengeStatus.factorType == .sms)
                XCTAssertTrue(recoveryChallengeStatus.canVerify())
                XCTAssertTrue(recoveryChallengeStatus.canResend())
            } else {
                XCTFail("Unexpected status")
            }
            ex.fulfill()
        }) { error in
            XCTFail(error.description)
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 30.0)
        
        if let recoveryChallengeStatus = recoveryChallengeStatus {
            fetchTransactionWith(recoveryChallengeStatus)
            cancelTransactionWithStatus(recoveryChallengeStatus)
        }
    }

    func testRecoverPasswordEmailSuccess() {
        let ex = expectation(description: "Operation should succeed!")
        OktaAuthSdk.recoverPassword(with: URL(string: urlString)!, username: factorRequiredUser!.username, factorType: .email, onStatusChange: { status in
            XCTAssertTrue(status.statusType == .recoveryChallenge)
            let recoveryChallengeStatus = status as? OktaAuthStatusRecoveryChallenge
            if let recoveryChallengeStatus = recoveryChallengeStatus {
                XCTAssertTrue(recoveryChallengeStatus.factorType == .email)
                XCTAssertTrue(recoveryChallengeStatus.recoveryType == .password)
            } else {
                XCTFail("Unexpected status")
            }
            ex.fulfill()
        }) { error in
            XCTFail(error.description)
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 30.0)
    }

    func testSmsFactorEnrollmentSuccess() {
        var factorEnrollStatus: OktaAuthStatusFactorEnroll?
        var smsFactor: OktaFactorSms?
        let ex = expectation(description: "Operation should succeed!")
        OktaAuthSdk.authenticate(with: URL(string: urlString)!, username: factorEnrollmentUser!.username, password: factorEnrollmentUser!.password, onStatusChange: { status in
            XCTAssertTrue(status.statusType == .MFAEnroll)
            factorEnrollStatus = status as? OktaAuthStatusFactorEnroll
            if let factorEnrollStatus = factorEnrollStatus {
                self.verifyBasicInfoForStatus(status: status)
                XCTAssertTrue(factorEnrollStatus.stateToken.count > 0)
                XCTAssertTrue(factorEnrollStatus.canCancel())
                XCTAssertTrue(factorEnrollStatus.availableFactors.count > 0)
                for factor in factorEnrollStatus.availableFactors {
                    XCTAssertTrue(factor.canEnroll())
                    XCTAssertTrue(factor.factor.vendorName!.count > 0)
                    if factor.type == .sms {
                        smsFactor = factor as? OktaFactorSms
                    }
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
        
        if let smsFactor = smsFactor {
            runFactorEnrollForSmsFactor(smsFactor)
        } else {
            XCTFail("Sms factor has not been found")
        }
        
        cancelTransactionWithStatus(factorEnrollStatus!)
    }

    func testTotpFactorEnrollmentSuccess() {
        var factorEnrollStatus: OktaAuthStatusFactorEnroll?
        var totpFactor: OktaFactorTotp?
        let ex = expectation(description: "Operation should succeed!")
        OktaAuthSdk.authenticate(with: URL(string: urlString)!, username: factorEnrollmentUser!.username, password: factorEnrollmentUser!.password, onStatusChange: { status in
            XCTAssertTrue(status.statusType == .MFAEnroll)
            factorEnrollStatus = status as? OktaAuthStatusFactorEnroll
            if let factorEnrollStatus = factorEnrollStatus {
                self.verifyBasicInfoForStatus(status: status)
                XCTAssertTrue(factorEnrollStatus.stateToken.count > 0)
                XCTAssertTrue(factorEnrollStatus.canCancel())
                XCTAssertTrue(factorEnrollStatus.availableFactors.count > 0)
                for factor in factorEnrollStatus.availableFactors {
                    XCTAssertTrue(factor.canEnroll())
                    XCTAssertTrue(factor.factor.vendorName!.count > 0)
                    if factor.type == .TOTP && factor.factor.vendorName == "OKTA" {
                        totpFactor = factor as? OktaFactorTotp
                    }
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
        
        if let totpFactor = totpFactor {
            runFactorEnrollForTotpFactor(totpFactor)
        } else {
            XCTFail("Totp factor has not been found")
        }
        
        cancelTransactionWithStatus(factorEnrollStatus!)
    }

    func runFactorRequiredForOktaVerifyFactor(_ factor: OktaFactor) {
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
            } else if factorChallengeStatus.factor.type == .TOTP {
                runFactorChallengeWithWrongOTPValuesForFactor(factorChallengeStatus.factor)
            } else {
                XCTFail("Unexpected factor")
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
        factor.select(answerToSecurityQuestion: answer,
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

    func runFactorEnrollForPushFactor(_ factor: OktaFactorPush) {
        let ex = expectation(description: "Operation should succeed!")
        factor.enroll(onStatusChange: { status in
            let factorEnrollActivateStatus = status as? OktaAuthStatusFactorEnrollActivate
            if let factorEnrollActivateStatus = factorEnrollActivateStatus {
                self.verifyBasicInfoForStatus(status: status)
                XCTAssertTrue(factorEnrollActivateStatus.factor.type == factor.type)
                XCTAssertTrue(factorEnrollActivateStatus.factor.canActivate())
                XCTAssertTrue(factorEnrollActivateStatus.canReturn())
                XCTAssertTrue(factorEnrollActivateStatus.canCancel())
            } else {
                XCTFail("Unexpected status")
            }
            ex.fulfill()
        }) { error in
            XCTFail(error.description)
            ex.fulfill()
        }

        waitForExpectations(timeout: 30.0)
    }

    func runFactorEnrollForSmsFactor(_ factor: OktaFactorSms) {
        let ex = expectation(description: "Operation should succeed!")
        factor.enroll(phoneNumber: phoneNumber, onStatusChange: { status in
            let factorEnrollActivateStatus = status as? OktaAuthStatusFactorEnrollActivate
            if let factorEnrollActivateStatus = factorEnrollActivateStatus {
                self.verifyBasicInfoForStatus(status: status)
                XCTAssertTrue(factorEnrollActivateStatus.factor.type == factor.type)
                XCTAssertTrue(factorEnrollActivateStatus.factor.canActivate())
                XCTAssertTrue(factorEnrollActivateStatus.canReturn())
                XCTAssertTrue(factorEnrollActivateStatus.canCancel())
            } else {
                XCTFail("Unexpected status")
            }
            ex.fulfill()
        }) { error in
            XCTFail(error.description)
            ex.fulfill()
        }

        waitForExpectations(timeout: 30.0)
    }

    func runFactorEnrollForTotpFactor(_ factor: OktaFactorTotp) {
        let ex = expectation(description: "Operation should succeed!")
        factor.enroll(onStatusChange: { status in
            let factorEnrollActivateStatus = status as? OktaAuthStatusFactorEnrollActivate
            if let factorEnrollActivateStatus = factorEnrollActivateStatus {
                self.verifyBasicInfoForStatus(status: status)
                XCTAssertTrue(factorEnrollActivateStatus.factor.type == factor.type)
                XCTAssertTrue(factorEnrollActivateStatus.factor.canActivate())
                XCTAssertTrue(factorEnrollActivateStatus.canReturn())
                XCTAssertTrue(factorEnrollActivateStatus.canCancel())
            } else {
                XCTFail("Unexpected status")
            }
            ex.fulfill()
        }) { error in
            XCTFail(error.description)
            ex.fulfill()
        }

        waitForExpectations(timeout: 30.0)
    }

    func cancelTransactionWithStatus(_ status: OktaAuthStatus) {
        let ex = expectation(description: "Operation should succeed!")
        status.cancel(onSuccess: {
            ex.fulfill()
        }) { error in
            XCTFail(error.description)
            ex.fulfill()
        }
        
        waitForExpectations(timeout: 30.0)
    }

    func fetchTransactionWith(_ originalStatus: OktaAuthStatusRecoveryChallenge) {
        let ex = expectation(description: "Operation should succeed!")
        OktaAuthSdk.fetchStatus(with: originalStatus.stateToken!, using: URL(string: urlString)!, onStatusChange: { status in
            let recoveryChallengeStatus = status as? OktaAuthStatusRecoveryChallenge
            if let recoveryChallengeStatus = recoveryChallengeStatus {
                XCTAssertEqual(recoveryChallengeStatus.stateToken, originalStatus.stateToken!)
                XCTAssertTrue(recoveryChallengeStatus.canVerify())
                XCTAssertTrue(recoveryChallengeStatus.canResend())
                XCTAssertTrue(recoveryChallengeStatus.canCancel())
            } else {
                XCTFail("Unexpected status")
            }
            ex.fulfill()
        }) { error in
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
