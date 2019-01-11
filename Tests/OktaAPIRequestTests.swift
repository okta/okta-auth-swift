//
//  OktaAPIRequestTests.swift
//  OktaAuth iOS Tests
//
//  Created by Alex Lebedev on 12/26/18.
//

import XCTest
@testable import OktaAuth

class OktaAPIRequestTests : XCTestCase {
    
    let url = URL(string: "http://example.com")!
    var req: OktaAPIRequest!
    
    override func setUp() {
        req = OktaAPIRequest(urlSession: URLSession.shared) { req, res in }
        req.baseURL = url
        req.path = "/"
    }
    
    override func tearDown() {
        req = nil
    }
    
    func testSetsHTTPSScheme() {
        guard let URLString = req.buildRequest()?.url?.absoluteString else {
            XCTFail("No URL string")
            return
        }
        
        XCTAssertTrue(url.absoluteString.hasPrefix("http"))
        XCTAssertTrue(URLString.hasPrefix("https"))
    }
    
    func testURLBuild() {
        req.path = "/test/path"
        req.urlParams = ["param": "value"]
        
        guard let URLString = req.buildRequest()?.url?.absoluteString else {
            XCTFail("No URL string")
            return
        }
        
        XCTAssertEqual(URLString, "https://example.com/test/path?param=value")
    }
    
    func testHeaders() {
        guard let URLRequest = req.buildRequest() else {
            XCTFail("No URL request")
            return
        }
        
        XCTAssertEqual(URLRequest.value(forHTTPHeaderField: "Accept"), "application/json")
        XCTAssertEqual(URLRequest.value(forHTTPHeaderField: "Content-Type"), "application/json")
        XCTAssertNotNil(URLRequest.value(forHTTPHeaderField: "User-Agent"))
    }
    
    func testAdditionalHeders() {
        let header = "X-Test-Header"
        let value = "HEADER_VALUE"
        req.additionalHeaders = [header: value]
        
        guard let URLRequest = req.buildRequest() else {
            XCTFail("No URL request")
            return
        }
        
        XCTAssertEqual(URLRequest.value(forHTTPHeaderField: header), value)
    }
    
    func testBodyParams() {
        req.bodyParams = ["root_param": [ "nested_param": "value" ]]
        
        guard let URLRequest = req.buildRequest() else {
            XCTFail("No URL request")
            return
        }
        
        guard let data = URLRequest.httpBody,
            let string = String(data: data, encoding: .utf8) else {
            XCTFail("No HTTP body")
                return
        }
        
        XCTAssertEqual(string, "{\"root_param\":{\"nested_param\":\"value\"}}")
    }
    
    func testMethod() {
        req.method = .delete
        
        guard let methodString = req.buildRequest()?.httpMethod else {
            XCTFail("No HTTP method")
            return
        }
        
        XCTAssertEqual(methodString, "DELETE")
    }
    
    func testHandleSuccessResponse() {
        let status = "SUCCESS"
        let exp = XCTestExpectation(description: "Success result")
        let req = OktaAPIRequest(urlSession: URLSession.shared) { req, res in
            if case .success(let response) = res, response.status.rawValue == status {
                exp.fulfill()
            } else {
                XCTFail()
            }
        }
        
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let data = "{\"status\":\"\(status)\"}".data(using: .utf8)!
        
        req.handleResponse(data: data, response: httpResponse)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testErrorResponse() {
        let errorCode = "42"
        let exp = XCTestExpectation(description: "Error result")
        let req = OktaAPIRequest(urlSession: URLSession.shared) { req, res in
            if case .error(let error) = res,
                case .serverRespondedWithError(let response) = error,
                response.errorCode == errorCode {
                exp.fulfill()
            } else {
                XCTFail()
            }
        }
        
        let httpResponse = HTTPURLResponse(url: url, statusCode: 400, httpVersion: nil, headerFields: nil)!
        let data = "{\"errorCode\":\"\(errorCode)\"}".data(using: .utf8)!
        
        req.handleResponse(data: data, response: httpResponse)
        
        wait(for: [exp], timeout: 1.0)
    }
}
