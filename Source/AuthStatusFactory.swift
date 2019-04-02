//
//  AuthStatusFactory.swift
//  OktaAuthNative
//
//  Created by Ildar Abdullin on 3/22/19.
//

import Foundation

public class AuthStatusFactory {
    
    public class func createAuthStatus(basedOn response: OktaAPISuccessResponse,
                                       and previousStatus: OktaAuthStatus) throws -> OktaAuthStatus {
        
        switch response.status! {

        case .passwordWarning:
            return OktaAuthStatusPasswordWarning(oktaDomain: previousStatus.url, model:response)
            
        case .passwordExpired:
            return OktaAuthStatusPasswordExpired(oktaDomain: previousStatus.url, model:response)
            
        case .MFAEnroll:
            return OktaAuthStatusMFAEnroll(oktaDomain: previousStatus.url, model:response)
            
        case .MFARequired:
            return OktaAuthStatusMFARequired(oktaDomain: previousStatus.url, model:response)
            
        case .lockedOut:
            return OktaAuthStatusLockedOut(oktaDomain: previousStatus.url, model:response)
            
        case .unauthenticated:
            throw OktaError.wrongState("Wrong state")
            
        default:
            throw OktaError.unknownState(response)
        }
    }
}
