//
//  File.swift
//  OktaAuthNative
//
//  Created by Ildar Abdullin on 3/12/19.
//

import Foundation

public class OktaAuthStatus {

    public internal(set) var url: URL

    public internal(set) var api: OktaAPI

    public internal(set) var statusType : AuthStatus = .unknown("Unknown status")

    public internal(set) var model: OktaAPISuccessResponse?

    init(oktaDomain: URL) {
        
        self.url = oktaDomain
        self.api = OktaAPI(oktaDomain: oktaDomain)
    }
}
