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
            return
        }
        
        client.authenticate(username: "username", password: "password")

        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testAuthenticateErrorFlows() {
        
        let request = OktaAPIRequest(baseURL: URL(string: "https://dummy.url")!,
                                     urlSession: URLSession(configuration: .default),
                                     completion: { _ = $0; _ = $1})
        client.currentRequest = request
        client.authenticate(username: "username", password: "password")
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.alreadyInProgress.description)
        
        client.currentRequest = nil
        client.status = .success
        client.authenticate(username: "username", password: "password")
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.wrongState("'unauthenticated' state expected").description)
    }
    
    func testPasswordExpiredSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthExpiredPassword")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertEqual(.passwordExpired, client.status)
        XCTAssertNotNil(client.stateToken)
        XCTAssertNotNil(delegateVerifyer.handleChangePasswordCompletion)
        XCTAssertTrue(delegateVerifyer.handleChangePasswordCalled, "Expected delegate method handleChangePasswordCalled to be called")

        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        delegateVerifyer.asyncExpectation = XCTestExpectation()
        delegateVerifyer.handleChangePasswordCompletion?("old_password", "new_password", false)
        XCTAssertTrue(oktaApiMock!.changePasswordCalled)
        XCTAssertFalse(delegateVerifyer.canSkipChangePassword)
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        checkSuccessStateResults()
    }
    
    func testPasswordChangeErrorFlows() {
        
        let request = OktaAPIRequest(baseURL: URL(string: "https://dummy.url")!,
                                     urlSession: URLSession(configuration: .default),
                                     completion: { _ = $0; _ = $1})
        client.currentRequest = request
        client.changePassword(oldPassword: "old_password", newPassword: "new_password")
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.alreadyInProgress.description)
        
        client.currentRequest = nil
        client.changePassword(oldPassword: "old_password", newPassword: "new_password")
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.wrongState("No state token").description)
        
        client.stateToken = "state_token"
        client.changePassword(oldPassword: "old_password", newPassword: "new_password")
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.wrongState("'passwordExpired' or 'passwordWarning' state expected").description)
        
        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthWarnPassword")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        delegateVerifyer.asyncExpectation = XCTestExpectation()
        client.status = .unauthenticated
        client.authenticate(username: "username", password: "password")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        client.links = nil
        delegateVerifyer.handleChangePasswordCompletion?(nil, nil, true)
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.wrongState("Can't find 'next' link in response").description)
    }
    
    func testPasswordWarningWithNoPasswordChangeSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthWarnPassword")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertEqual(.passwordWarning, client.status)
        XCTAssertNotNil(client.stateToken)
        XCTAssertNotNil(delegateVerifyer.handleChangePasswordCompletion)
        XCTAssertTrue(delegateVerifyer.handleChangePasswordCalled, "Expected delegate method handleChangePasswordCalled to be called")
        XCTAssertTrue(delegateVerifyer.canSkipChangePassword)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        delegateVerifyer.asyncExpectation = XCTestExpectation()
        delegateVerifyer.handleChangePasswordCompletion?(nil, nil, true)
        XCTAssertTrue(oktaApiMock!.performCalled)
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        checkSuccessStateResults()
    }
    
    func testPasswordWarningWithPasswordChangeSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthWarnPassword")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertEqual(.passwordWarning, client.status)
        XCTAssertNotNil(client.stateToken)
        XCTAssertNotNil(delegateVerifyer.handleChangePasswordCompletion)
        XCTAssertTrue(delegateVerifyer.handleChangePasswordCalled, "Expected delegate method handleChangePasswordCalled to be called")
        XCTAssertTrue(delegateVerifyer.canSkipChangePassword)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        delegateVerifyer.asyncExpectation = XCTestExpectation()
        delegateVerifyer.handleChangePasswordCompletion?(nil, nil, false)
        XCTAssertTrue(oktaApiMock!.changePasswordCalled)
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        checkSuccessStateResults()
    }
    
    func testCancellationBasicSuccessFlow() {
        
        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "TransactionCancellationSuccess")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.stateToken = "state_token"
        client.cancelTransaction()
        
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
        
        client.stateToken = "state_token"
        delegateVerifyer.asyncExpectation = XCTestExpectation()
        client.factorResultPollTimer = Timer(timeInterval: 0.1, repeats: false) { _ in
        }
        XCTAssertTrue(client.factorResultPollTimer!.isValid)
        
        DispatchQueue.global().async {
            self.client.cancelTransaction()
        }
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertFalse(client.factorResultPollTimer!.isValid)
        
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
    
    func testCancellationErrorFlows() {
        
        client.cancelTransaction()
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.wrongState("No state token").description)
    }
    
    func testFetchTransactionStatusSuccessFlow() {
        
        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.stateToken = "state_token"
        client.fetchTransactionState()
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testFetchTransactionStatusErrorFlows() {
        
        let request = OktaAPIRequest(baseURL: URL(string: "https://dummy.url")!,
                                     urlSession: URLSession(configuration: .default),
                                     completion: { _ = $0; _ = $1})
        client.currentRequest = request
        client.fetchTransactionState()
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.alreadyInProgress.description)
        
        client.currentRequest = nil
        client.fetchTransactionState()
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.wrongState("No state token").description)
    }
    
    func testVerifyFactorSuccessFlow() {
        
        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.stateToken = "state_token"
        let factor = EmbeddedResponse.Factor(id: "factor_id", factorType: nil, provider: nil, vendorName: nil, profile: nil)
        client.verify(factor: factor)
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testVerifyFactorErrorFlows() {
        
        let request = OktaAPIRequest(baseURL: URL(string: "https://dummy.url")!,
                                     urlSession: URLSession(configuration: .default),
                                     completion: { _ = $0; _ = $1})
        client.currentRequest = request
        var factor = EmbeddedResponse.Factor(id: "factor_id", factorType: nil, provider: nil, vendorName: nil, profile: nil)
        client.verify(factor: factor)
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.alreadyInProgress.description)
        
        client.currentRequest = nil
        factor = EmbeddedResponse.Factor(id: "factor_id", factorType: nil, provider: nil, vendorName: nil, profile: nil)
        client.verify(factor: factor)
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.wrongState("No state token").description)
    }
    
    func testCheckAPIResultErrorBasicAuthFlow() {
        
        let oktaApiMock = OktaAPIMock(successCase: false, resourceName: "AuthenticationFailedError")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
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
            return
        }

        client.authenticate(username: "username", password: "password")

        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(mfaHandlerVerifyer.factors)
        XCTAssertTrue(mfaHandlerVerifyer.selectFactorCalled, "Expected delegate method selectFactorCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.selectFactorCompletion)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "MFAWaitPushChallenge")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.factorResultPollRate = 0.1
        mfaHandlerVerifyer.asyncExpectation = XCTestExpectation()
        mfaHandlerVerifyer.selectFactorCompletion?(mfaHandlerVerifyer.factors![0])

        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)

        XCTAssertTrue(mfaHandlerVerifyer.pushStateUpdatedCalled)
        XCTAssertEqual(mfaHandlerVerifyer.state?.rawValue, "WAITING")
        XCTAssertTrue(client.factorResultPollTimer!.isValid)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testAuthenticateWithTOTPFactorSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthFactorsResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(mfaHandlerVerifyer.factors)
        XCTAssertTrue(mfaHandlerVerifyer.selectFactorCalled, "Expected delegate method selectFactorCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.selectFactorCompletion)

        mfaHandlerVerifyer.selectFactorCompletion!(mfaHandlerVerifyer.factors![1])
        
        XCTAssertTrue(mfaHandlerVerifyer.requestTOTPCalled, "Expected delegate method requestTOTPCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.requestTOTPCodeCompletion)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        mfaHandlerVerifyer.requestTOTPCodeCompletion?("1234")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testAuthenticateWithSmsFactorSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthFactorsResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(mfaHandlerVerifyer.factors)
        XCTAssertTrue(mfaHandlerVerifyer.selectFactorCalled, "Expected delegate method selectFactorCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.selectFactorCompletion)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "MFAWaitSmsChallenge")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        mfaHandlerVerifyer.selectFactorCompletion?(mfaHandlerVerifyer.factors![2])
        
        mfaHandlerVerifyer.asyncExpectation = XCTestExpectation()
        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(mfaHandlerVerifyer.phoneNumber)
        XCTAssertTrue(mfaHandlerVerifyer.requestSMSCodeCalled, "Expected delegate method requestSMSCodeCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.requestSMSCodeCompletion)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        mfaHandlerVerifyer.requestSMSCodeCompletion?("1234")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testVerifySMSSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthFactorsResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(mfaHandlerVerifyer.factors)
        XCTAssertTrue(mfaHandlerVerifyer.selectFactorCalled, "Expected delegate method selectFactorCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.selectFactorCompletion)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "MFAWaitSmsChallenge")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.verify(factor: mfaHandlerVerifyer.factors![2])
        
        mfaHandlerVerifyer.asyncExpectation = XCTestExpectation()
        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(mfaHandlerVerifyer.phoneNumber)
        XCTAssertTrue(mfaHandlerVerifyer.requestSMSCodeCalled, "Expected delegate method requestSMSCodeCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.requestSMSCodeCompletion)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.verify(factor: mfaHandlerVerifyer.factors![2], passCode: "1234")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testAuthenticateWithQuestionFactorSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthFactorsResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(mfaHandlerVerifyer.factors)
        XCTAssertTrue(mfaHandlerVerifyer.selectFactorCalled, "Expected delegate method selectFactorCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.selectFactorCompletion)
        
        mfaHandlerVerifyer.selectFactorCompletion!(mfaHandlerVerifyer.factors![3])
        
        XCTAssertTrue(mfaHandlerVerifyer.securityQuestionCalled, "Expected delegate method securityQuestionCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.securityQuestionCompletion)
        XCTAssertNotNil(mfaHandlerVerifyer.question)
        XCTAssertEqual(mfaHandlerVerifyer.question, "What is your favorite piece of art?")
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        mfaHandlerVerifyer.securityQuestionCompletion?("answer")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testVerifyPushSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthFactorsResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
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
        
        client.verify(factor: mfaHandlerVerifyer.factors![0])
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        self.checkSuccessStateResults()
    }
    
    func testPerformLinkSuccessFlow() {
        
        var oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthFactorsResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)

        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "MFAWaitSmsChallenge")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.verify(factor: mfaHandlerVerifyer.factors![2])
        
        mfaHandlerVerifyer.asyncExpectation = XCTestExpectation()
        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(client.links)
        XCTAssertNotNil(client.links?.next)
        XCTAssertNotNil(client.links?.prev)
        XCTAssertNotNil(client.links?.cancel)
        
        oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthFactorsResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
        }
        
        client.perform(link: client.links!.prev!)
        
        mfaHandlerVerifyer.asyncExpectation = XCTestExpectation()
        wait(for: [mfaHandlerVerifyer.asyncExpectation!], timeout: 1.0)
        
        XCTAssertNotNil(mfaHandlerVerifyer.factors)
        XCTAssertTrue(mfaHandlerVerifyer.selectFactorCalled, "Expected delegate method selectFactorCalled to be called")
        XCTAssertNotNil(mfaHandlerVerifyer.selectFactorCompletion)
    }
    
    func testPerformLinkErrorFlows() {
        
        let request = OktaAPIRequest(baseURL: URL(string: "https://dummy.url")!,
                                     urlSession: URLSession(configuration: .default),
                                     completion: { _ = $0; _ = $1})
        client.currentRequest = request
        
        let link = LinksResponse.Link(href: URL(string: "https://dummy.url")!, hints: [:])
        client.perform(link: link)
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.alreadyInProgress.description)
        
        client.currentRequest = nil
        client.perform(link: link)
        XCTAssertTrue(delegateVerifyer.handleErrorCalled, "Expected delegate method handleErrorCalled to be called")
        XCTAssertNotNil(delegateVerifyer.error)
        XCTAssertEqual(delegateVerifyer.error?.description, OktaError.wrongState("No state token").description)
    }
    
    func testResetStatusFlow() {
     
        let oktaApiMock = OktaAPIMock(successCase: true, resourceName: "PrimaryAuthResponse")
        if let oktaApiMock = oktaApiMock {
            client.api = oktaApiMock
        } else {
            XCTFail("Incorrect OktaApiMock usage")
            return
        }
        
        client.authenticate(username: "username", password: "password")
        
        wait(for: [delegateVerifyer.asyncExpectation!], timeout: 1.0)
        
        checkSuccessStateResults()
        
        client.resetStatus()

        XCTAssertNil(client.sessionToken)
        XCTAssertEqual(.unauthenticated, client.status)
        XCTAssertNil(client.stateToken)
        XCTAssertNil(client.factorResult)
        XCTAssertNil(client.links)
        XCTAssertNil(client.recoveryToken)
        XCTAssertNil(client.embedded)
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
