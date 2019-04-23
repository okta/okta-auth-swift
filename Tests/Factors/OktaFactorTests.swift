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

class OktaFactorTests: XCTestCase {

    func testCreation_Sms() {
        guard let testResponse = TestResponse.MFA_ENROLL_NotEnroller.parse(),
              let stateToken = testResponse.stateToken,
              let factorsResponse = testResponse.embedded!.factors,
              let factorResponse = factorsResponse.first(where: { $0.factorType == .sms }) else {
            XCTFail("Failed to read test data!")
            return
        }
        
        guard let factor = OktaFactor.createFactorWith(factorResponse,
                                                       stateToken: stateToken,
                                                       verifyLink: nil,
                                                       activationLink: nil) as? OktaFactorSms else {
            XCTFail("OktaFactorSms should be created!")
            return
        }
        
        XCTAssertEqual("REQUIRED", factor.enrollment)
        XCTAssertEqual("NOT_SETUP", factor.status)
        XCTAssertEqual(FactorProvider.okta, factor.provider)
        XCTAssertNil(factor.profile)
        XCTAssertNotNil(factor.links)
        XCTAssertEqual(FactorType.sms, factor.type)
        XCTAssertFalse(factor.canVerify())
        XCTAssertFalse(factor.canSelect())
        XCTAssertFalse(factor.canActivate())
        XCTAssertTrue(factor.canEnroll())
    }
    
    func testCreation_question() {
        guard let testResponse = TestResponse.MFA_ENROLL_NotEnroller.parse(),
              let stateToken = testResponse.stateToken,
              let factorsResponse = testResponse.embedded!.factors,
              let factorResponse = factorsResponse.first(where: { $0.factorType == .question }) else {
            XCTFail("Failed to read test data!")
            return
        }
        
        guard let factor = OktaFactor.createFactorWith(factorResponse,
                                                       stateToken: stateToken,
                                                       verifyLink: nil,
                                                       activationLink: nil) as? OktaFactorQuestion else {
            XCTFail("OktaFactorSms should be created!")
            return
        }
        
        XCTAssertEqual("REQUIRED", factor.enrollment)
        XCTAssertEqual("NOT_SETUP", factor.status)
        XCTAssertEqual(FactorProvider.okta, factor.provider)
        XCTAssertNil(factor.profile)
        XCTAssertNotNil(factor.links)
        XCTAssertEqual(FactorType.question, factor.type)
        XCTAssertFalse(factor.canVerify())
        XCTAssertFalse(factor.canSelect())
        XCTAssertFalse(factor.canActivate())
        XCTAssertTrue(factor.canEnroll())
    }
    
    func testCreation_Push() {
        guard let testResponse = TestResponse.MFA_ENROLL_NotEnroller.parse(),
              let stateToken = testResponse.stateToken,
              let factorsResponse = testResponse.embedded!.factors,
              let factorResponse = factorsResponse.first(where: { $0.factorType == .push }) else {
            XCTFail("Failed to read test data!")
            return
        }
        
        guard let factor = OktaFactor.createFactorWith(factorResponse,
                                                       stateToken: stateToken,
                                                       verifyLink: nil,
                                                       activationLink: nil) as? OktaFactorPush else {
            XCTFail("OktaFactorSms should be created!")
            return
        }
        
        XCTAssertEqual("REQUIRED", factor.enrollment)
        XCTAssertEqual("NOT_SETUP", factor.status)
        XCTAssertEqual(FactorProvider.okta, factor.provider)
        XCTAssertNil(factor.profile)
        XCTAssertNotNil(factor.links)
        XCTAssertEqual(FactorType.push, factor.type)
        XCTAssertFalse(factor.canVerify())
        XCTAssertFalse(factor.canSelect())
        XCTAssertFalse(factor.canActivate())
        XCTAssertTrue(factor.canEnroll())
    }
    
    func testCreation_Totp() {
        guard let testResponse = TestResponse.MFA_ENROLL_NotEnroller.parse(),
              let stateToken = testResponse.stateToken,
              let factorsResponse = testResponse.embedded!.factors,
              let factorResponse = factorsResponse.first(where: { $0.factorType == .TOTP }) else {
            XCTFail("Failed to read test data!")
            return
        }
        
        guard let factor = OktaFactor.createFactorWith(factorResponse,
                                                       stateToken: stateToken,
                                                       verifyLink: nil,
                                                       activationLink: nil) as? OktaFactorTotp else {
            XCTFail("OktaFactorSms should be created!")
            return
        }
        
        XCTAssertEqual("REQUIRED", factor.enrollment)
        XCTAssertEqual("NOT_SETUP", factor.status)
        XCTAssertEqual(FactorProvider.okta, factor.provider)
        XCTAssertNil(factor.profile)
        XCTAssertNotNil(factor.links)
        XCTAssertEqual(FactorType.TOTP, factor.type)
        XCTAssertFalse(factor.canVerify())
        XCTAssertFalse(factor.canSelect())
        XCTAssertFalse(factor.canActivate())
        XCTAssertTrue(factor.canEnroll())
    }
}
