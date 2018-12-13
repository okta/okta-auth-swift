//
//  OktaAPIRequest.swift
//  OktaAuth iOS
//
//  Created by Alex on 13 Dec 18.
//

import Foundation

/// Constructs and runs Okta API URL request

class OktaAPIRequest {

    var method: Method = .post
    var baseURL: URL?
    var path: String?
    var urlParams: [String: String]?
    var bodyParams: [String: String]?

    var responseHandler: ((OktaAPISuccess) -> Void)?
    var errorHandler: ((OktaAPIError) -> Void)?

    enum Method {
        case get, post, puth, delete, options
    }

    func run() {
        
    }

}
