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
    
    public func cancel(onSuccess: @escaping () -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        // implement
    }

    func createAuthStatus(basedOn response: OktaAPISuccessResponse,
                          and previousStatus: OktaAuthStatus) throws -> OktaAuthStatus {
        
        guard let status = response.status else {
            throw OktaError.invalidResponse
        }
        
        switch status {
            
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

    func handleServerResponse(_ response: OktaAPIRequest.Result,
                              onSuccess: @escaping (_ sessionToken: String) -> Void,
                              onStatusChanged: @escaping (_ newState: OktaAuthStatus) -> Void,
                              onError: @escaping (_ error: OktaError) -> Void)
    {
        var authResponse : OktaAPISuccessResponse
        
        switch response {
        case .error(let error):
            onError(error)
            return
        case .success(let success):
            authResponse = success
        }

        guard let status = authResponse.status else {
            onError(OktaError.invalidResponse)
        }

        if status == .success {
            guard let sessionToken = authResponse.sessionToken else {
                onError(OktaError.invalidResponse)
            }
            onSuccess(sessionToken)
        }
        
        do {
            let status = try self.createAuthStatus(basedOn: authResponse, and: self)
            onStatusChanged(status)
        } catch let error as OktaError {
            onError(error)
        } catch {
            onError(OktaError.unexpectedResponse)
        }
    }
}
