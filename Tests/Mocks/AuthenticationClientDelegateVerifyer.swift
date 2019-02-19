//
//  AuthenticationClientDelegateVerifyer.swift
//  OktaAuthNative iOS Tests
//
//  Created by Ildar Abdullin on 2/5/19.
//

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
