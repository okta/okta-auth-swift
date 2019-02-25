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

import Foundation

public enum OktaError: Error {
    case errorBuildingURLRequest
    case connectionError(Error)
    case emptyServerResponse
    case responseSerializationError(Error)
    case serverRespondedWithError(OktaAPIErrorResponse)
    case authenicationStateNotSupported(AuthStatus)
    case factorNotSupported(EmbeddedResponse.Factor)
    case unexpectedResponse
    case wrongState(String)
    case alreadyInProgress
}

public extension OktaError {
    var description: String {
        switch self {
        case .errorBuildingURLRequest:
            return "Error building URL request"
        case .connectionError(let error):
            return "Connection error (\(error.localizedDescription))"
        case .emptyServerResponse:
            return "Empty server response"
        case .responseSerializationError(let error):
            return "Response serialization error (\(error.localizedDescription))"
        case .serverRespondedWithError(let error):
            let description: String
            if let causes = error.errorCauses, causes.count > 0 {
                description = causes.compactMap { $0.errorSummary }.joined(separator: "; ")
            } else if let summary = error.errorSummary {
                description = summary
            } else {
                description = "Unknown"
            }
            return "Server responded with error: \(description)"
        case .authenicationStateNotSupported(let status):
            return "Authenication state not supported (\(status.description))"
        case .factorNotSupported(let factor):
            return "MFA factor not supported (\(factor))"
        case .unexpectedResponse:
            return "Unexpected response"
        case .wrongState(error: let error):
            return error
        case .alreadyInProgress:
            return "Another request is in progress"
        }
    }
}
