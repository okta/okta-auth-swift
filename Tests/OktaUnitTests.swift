//
//  OktaUnitTests.swift
//  OktaAuthNative iOS Tests
//
//  Created by Ildar Abdullin on 2/4/19.
//

import XCTest
@testable import OktaAuthNative

class OktaUnitTests: XCTestCase {

    var client: AuthenticationClient!
    var delegateVerifyer: AuthenticationClientDelegateVerifyer!
    
    override func setUp() {
        delegateVerifyer = AuthenticationClientDelegateVerifyer()
        delegateVerifyer.asyncExpectation = XCTestExpectation()
        client = AuthenticationClient(oktaDomain: URL(string: "http://example.com")!, delegate: delegateVerifyer)
    }

    override func tearDown() {
        delegateVerifyer = nil
        client = nil
    }
    
    func testAuthenticate() {

        let oktaApiMock = OktaApiMock(successCase: true, json: nil, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.authenticate(username: "username", password: "password")

        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        if delegateVerifyer.handleSuccessCalled {
            XCTAssertTrue(delegateVerifyer.handleSuccessCalled, "handleError delegate method has been successfully called")
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

    func testCheckAPIResultError() {
        
        let oktaApiMock = OktaApiMock(successCase: false, json: nil, resourceName: "AuthenticationFailedError")
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
}
