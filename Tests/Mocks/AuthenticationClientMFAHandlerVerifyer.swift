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
import OktaAuthNative

class AuthenticationClientMFAHandlerVerifyer: AuthenticationClientMFAHandler {
    
    func selectFactor(factors: [EmbeddedResponse.Factor], callback: @escaping (_ factor: EmbeddedResponse.Factor) -> Void) {
        
        selectFactorCalled = true
        self.factors = factors
        self.selectFactorCompletion = callback
        
        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }
    
    func pushStateUpdated(_ state: OktaAPISuccessResponse.FactorResult) {
        
        pushStateUpdatedCalled = true
        self.state = state
        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }
    
    func requestTOTP(callback: @escaping (_ code: String) -> Void) {
        
        requestTOTPCalled = true
        self.requestTOTPCodeCompletion = callback
        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }
    
    func requestSMSCode(phoneNumber: String?, callback: @escaping (_ code: String) -> Void) {
        
        requestSMSCodeCalled = true
        self.phoneNumber = phoneNumber
        self.requestSMSCodeCompletion = callback
        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }
    
    func securityQuestion(question: String, callback: @escaping (_ answer: String) -> Void) {
        
        securityQuestionCalled = true
        self.question = question
        self.securityQuestionCompletion = callback
        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }

    var asyncExpectation: XCTestExpectation?
    var factors: [EmbeddedResponse.Factor]?
    var state: OktaAPISuccessResponse.FactorResult?
    var phoneNumber: String?
    var question: String?
    var selectFactorCompletion: ((_ factor: EmbeddedResponse.Factor) -> Void)?
    var requestSMSCodeCompletion: ((_ code: String) -> Void)?
    var requestTOTPCodeCompletion: ((_ code: String) -> Void)?
    var securityQuestionCompletion: ((_ answer: String) -> Void)?
    
    var selectFactorCalled: Bool = false
    var pushStateUpdatedCalled: Bool = false
    var requestTOTPCalled: Bool = false
    var requestSMSCodeCalled: Bool = false
    var securityQuestionCalled: Bool = false
}
