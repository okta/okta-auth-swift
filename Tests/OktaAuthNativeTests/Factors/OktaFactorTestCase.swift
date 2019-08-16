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

class OktaFactorTestCase: XCTestCase {
    func createFactor<T: OktaFactor>(from response: TestResponse, type: FactorType) -> T? {
        guard let responseModel = response.parse(),
              let statetoken = responseModel.stateToken else {
            XCTFail("Unable to parse response!")
            return nil
        }
        
        guard let responseFactor: EmbeddedResponse.Factor = {
            if responseModel.embedded?.factor?.factorType == type {
                return responseModel.embedded?.factor
            }
            
            return responseModel.embedded?.factors?.first(where: { $0.factorType == type })
        }() else {
            return nil
        }
        
        let verifyLink = responseModel.links?.verify ?? responseFactor.links?.verify
        let activationLink = (responseModel.links?.next?.name == "activate") ? responseModel.links?.next : nil
        
        return OktaFactor.createFactorWith(responseFactor,
                                           stateToken: statetoken,
                                           verifyLink: verifyLink,
                                           activationLink: activationLink) as? T
    }
    
    func verifyDelegateFailed(_ delegate: OktaFactorResultProtocolMock, with errorDescription: String? = nil) {
        guard let delegateResponse = delegate.response,
              case .error(let error) = delegateResponse else {
            XCTFail("Delegate should be called with error response!")
            return
        }
        
        guard let expectedError = errorDescription else {
            return
        }
        
        XCTAssertEqual(expectedError, error.localizedDescription)
    }
    
    func verifyDelegateSucceeded(_ delegate: OktaFactorResultProtocolMock, with expectedResponse: TestResponse) {
        guard let delegateResponse = delegate.response,
              case .success(let response) = delegateResponse else {
            XCTFail("Delegate should be called with success response!")
            return
        }
        
        XCTAssertEqual(expectedResponse.parse()?.rawData, response.rawData)
    }
}
