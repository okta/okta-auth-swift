//
//  OktaAuthSdk.swift
//  OktaAuthNative
//
//  Created by Ildar Abdullin on 3/12/19.
//

import Foundation

public class OktaAuthSdk {
    
    public class func authenticate(with url: URL,
                                   username: String,
                                   password: String,
                                   onSuccess: @escaping (_ sessionToken: String) -> Void,
                                   onPasswordWarning: @escaping (_ passwordWarningStatus: OktaAuthStatusPasswordWarning) -> Void,
                                   onPasswordExpired: @escaping (_ passwordExpiredStatus: OktaAuthStatusPasswordExpired) -> Void,
                                   onMFAEnroll: @escaping (_ mfaEnrollStatus: OktaAuthStatusMFAEnroll) -> Void,
                                   onMFARequired: @escaping (_ mfaRequiredStatus: OktaAuthStatusMFARequired) -> Void,
                                   onLockedOut: @escaping (_ lockedOutStatus: OktaAuthStatusLockedOut) -> Void,
                                   onError: @escaping (_ error: OktaError) -> Void)
    {
        let unauthenticatedStatus = OktaAuthStatusUnauthenticated(oktaDomain: url)
        unauthenticatedStatus.authenticate(username: username,
                                           password: password,
                                           onSuccess: onSuccess,
                                           onPasswordWarning: onPasswordWarning,
                                           onPasswordExpired: onPasswordExpired,
                                           onMFAEnroll: onMFAEnroll,
                                           onMFARequired: onMFARequired,
                                           onLockedOut: onLockedOut,
                                           onError: onError)
    }
    
    public class func unlockAccount(username: String) {
        
    }

    public class func recoverPassword(username: String) {
        
    }
}
