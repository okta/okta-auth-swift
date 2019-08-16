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

@testable import OktaAuthNative

class OktaModelsTests: XCTestCase {

    var decoder: JSONDecoder!
    var encoder: JSONEncoder!

    override func setUp() {
        decoder = JSONDecoder()
        encoder = JSONEncoder()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"

        decoder.dateDecodingStrategy = .formatted(formatter)
        encoder.dateEncodingStrategy = .formatted(formatter)
    }

    override func tearDown() {
        decoder = nil
    }
    
    // MARK: - OktaAPISuccessResponse

    func testOktaAPISuccessResponse_SUCCESS() {
        guard let jsonData = TestResponse.SUCCESS.data() else {
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

        XCTAssertNotNil(response.embedded)
        
        // User
        XCTAssertEqual("test_id", response.embedded?.user?.id)
        XCTAssertNotNil(response.embedded?.user?.passwordChanged)
        XCTAssertEqual("test_user", response.embedded?.user?.profile?.login)
        XCTAssertEqual("test_first_name", response.embedded?.user?.profile?.firstName)
        XCTAssertEqual("test_last_name", response.embedded?.user?.profile?.lastName)
        XCTAssertEqual("America/Los_Angeles", response.embedded?.user?.profile?.timeZone)
        
        XCTAssertNil(response.embedded?.policy)
        XCTAssertNil(response.embedded?.target)
        XCTAssertNil(response.embedded?.authentication)
        
        XCTAssertNil(response.links)
    }
    
    func testOktaAPISuccessResponse_MFA_REQUIRED() {
        guard let jsonData = TestResponse.MFA_REQUIRED.data() else {
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

        XCTAssertNotNil(response.embedded)
        
        XCTAssertNil(response.embedded?.target)
        XCTAssertNil(response.embedded?.authentication)
        
        // User
        XCTAssertEqual("test_user_id", response.embedded?.user?.id)
        XCTAssertNotNil(response.embedded?.user?.passwordChanged)
        XCTAssertEqual("test_user", response.embedded?.user?.profile?.login)
        XCTAssertEqual("test_first_name", response.embedded?.user?.profile?.firstName)
        XCTAssertEqual("test_last_name", response.embedded?.user?.profile?.lastName)
        XCTAssertEqual("America/Los_Angeles", response.embedded?.user?.profile?.timeZone)
        
        // Policy
        XCTAssertNotNil(response.embedded?.policy)
        if case .rememberDevice(let rememberDevice)? = response.embedded?.policy {
            XCTAssertEqual(false, rememberDevice.allowRememberDevice)
            XCTAssertEqual(0, rememberDevice.rememberDeviceLifetimeInMinutes)
            XCTAssertEqual(false, rememberDevice.rememberDeviceByDefault)
        } else {
            XCTFail("Failed to parse policy.")
        }
        
        // Factors
        XCTAssertNil(response.embedded?.factor)
        
        let factors = response.embedded?.factors
        XCTAssertNotNil(factors)
        
        XCTAssertEqual(6, factors?.count)
        
        let smsFactor = factors?.first(where: { $0.factorType == .sms })
        XCTAssertNotNil(smsFactor)
        XCTAssertEqual("smskdhbk0ajTQ7ZyD0h7", smsFactor?.id)
        XCTAssertEqual(FactorProvider.okta, smsFactor?.provider)
        XCTAssertEqual("OKTA", smsFactor?.vendorName)
        XCTAssertEqual("+555 XX XXX 5555", smsFactor?.profile?.phoneNumber)
        XCTAssertEqual("https://test.domain.com/api/v1/authn/factors/smskdhbk0ajTQ7ZyD0h7/verify", smsFactor?.links?.verify?.href.absoluteString)
        
        let callFactor = factors?.first(where: { $0.factorType == .call })
        XCTAssertNotNil(callFactor)
        XCTAssertEqual("clf193zUBEROPBNZKPPE", callFactor?.id)
        XCTAssertEqual(FactorProvider.okta, callFactor?.provider)
        XCTAssertEqual("+1 XXX-XXX-1337", callFactor?.profile?.phoneNumber)
        XCTAssertEqual("https://test.domain.com/api/v1/authn/factors/clf193zUBEROPBNZKPPE/verify", callFactor?.links?.verify?.href.absoluteString)
        
        let pushFactor = factors?.first(where: { $0.factorType == .push })
        XCTAssertNotNil(pushFactor)
        XCTAssertEqual("opfkdh40kws5XarDb0h7", pushFactor?.id)
        XCTAssertEqual(FactorProvider.okta, pushFactor?.provider)
        XCTAssertEqual("OKTA", pushFactor?.vendorName)
        XCTAssertEqual("test_user", pushFactor?.profile?.credentialId)
        XCTAssertEqual("https://test.domain.com/api/v1/authn/factors/opfkdh40kws5XarDb0h7/verify", pushFactor?.links?.verify?.href.absoluteString)
        
        let totpFactor = factors?.first(where: { $0.factorType == .TOTP })
        XCTAssertNotNil(totpFactor)
        XCTAssertEqual("ostkdh5wmlQpOvaoa0h7", totpFactor?.id)
        XCTAssertEqual(FactorProvider.okta, totpFactor?.provider)
        XCTAssertEqual("OKTA", totpFactor?.vendorName)
        XCTAssertEqual("test_id", totpFactor?.profile?.credentialId)
        XCTAssertEqual("https://test.domain.com/api/v1/authn/factors/ostkdh5wmlQpOvaoa0h7/verify", totpFactor?.links?.verify?.href.absoluteString)
        
        let questionFactor = factors?.first(where: { $0.factorType == .question })
        XCTAssertNotNil(questionFactor)
        XCTAssertEqual("ufskdh8bvdzPcnFQ20h7", questionFactor?.id)
        XCTAssertEqual(FactorProvider.okta, questionFactor?.provider)
        XCTAssertEqual("OKTA", questionFactor?.vendorName)
        XCTAssertEqual("favorite_security_question", questionFactor?.profile?.question)
        XCTAssertEqual("What is your favorite security question?", questionFactor?.profile?.questionText)
        XCTAssertEqual("https://test.domain.com/api/v1/authn/factors/ufskdh8bvdzPcnFQ20h7/verify", questionFactor?.links?.verify?.href.absoluteString)
        
        let tokenFactor = factors?.first(where: { $0.factorType == .token })
        XCTAssertNotNil(tokenFactor)
        XCTAssertEqual("rsalhpMQVYKHZKXZJQEW", tokenFactor?.id)
        XCTAssertEqual(FactorProvider.rsa, tokenFactor?.provider)
        XCTAssertEqual("dade.murphy@example.com", tokenFactor?.profile?.credentialId)
        XCTAssertEqual("https://test.domain.com/api/v1/authn/factors/rsalhpMQVYKHZKXZJQEW/verify", tokenFactor?.links?.verify?.href.absoluteString)
        
        // Links
        
        XCTAssertNotNil(response.links)
        XCTAssertNotNil(response.links?.cancel)
        XCTAssertEqual(URL(string: "https://test.domain.com/api/v1/authn/cancel")!, response.links?.cancel?.href)
        XCTAssertNil(response.links?.next)
        XCTAssertNil(response.links?.prev)
        XCTAssertNil(response.links?.resend)
        XCTAssertNil(response.links?.skip)
    }

    func testSuccessResponse_UnknownStatus() {
        guard let jsonData = TestResponse.Unknown_State_And_FactorResult.data() else {
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
        
        XCTAssertEqual(AuthStatus.unknown("SOME_STATUS"), response.status)
        XCTAssertEqual(OktaAPISuccessResponse.FactorResult.unknown("SOME_FACTOR_RESULT"), response.factorResult)
    }
    
    // MARK: - OktaAPIErrorResponse
    
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
    
    // MARK: - OktaAPISuccessResponse.FactorResult
    
    func testFactorResult() {
        let results: [OktaAPISuccessResponse.FactorResult] = [
            .success,
            .active,
            .pending,
            .waiting,
            .cancelled,
            .timeout,
            .timeWindowExceeded,
            .passcodeReplayed,
            .error,
            .rejected,
            .unknown("test")
        ]
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for result in results {
            do {
                let encodedData = try encoder.encode([result])
                let decodedResult = (try decoder.decode([OktaAPISuccessResponse.FactorResult].self, from: encodedData)).first
                
                XCTAssertEqual(result, decodedResult)
            } catch {
                XCTFail(error.localizedDescription)
                continue
            }
        }
    }
    
    // MARK: - OktaAPISuccessResponse.RecoveryType
    
    func testRecoveryType() {
        let recoveryTypes: [OktaAPISuccessResponse.RecoveryType] = [
            .password,
            .unlock,
            .unknown("test")
        ]
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for type in recoveryTypes {
            do {
                let encodedData = try encoder.encode([type])
                let decodedType = (try decoder.decode([OktaAPISuccessResponse.RecoveryType].self, from: encodedData)).first
                
                XCTAssertEqual(type, decodedType)
            } catch {
                XCTFail(error.localizedDescription)
                continue
            }
        }
    }
    
    // MARK: - EmbeddedResponse.AuthenticationObject.AuthProtocol
    
    func testAuthProtocol() {
        let authProtocols: [EmbeddedResponse.AuthenticationObject.AuthProtocol] = [
            .saml_2_0,
            .saml_1_1,
            .ws_fed,
            .unknown("test")
        ]
        
        let encoder = JSONEncoder()
        let decoder = JSONDecoder()
        
        for authProtocol in authProtocols {
            do {
                let encodedData = try encoder.encode([authProtocol])
                let decodedProtocol = (try decoder.decode([EmbeddedResponse.AuthenticationObject.AuthProtocol].self, from: encodedData)).first
                
                XCTAssertEqual(authProtocol, decodedProtocol)
            } catch {
                XCTFail(error.localizedDescription)
                continue
            }
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
