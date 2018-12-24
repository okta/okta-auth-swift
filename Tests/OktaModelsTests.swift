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

    func testResponse_PrimaryAuth() {
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

        XCTAssertEqual("MFA_REQUIRED", response.status)
        XCTAssertNotNil(response.stateToken)
        XCTAssertNil(response.sessionToken)
        XCTAssertNotNil(response.expirationDate)
        XCTAssertEqual("/myapp/some/deep/link/i/want/to/return/to", response.relayState)
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
        
    }
    
    // MARK: - Utils
    
    private func readResponse(named name: String) -> Data? {
        guard let url = Bundle.init(for: self.classForCoder).url(forResource: name, withExtension: nil) else {
            return nil
        }
        
        return try? Data(contentsOf: url)
    }

}
