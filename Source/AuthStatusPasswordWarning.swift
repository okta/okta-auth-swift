//
//  AuthStatusPasswordWarning.swift
//  OktaAuthNative
//
//  Created by Ildar Abdullin on 3/12/19.
//

import Foundation

public class OktaAuthStatusPasswordWarning : OktaAuthStatus {

    init(oktaDomain: URL, model: OktaAPISuccessResponse) {
        super.init(oktaDomain: oktaDomain)
        self.model = model
        statusType = .passwordWarning
    }

    public func changePassword(oldPassword: String,
                               newPassword: String,
                               onSuccess: @escaping (_ sessionToken: String) -> Void,
                               onError: @escaping (_ error: OktaError) -> Void) {

        let changePasswordStatus = OktaAuthStatusPasswordExpired(oktaDomain: self.url, model: self.model!)
        changePasswordStatus.changePassword(oldPassword: oldPassword,
                                            newPassword: newPassword,
                                            onSuccess: onSuccess,
                                            onError: onError)
    }

    public func skipPasswordChange(onSuccess: @escaping (_ sessionToken: String) -> Void,
                                   onError: @escaping (_ error: OktaError) -> Void) {

        guard canSkip() else {
            onError(.wrongState("Can't find 'skip' link in response"))
            return
        }

        api.perform(link: model!.links!.skip!, stateToken: model!.stateToken!) { result in

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
                
            default:
                onError(OktaError.unknownState(authResponse))
            }
        }
    }

    public func canSkip() -> Bool {
        
        guard (model?.links?.skip?.href) != nil else {
            return false
        }

        return true
    }
}
