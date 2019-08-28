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

class OktaAPITests: XCTestCase {

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
            XCTAssertEqual(req.additionalHeaders?["X-Device-Fingerprint"], deviceFingerprint)
            exp.fulfill()
        }

        api.primaryAuthentication(username: username, password: password, deviceFingerprint: deviceFingerprint)

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

    func testChangePasswordWithLink() {
        let link = LinksResponse.Link(name: "test", href: URL(string: "http://test")!, hints: [:])
        let token = "token"
        let oldpass = "oldpass"
        let newpass = "newpass"

        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, link.href)
            XCTAssertNil(req.path)
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, token)
            XCTAssertEqual(req.bodyParams?["oldPassword"] as? String, oldpass)
            XCTAssertEqual(req.bodyParams?["newPassword"] as? String, newpass)
            exp.fulfill()
        }

        api.changePassword(link: link, stateToken: token, oldPassword: oldpass, newPassword: newpass)

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

    func testUnlockAccount() {
        let username = "username"
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

    func testRecoverPassword() {
        let username = "username"
        let factorType = FactorType.email

        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, self.url)
            XCTAssertEqual(req.path, "/api/v1/authn/recovery/password")
            XCTAssertEqual(req.bodyParams?["username"] as? String, username)
            XCTAssertEqual(req.bodyParams?["factorType"] as? String, factorType.rawValue)
            exp.fulfill()
        }

        api.recoverPassword(username: username, factor: factorType)

        wait(for: [exp], timeout: 60.0)
    }

    func testRecoverWith() {
        let answer = "answer"
        let stateToken = "stateToken"
        let recoveryToken = "recoveryToken"
        let link = LinksResponse.Link(name: "test", href: URL(string: "http://test")!, hints: [:])

        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, link.href)
            XCTAssertNil(req.path)
            XCTAssertEqual(req.bodyParams?["answer"] as? String, answer)
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, stateToken)
            XCTAssertEqual(req.bodyParams?["recoveryToken"] as? String, recoveryToken)
            exp.fulfill()
        }

        api.recoverWith(answer: answer, stateToken: stateToken, recoveryToken: recoveryToken, link: link)

        wait(for: [exp], timeout: 60.0)
    }

    func testResetPassword() {
        let newPassword = "newPassword"
        let stateToken = "stateToken"
        let link = LinksResponse.Link(name: "test", href: URL(string: "http://test")!, hints: [:])

        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, link.href)
            XCTAssertNil(req.path)
            XCTAssertEqual(req.bodyParams?["newPassword"] as? String, newPassword)
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, stateToken)
            exp.fulfill()
        }

        api.resetPassword(newPassword: newPassword, stateToken: stateToken, link: link)

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

    func testCancelTransactionWithLink() {
        let stateToken = "stateToken"
        let link = LinksResponse.Link(name: "test", href: URL(string: "http://test")!, hints: [:])

        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, link.href)
            XCTAssertNil(req.path)
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, stateToken)
            exp.fulfill()
        }

        api.cancelTransaction(with: link, stateToken: stateToken)

        wait(for: [exp], timeout: 60.0)
    }

    func testPerformLink() {
        let link = LinksResponse.Link(name: nil, href: url, hints: [:])
        let token = "token"

        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, self.url)
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, token)
            exp.fulfill()
        }

        api.perform(link: link, stateToken: token)

        wait(for: [exp], timeout: 60.0)
    }

    func testVerifyFactor() {
        let factorId = "id"
        let token = "token"
        let answer = "answer"
        let passCode = "passCode"
        let rememberDevice = true
        let autoPush = false

        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.urlParams?["rememberDevice"], "true")
            XCTAssertEqual(req.urlParams?["autoPush"], "false")
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, token)
            XCTAssertEqual(req.bodyParams?["answer"] as? String, answer)
            XCTAssertEqual(req.bodyParams?["passCode"] as? String, passCode)
            exp.fulfill()
        }

        api.verifyFactor(factorId: factorId,
                         stateToken: token,
                         answer: answer,
                         passCode: passCode,
                         rememberDevice: rememberDevice,
                         autoPush: autoPush)

        wait(for: [exp], timeout: 60.0)
    }

    func testVerifyFactorWithLink() {
        let stateToken = "stateToken"
        let link = LinksResponse.Link(name: "test", href: URL(string: "http://test")!, hints: [:])

        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, link.href)
            XCTAssertNil(req.path)
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, stateToken)
            exp.fulfill()
        }

        api.verifyFactor(with: link, stateToken: stateToken)

        wait(for: [exp], timeout: 60.0)
    }

    func testEnrollFactor() {
        let factor = EmbeddedResponse.Factor(
            id: "id",
            factorType: .sms,
            provider: .okta,
            vendorName: "Okta",
            profile: nil,
            embedded: nil,
            links: nil,
            enrollment: nil,
            status: nil
        )
        let link = LinksResponse.Link(name: "test", href: URL(string: "http://test")!, hints: [:])
        let stateToken = "stateToken"
        let phoneNumber = "phoneNumber"
        let questionId = "questionId"
        let answer = "answer"
        let credentialId = "credentialId"
        let passCode = "passCode"

        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, link.href)
            XCTAssertNil(req.path)
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, stateToken)
            XCTAssertEqual(req.bodyParams?["factorType"] as? String, factor.factorType.rawValue)
            XCTAssertEqual(req.bodyParams?["provider"] as? String, factor.provider?.rawValue)
            XCTAssertEqual(req.bodyParams?["passCode"] as? String, passCode)
            let profile = req.bodyParams?["profile"] as? [AnyHashable: Any]
            XCTAssertEqual(profile?["question"] as? String, questionId)
            XCTAssertEqual(profile?["answer"] as? String, answer)
            XCTAssertEqual(profile?["phoneNumber"] as? String, phoneNumber)
            XCTAssertEqual(profile?["credentialId"] as? String, credentialId)
            exp.fulfill()
        }

        api.enrollFactor(factor, with: link, stateToken: stateToken, phoneNumber: phoneNumber, questionId: questionId, answer: answer, credentialId: credentialId, passCode: passCode)

        wait(for: [exp], timeout: 60.0)
    }

    func testSendActivationLink() {
        let link = LinksResponse.Link(name: "test", href: URL(string: "http://test")!, hints: [:])
        let stateToken = "stateToken"

        let exp = XCTestExpectation()
        api.commonCompletion = { req, _ in
            XCTAssertEqual(req.baseURL, link.href)
            XCTAssertNil(req.path)
            XCTAssertEqual(req.bodyParams?["stateToken"] as? String, stateToken)
            exp.fulfill()
        }

        api.sendActivationLink(link: link, stateToken: stateToken)

        wait(for: [exp], timeout: 60.0)
    }
}
