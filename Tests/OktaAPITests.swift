//
//  OktaAPITests.swift
//  OktaAuth iOS Tests
//
//  Created by Alex Lebedev on 12/27/18.
//

import XCTest
@testable import OktaAuthNative

class OktaAPITests : XCTestCase {
    
    let url = URL(string: "https://B6D242A0-4FC6-41A4-A68B-F722B84BB346.com")!
    var api: OktaAPI!
    
    override func setUp() {
        api = OktaAPI(oktaDomain: url)
    }
    
    override func tearDown() {
        api = nil
    }
    
    func testPrimaryAuthentication() {
        let username = "username"
        let password = "password"
        
        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, self.url)
            XCTAssertEqual(req.path, "/api/v1/authn")
            XCTAssertEqual(req.bodyParams?["username"] as? String, username)
            XCTAssertEqual(req.bodyParams?["password"] as? String, password)
            exp.fulfill()
        }
        
        let _ = api.primaryAuthentication(username: username, password: password)
        
        wait(for: [exp], timeout: 60.0)
    }
    
    func testPrimaryAuthenticationWithDeviceFingerprint() {
        let username = "username"
        let password = "password"
        let deviceFingerprint = "fingerprint"
        
        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, self.url)
            XCTAssertEqual(req.path, "/api/v1/authn")
            XCTAssertEqual(req.bodyParams?["username"] as? String, username)
            XCTAssertEqual(req.bodyParams?["password"] as? String, password)
            XCTAssertEqual(req.additionalHeaders?["X-Device-Fingerprint"] , deviceFingerprint)
            exp.fulfill()
        }
        
        let _ = api.primaryAuthentication(username: username, password: password, deviceFingerprint: deviceFingerprint)
        
        wait(for: [exp], timeout: 60.0)
    }
    
    func testChangePassword() {
        let token = "token"
        let oldpass = "oldpass"
        let newpass = "newpass"
        
        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, self.url)
            XCTAssertEqual(req.path, "/api/v1/authn/credentials/change_password")
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, token)
            XCTAssertEqual(req.bodyParams?["oldPassword"] as? String, oldpass)
            XCTAssertEqual(req.bodyParams?["newPassword"] as? String, newpass)
            exp.fulfill()
        }
        
        let _ = api.changePassword(stateToken: token, oldPassword: oldpass, newPassword: newpass)
        
        wait(for: [exp], timeout: 60.0)
    }
    
    func testUnlockAccount() {
        let username = "test_username"
        let factorType = FactorType.email
        
        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, self.url)
            XCTAssertEqual(req.path, "/api/v1/authn/recovery/unlock")
            XCTAssertEqual(req.bodyParams?["username"] as? String, username)
            XCTAssertEqual(req.bodyParams?["factorType"] as? String, factorType.rawValue)
            exp.fulfill()
        }
        
        api.unlockAccount(username: username, factor: factorType)
        
        wait(for: [exp], timeout: 60.0)
    }
    
    func testGetTransactionState() {
        let token = "token"
        
        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, self.url)
            XCTAssertEqual(req.path, "/api/v1/authn")
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, token)
            exp.fulfill()
        }
        
        let _ = api.getTransactionState(stateToken: token)
        
        wait(for: [exp], timeout: 60.0)
    }
    
    func testEnrollMFAFactor() {
        let token = "token"
        let factorType = FactorType.sms
        let factorProvider = FactorProvider.okta
        let phoneNumber = "12345678"
        let profile = FactorProfile.sms(FactorProfile.SMS(phoneNumber: phoneNumber))
        
        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, self.url)
            XCTAssertEqual(req.path, "/api/v1/authn/factors")
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, token)
            XCTAssertEqual(req.bodyParams?["factorType"] as? String, factorType.rawValue)
            XCTAssertEqual(req.bodyParams?["provider"] as? String, factorProvider.rawValue)
            XCTAssertEqual(req.bodyParams?["profile"] as? Dictionary, ["phoneNumber" : phoneNumber])
            exp.fulfill()
        }
        
        let _ = api.enrollMFAFactor(stateToken: token, factor: factorType, provider: factorProvider, profile: profile)
        
        wait(for: [exp], timeout: 60.0)
    }
    
    func testActivateMFAFactor() {
        let token = "token"
        let factorId = "factorId"
        let code = "code"
        let url = URL(string: "http://test/url")!
        
        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, url)
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, token)
            XCTAssertEqual(req.bodyParams?["factorId"] as? String, factorId)
            XCTAssertEqual(req.bodyParams?["passCode"] as? String, code)
            exp.fulfill()
        }
        
        let _ = api.activateMFAFactor(url: url, stateToken: token, factorId: factorId, code: code)
        
        wait(for: [exp], timeout: 60.0)
    }
    
    func testCancelTransaction() {
        let token = "token"
        
        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, self.url)
            XCTAssertEqual(req.path, "/api/v1/authn/cancel")
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, token)
            exp.fulfill()
        }
        
        let _ = api.cancelTransaction(stateToken: token)
        
        wait(for: [exp], timeout: 60.0)
    }
    
    func testPerformLink() {
        let link = LinksResponse.Link(href: url, hints: [:])
        let token = "token"
        
        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, self.url)
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, token)
            exp.fulfill()
        }
        
        let _ = api.perform(link: link, stateToken: token)
        
        wait(for: [exp], timeout: 60.0)
    }
}
