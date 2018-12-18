//
//  OktaModels.swift
//  OktaAuth iOS
//
//  Created by Alex on 13 Dec 18.
//

import Foundation

// OktaAPISuceess and OktaAPIError are models for REST API json responses

public struct OktaAPISuccessResponse: Codable {

    var status: String?
    var stateToken: String?
//    var expiresAt: Date?

    /// ... etc

}

public struct OktaAPIErrorResponse: Codable {

    var errorCode: String?
    var errorSummary: String?
    var errorLink: String?

    /// ... etc

}
