//
//  OktaAuthiOSIntegrationTests.swift
//  OktaAuth iOS Integration Tests
//
//  Created by Anastasiia Iurok on 12/26/18.
//

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
