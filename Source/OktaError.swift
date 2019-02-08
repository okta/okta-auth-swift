//
//  OktaError.swift
//  OktaAuth iOS
//
//  Created by Alex on 13 Dec 18.
//

import Foundation

public enum OktaError: Error {
    case errorBuildingURLRequest
    case connectionError(Error)
    case emptyServerResponse
    case responseSerializationError(Error)
    case serverRespondedWithError(OktaAPIErrorResponse)
    case authenicationStatusNotSupported(AuthStatus)
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
        case .authenicationStatusNotSupported(let status):
            return "Authenication state not supported (\(status.description))"
        case .unexpectedResponse:
            return "Unexpected response"
        case .wrongState:
            return "Wrong state"
        case .alreadyInProgress:
            return "Another request is in progress"
        }
    }
}
