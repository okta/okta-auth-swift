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

class AuthenticationClientDelegateVerifyer: AuthenticationClientDelegate {

    func handleSuccess(sessionToken: String) {
        
        handleSuccessCalled = true
        self.sessionToken = sessionToken
        
        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }
    
    func handleError(_ error: OktaError) {
        
        handleErrorCalled = true
        self.error = error
        
        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }
    
    func handleChangePassword(canSkip: Bool, callback: @escaping (_ old: String?, _ new: String?, _ skip: Bool) -> Void) {
        
        handleChangePasswordCalled = true
        
        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }
    
    func transactionCancelled() {
        
        transactionCancelledCalled = true
        
        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }

    func handleRecoveryChallenge(factorType: FactorType?, factorResult: OktaAPISuccessResponse.FactorResult?) {
        
        handleRecoveryChallengeCalled = true;

        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }
    
    func handleAccountLockedOut(callback: @escaping (String, FactorType) -> Void) {
        
        handleAccountLockedOutCalled = true;
        
        if let expectation = asyncExpectation {
            expectation.fulfill()
        }
    }

    var handleSuccessCalled: Bool = false
    var handleErrorCalled: Bool = false
    var handleChangePasswordCalled: Bool = false
    var transactionCancelledCalled: Bool = false
    var handleRecoveryChallengeCalled: Bool = false
    var handleAccountLockedOutCalled: Bool = false
    
    var sessionToken: String?
    var error: OktaError?
    
    var asyncExpectation: XCTestExpectation?
}
