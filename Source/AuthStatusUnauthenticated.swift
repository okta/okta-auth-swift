//
//  AuthStatusUnauthenticated.swift
//  OktaAuthNative
//
//  Created by Ildar Abdullin on 3/12/19.
//

import Foundation

public class OktaAuthStatusUnauthenticated : OktaAuthStatus {
    
    override init(oktaDomain: URL) {
        super.init(oktaDomain: oktaDomain)
        statusType = .unauthenticated
    }

    public func authenticate(username: String,
                             password: String,
                             onSuccess: @escaping (_ sessionToken: String) -> Void,
                             onPasswordWarning: @escaping (_ passwordWarningStatus: OktaAuthStatusPasswordWarning) -> Void,
                             onPasswordExpired: @escaping (_ passwordExpiredStatus: OktaAuthStatusPasswordExpired) -> Void,
                             onMFAEnroll: @escaping (_ mfaEnrollStatus: OktaAuthStatusMFAEnroll) -> Void,
                             onMFARequired: @escaping (_ mfaRequiredStatus: OktaAuthStatusMFARequired) -> Void,
                             onLockedOut: @escaping (_ lockedOutStatus: OktaAuthStatusLockedOut) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void)
    {
        api.primaryAuthentication(username: username,
                                  password: password,
                                  deviceFingerprint: nil)
        { result in
                                        
            var authResponse : OktaAPISuccessResponse
                                    
            switch result {
                case .error(let error):
                    onError(error)
                    return
                case .success(let success):
                    authResponse = success
            }
                    
            switch authResponse.status! {
                                            
                case .success:
                    onSuccess(authResponse.sessionToken!)

                case .passwordWarning:
                    onPasswordWarning(OktaAuthStatusPasswordWarning(oktaDomain: self.url, model:authResponse))
                                            
                case .passwordExpired:
                    onPasswordExpired(OktaAuthStatusPasswordExpired(oktaDomain: self.url, model:authResponse))

                case .MFAEnroll:
                    onMFAEnroll(OktaAuthStatusMFAEnroll(oktaDomain: self.url, model:authResponse))
                                            
                case .MFARequired:
                    onMFARequired(OktaAuthStatusMFARequired(oktaDomain: self.url, model:authResponse))
                                            
                case .lockedOut:
                    onLockedOut(OktaAuthStatusLockedOut(oktaDomain: self.url, model:authResponse))

                case .unauthenticated:
                    onError(OktaError.wrongState("Wrong state"))
                                            
                default:
                    onError(OktaError.unknownState(authResponse))
            }
        }
    }

    public func authenticate(username: String,
                             password: String,
                             onSuccess: @escaping (_ sessionToken: String) -> Void,
                             onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void) {

        api.primaryAuthentication(username: username,
                                  password: password,
                                  deviceFingerprint: nil)
        { result in
            
            self.handleServerResponse(result,
                                      onSuccess: onSuccess,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        }
    }

    public func unlockAccount(username: String,
                              factorType: FactorType,
                              onRecoveryChallenge: @escaping (_ recoveryChallengeStatus: OktaAuthStatusRecoveryChallenge) -> Void,
                              onError: @escaping (_ error: OktaError) -> Void) {
        // implement
    }
    
    public func recoverPassword(username: String,
                                factorType: FactorType,
                                onRecoveryChallenge: @escaping (_ recoveryChallengeStatus: OktaAuthStatusRecoveryChallenge) -> Void,
                                onError: @escaping (_ error: OktaError) -> Void) {
        // implement
    }
}
