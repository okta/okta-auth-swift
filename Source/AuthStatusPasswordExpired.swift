//
//  AuthStatusPasswordExpired.swift
//  OktaAuthNative
//
//  Created by Ildar Abdullin on 3/12/19.
//

import Foundation

public class OktaAuthStatusPasswordExpired : OktaAuthStatus {

    init(oktaDomain: URL, model: OktaAPISuccessResponse) {
        super.init(oktaDomain: oktaDomain)
        self.model = model
        statusType = .passwordExpired
    }

    public func changePassword(oldPassword: String,
                               newPassword: String,
                               onSuccess: @escaping (_ sessionToken: String) -> Void,
                               onError: @escaping (_ error: OktaError) -> Void) {

        guard canChange() else {
            onError(.wrongState("Can't find 'skip' link in response"))
            return
        }

        api.changePassword(link: model!.links!.next!,
                           stateToken: model!.sessionToken!,
                           oldPassword: oldPassword,
                           newPassword: newPassword) { result in
    
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

    public func canChange() -> Bool {
        
        guard (model?.links?.next?.href) != nil else {
            return false
        }

        return true
    }
}
