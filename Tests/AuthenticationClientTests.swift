//
//  AuthenticationClientTests.swift
//  OktaAuthNative iOS Tests
//
//  Created by Ildar Abdullin on 2/4/19.
//

import XCTest
@testable import OktaAuthNative

class AuthenticationClientTests: XCTestCase {

    var client: AuthenticationClient!
    var delegateVerifyer: AuthenticationClientDelegateVerifyer!
    var mfaHandlerVerifyer: AuthenticationClientMFAHandlerVerifyer!
    
    override func setUp() {
        delegateVerifyer = AuthenticationClientDelegateVerifyer()
        delegateVerifyer.asyncExpectation = XCTestExpectation()
        mfaHandlerVerifyer = AuthenticationClientMFAHandlerVerifyer()
        mfaHandlerVerifyer.asyncExpectation = XCTestExpectation()
        client = AuthenticationClient(oktaDomain: URL(string: "http://example.com")!, delegate: delegateVerifyer, mfaHandler: mfaHandlerVerifyer)
    }

    override func tearDown() {
        delegateVerifyer = nil
        client = nil
    }
    
    func testAuthenticateBasicSuccessFlow() {

        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.authenticate(username: "username", password: "password")

        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testChangePasswordBasicSuccessFlow() {
        
        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.stateToken = "state_token"
        client.status = .passwordExpired
        client.changePassword(oldPassword: "old_password", newPassword: "new_password")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        if delegateVerifyer.handleSuccessCalled {
            XCTAssertTrue(delegateVerifyer.handleSuccessCalled, "handleSuccess delegate method has been successfully called")
            XCTAssertEqual("test_session_token", delegateVerifyer.sessionToken)
            XCTAssertEqual(.success, client.status)
            XCTAssertNil(client.stateToken)
            XCTAssertEqual("test_session_token", client.sessionToken)
            XCTAssertNil(client.factorResult)
            XCTAssertNil(client.links)
            XCTAssertNil(client.recoveryToken)
            XCTAssertNotNil(client.embedded)
        } else {
            XCTFail("Expected delegate method handleSuccess to be called")
        }
        
        client.stateToken = "state_token"
        client.status = .passwordWarning
        client.changePassword(oldPassword: "old_password", newPassword: "new_password")
        
        delegateVerifyer.asyncExpectation = XCTestExpectation()
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        if delegateVerifyer.handleSuccessCalled {
            XCTAssertTrue(delegateVerifyer.handleSuccessCalled, "handleSuccess delegate method has been successfully called")
            XCTAssertEqual("test_session_token", delegateVerifyer.sessionToken)
            XCTAssertEqual(.success, client.status)
            XCTAssertNil(client.stateToken)
            XCTAssertEqual("test_session_token", client.sessionToken)
            XCTAssertNil(client.factorResult)
            XCTAssertNil(client.links)
            XCTAssertNil(client.recoveryToken)
            XCTAssertNotNil(client.embedded)
        } else {
            XCTFail("Expected delegate method handleSuccess to be called")
        }
    }
    
    func testCancellationBasicSuccessFlow() {
        
        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "TransactionCancellationSuccess")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.stateToken = "state_token"
        client.cancel()
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        if delegateVerifyer.transactionCancelledCalled {
            XCTAssertTrue(delegateVerifyer.transactionCancelledCalled, "transactionCancelled delegate method has been successfully called")
            XCTAssertEqual(.unauthenticated, client.status)
            XCTAssertNil(client.stateToken)
            XCTAssertNil(client.sessionToken)
            XCTAssertNil(client.factorResult)
            XCTAssertNil(client.links)
            XCTAssertNil(client.recoveryToken)
            XCTAssertNil(client.embedded)
        } else {
            XCTFail("Expected delegate method transactionCancelled to be called")
        }
    }
    
    func testFetchTransactionStatusSuccessFlow() {
        
        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.stateToken = "state_token"
        client.fetchTransactionStatus()
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testVerifyFactorSuccessFlow() {
        
        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.stateToken = "state_token"
        let factor = EmbeddedResponse.Factor(id: "factor_id", factorType: nil, provider: nil, vendorName: nil, profile: nil)
        client.verify(factor: factor)
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testPerformLinkSuccessFlow() {
        
        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.stateToken = "state_token"
        let link = LinksResponse.Link(href: URL(string: "www.okta.com")!, hints: ["allow" : ["POST"]])
        client.perform(link: link)
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }

    func testCheckAPIResultErrorBasicAuthFlow() {
        
        let oktaApiMock = OktaAPIMock(successCase: false, resourceName: "AuthenticationFailedError")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }

        client.stateToken = "state_token"
        client.factorResult = .waiting
        client.links = LinksResponse(next: nil, prev: nil, cancel: nil, skip: nil, resend: nil)
        client.embedded = EmbeddedResponse(user: nil, target: nil, policy: nil, authentication: nil, factor: nil, factors: nil)
        client.recoveryToken = "recovery_token"
        client.sessionToken = "session_token"
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        if delegateVerifyer.handleErrorCalled {
            // Check that data has not been reset by Auth engine
            XCTAssertTrue(delegateVerifyer.handleErrorCalled, "handleError delegate method has been successfully called")
            XCTAssertEqual("session_token", client.sessionToken)
            XCTAssertEqual(.unauthenticated, client.status)
            XCTAssertNotNil(client.stateToken)
            XCTAssertEqual("state_token", client.stateToken)
            XCTAssertEqual(.waiting, client.factorResult)
            XCTAssertNotNil(client.links)
            XCTAssertEqual("recovery_token", client.recoveryToken)
            XCTAssertNotNil(client.embedded)
        } else {
            XCTFail("Expected delegate method handleError to be called")
        }
    }
    
    func testAuthenticateWithPushFactorSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthFactorsResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }

        client.authenticate(username: "username", password: "password")

        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(mfaHandlerVerifyer.factors)
        XCTAssertTrue(mfaHandlerVerifyer.selectFactorCalled, "Expected delegate method selectFactorCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.selectFactorCompletion)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        mfaHandlerVerifyer.selectFactorCompletion!(mfaHandlerVerifyer.factors![0])
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testAuthenticateWithTOTPFactorSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthFactorsResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(mfaHandlerVerifyer.factors)
        XCTAssertTrue(mfaHandlerVerifyer.selectFactorCalled, "Expected delegate method selectFactorCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.selectFactorCompletion)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        mfaHandlerVerifyer.selectFactorCompletion!(mfaHandlerVerifyer.factors![1])
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    private func checkSuccessStateResults() {

        if delegateVerifyer.handleSuccessCalled {
            XCTAssertTrue(delegateVerifyer.handleSuccessCalled, "handleSuccess delegate method has been successfully called")
            XCTAssertEqual("test_session_token", delegateVerifyer.sessionToken)
            XCTAssertEqual(.success, client.status)
            XCTAssertNil(client.stateToken)
            XCTAssertEqual("test_session_token", client.sessionToken)
            XCTAssertNil(client.factorResult)
            XCTAssertNil(client.links)
            XCTAssertNil(client.recoveryToken)
            XCTAssertNotNil(client.embedded)
        } else {
            XCTFail("Expected delegate method transactionCancelled to be called")
        }
    }
}
