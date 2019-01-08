//
//  OktaAPITests.swift
//  OktaAuth iOS Tests
//
//  Created by Alex Lebedev on 12/27/18.
//

import XCTest
@testable import OktaAuth

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
        
        api.primaryAuthentication(username: username, password: password)
        
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
        
        api.changePassword(stateToken: token, oldPassword: oldpass, newPassword: newpass)
        
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
        
        api.getTransactionState(stateToken: token)
        
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
        
        api.cancelTransaction(stateToken: token)
        
        wait(for: [exp], timeout: 60.0)
    }
}
