//
//  OktaModelsTests.swift
//  OktaAuth iOS Tests
//
//  Created by Anastasiia Iurok on 12/24/18.
//

import XCTest

@testable import OktaAuth

class OktaModelsTests: XCTestCase {

    var decoder: JSONDecoder!

    override func setUp() {
        decoder = JSONDecoder()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(formatter)
    }

    override func tearDown() {
        decoder = nil
    }

    func testSuccessResponse_PrimaryAuth() {
        guard let jsonData = readResponse(named: "PrimaryAuthResponse") else {
            XCTFail("Test resource missing.")
            return
        }
        
        let response: OktaAPISuccessResponse
        do {
            response = try decoder.decode(OktaAPISuccessResponse.self, from: jsonData)
        } catch let e {
            XCTFail("JSON parsing failed with error: \(e)")
            return
        }

        XCTAssertEqual(AuthStatus.success, response.status)
        XCTAssertNil(response.stateToken)
        XCTAssertEqual("test_session_token", response.sessionToken)
        XCTAssertNotNil(response.expirationDate)
        XCTAssertNil(response.relayState)
        XCTAssertNil(response.factorResult)

        XCTAssertNotNil(response.embeddedResources)
        
        // User
        XCTAssertEqual("test_user_id", response.embeddedResources?.user?.id)
        XCTAssertNotNil(response.embeddedResources?.user?.passwordChanged)
        XCTAssertEqual("testname.testlastname@okta.com", response.embeddedResources?.user?.profile?.login)
        XCTAssertEqual("TestName", response.embeddedResources?.user?.profile?.firstName)
        XCTAssertEqual("TestLastName", response.embeddedResources?.user?.profile?.lastName)
        XCTAssertEqual("America/Los_Angeles", response.embeddedResources?.user?.profile?.timeZone)
        
        XCTAssertNil(response.embeddedResources?.policy)
        XCTAssertNil(response.embeddedResources?.target)
        XCTAssertNil(response.embeddedResources?.authentication)
        
        XCTAssertNil(response.links)
    }
    
    func testSuccessResponse_PrimaryAuthWithFactors() {
        guard let jsonData = readResponse(named: "PrimaryAuthFactorsResponse") else {
            XCTFail("Test resource missing.")
            return
        }
        
        let response: OktaAPISuccessResponse
        do {
            response = try decoder.decode(OktaAPISuccessResponse.self, from: jsonData)
        } catch let e {
            XCTFail("JSON parsing failed with error: \(e)")
            return
        }

        XCTAssertEqual(AuthStatus.MFARequired, response.status)
        XCTAssertEqual("test_state_token", response.stateToken)
        XCTAssertNil(response.sessionToken)
        XCTAssertNotNil(response.expirationDate)
        XCTAssertNil(response.relayState)
        XCTAssertNil(response.factorResult)

        XCTAssertNotNil(response.embeddedResources)
        
        // User
        XCTAssertEqual("test_user_id", response.embeddedResources?.user?.id)
        XCTAssertNotNil(response.embeddedResources?.user?.passwordChanged)
        XCTAssertEqual("testname.testlastname@okta.com", response.embeddedResources?.user?.profile?.login)
        XCTAssertEqual("TestName", response.embeddedResources?.user?.profile?.firstName)
        XCTAssertEqual("TestLastName", response.embeddedResources?.user?.profile?.lastName)
        XCTAssertEqual("America/Los_Angeles", response.embeddedResources?.user?.profile?.timeZone)
        
        // Policy
        XCTAssertNotNil(response.embeddedResources?.policy)
        if case .rememberDevice(let rememberDevice)? = response.embeddedResources?.policy {
            XCTAssertEqual(false, rememberDevice.allowRememberDevice)
            XCTAssertEqual(0, rememberDevice.rememberDeviceLifetimeInMinutes)
            XCTAssertEqual(false, rememberDevice.rememberDeviceByDefault)
        } else {
            XCTFail("Failed to parse policy.")
        }
        
        XCTAssertNil(response.embeddedResources?.target)
        XCTAssertNil(response.embeddedResources?.authentication)
        
        XCTAssertNotNil(response.links)
        XCTAssertNotNil(response.links?.cancel)
        XCTAssertEqual(URL(string: "https://test_link/cancel")!, response.links?.cancel?.href)
        XCTAssertNil(response.links?.next)
        XCTAssertNil(response.links?.prev)
        XCTAssertNil(response.links?.resend)
        XCTAssertNil(response.links?.skip)
    }
    
    func testErrorResponse_AuthenticationFailed() {
        guard let jsonData = readResponse(named: "AuthenticationFailedError") else {
            XCTFail("Test resource missing.")
            return
        }
        
        let response: OktaAPIErrorResponse
        do {
            response = try decoder.decode(OktaAPIErrorResponse.self, from: jsonData)
        } catch let e {
            XCTFail("JSON parsing failed with error: \(e)")
            return
        }
        
        XCTAssertEqual("E0000004", response.errorCode)
        XCTAssertEqual("Authentication failed", response.errorSummary)
        XCTAssertEqual("E0000004", response.errorLink)
        XCTAssertEqual("oaep_fwxUiwQjSHsMRpsv4pMg", response.errorId)
        XCTAssertEqual(0, response.errorCauses?.count ?? 0)
    }

    func testErrorResponse_OperationNotAllowed() {
        guard let jsonData = readResponse(named: "OperationNotAllowedError") else {
            XCTFail("Test resource missing.")
            return
        }
        
        let response: OktaAPIErrorResponse
        do {
            response = try decoder.decode(OktaAPIErrorResponse.self, from: jsonData)
        } catch let e {
            XCTFail("JSON parsing failed with error: \(e)")
            return
        }
        
        XCTAssertEqual("E0000079", response.errorCode)
        XCTAssertEqual("This operation is not allowed in the current authentication state.", response.errorSummary)
        XCTAssertEqual("E0000079", response.errorLink)
        XCTAssertEqual("oae601OOxRbRImSztKcjduZ2w", response.errorId)
        XCTAssertNotNil(response.errorCauses)
        XCTAssertEqual("This operation is not allowed in the current authentication state.", response.errorCauses?.first?.errorSummary)
    }
    
    // MARK: - Utils
    
    private func readResponse(named name: String) -> Data? {
        guard let url = Bundle.init(for: self.classForCoder).url(forResource: name, withExtension: nil) else {
            return nil
        }
        
        return try? Data(contentsOf: url)
    }

}
