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

class OktaAPIRequestTests : XCTestCase {
    
    let url = URL(string: "https://example.com")!
    var req: OktaAPIRequest!
    
    override func setUp() {
        req = OktaAPIRequest(baseURL: url, urlSession: URLSession.shared) { req, res in }
    }
    
    override func tearDown() {
        req = nil
    }
    
    func testSetsHTTPSScheme() throws {
        guard let URLString = try XCTUnwrap(req.buildRequest()).url?.absoluteString else {
            XCTFail("No URL string")
            return
        }
        
        XCTAssertTrue(url.absoluteString.hasPrefix("http"))
        XCTAssertTrue(URLString.hasPrefix("https"))
    }
    
    func testURLBuild() {
        req.path = "/test/path"
        req.urlParams = ["param": "value"]
        
        guard let URLString = try? req.buildRequest().url?.absoluteString else {
            XCTFail("No URL string")
            return
        }
        
        XCTAssertEqual(URLString, "https://example.com/test/path?param=value")
    }
    
    func testHeaders() {
        guard let URLRequest = try? req.buildRequest() else {
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
        
        guard let URLRequest = try? req.buildRequest() else {
            XCTFail("No URL request")
            return
        }
        
        XCTAssertEqual(URLRequest.value(forHTTPHeaderField: header), value)
    }
    
    func testBodyParams() {
        req.bodyParams = ["root_param": [ "nested_param": "value" ]]
        
        guard let URLRequest = try? req.buildRequest() else {
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
        
        guard let methodString = try? req.buildRequest().httpMethod else {
            XCTFail("No HTTP method")
            return
        }
        
        XCTAssertEqual(methodString, "DELETE")
    }
    
    func testHandleSuccessResponse() {
        let status = AuthStatus.success
        let exp = XCTestExpectation(description: "Success result")
        let req = OktaAPIRequest(baseURL: url, urlSession: URLSession.shared) { req, res in
            if case .success(let response) = res, response.status == status {
                exp.fulfill()
            } else {
                XCTFail()
            }
        }
        
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let data = "{\"status\":\"SUCCESS\"}".data(using: .utf8)!
        
        req.handleResponse(data: data, response: httpResponse, error: nil)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testErrorResponse() {
        let errorCode = "42"
        let exp = XCTestExpectation(description: "Error result")
        let req = OktaAPIRequest(baseURL: url, urlSession: URLSession.shared) { req, res in
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
        
        req.handleResponse(data: data, response: httpResponse, error: nil)
        
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRun_WithInjectedDelegate() {
        let status = AuthStatus.success
        let httpResponse = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil, headerFields: nil)!
        let data = "{\"status\":\"SUCCESS\"}".data(using: .utf8)!
        let exp = XCTestExpectation(description: "Success result")
        let mock = OktaAuthHTTPClientMock(data: data, httpResponse: httpResponse, error: nil)
        
        let req = OktaAPIRequest(baseURL: url, urlSession: URLSession.shared, httpClient: mock) { (req, res) in
            if case .success(let response) = res, response.status == status {
                exp.fulfill()
            } else {
                XCTFail()
            }
        }
        req.run()
        XCTAssertTrue(mock.didSendRequest)
        wait(for: [exp], timeout: 1.0)
    }
    
    func testRun_withoutInjectedDelegate() {
        let mock = OktaURLSessionMock()
        let req = OktaAPIRequest(baseURL: url, urlSession: mock) { (request, result) in
        }
        req.run()
        XCTAssertTrue(mock.didSendRequest)
    }
}
