//
//  AuthStatusRecoveryChallenge.swift
//  OktaAuthNative
//
//  Created by Ildar Abdullin on 3/13/19.
//

import Foundation

public class OktaAuthStatusRecoveryChallenge : OktaAuthStatus {

    init(oktaDomain: URL, model: OktaAPISuccessResponse) {
        super.init(oktaDomain: oktaDomain)
        self.model = model
        statusType = .MFAEnroll
    }
}
