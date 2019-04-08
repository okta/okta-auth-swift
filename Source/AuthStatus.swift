/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

import Foundation

open class OktaAuthStatus {

    public internal(set) var api: OktaAPI

    public internal(set) var statusType : AuthStatus = .unknown("Unknown status")

    public internal(set) var model: OktaAPISuccessResponse

    public internal(set) var responseHandler: AuthStatusCustomHandlerProtocol?

    init(oktaDomain: URL, model: OktaAPISuccessResponse, responseHandler: AuthStatusCustomHandlerProtocol? = nil) {
        self.api = OktaAPI(oktaDomain: oktaDomain)
        self.model = model
        self.responseHandler = responseHandler
    }

    init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) {
        self.model = model
        self.api = currentState.api
        self.responseHandler = currentState.responseHandler
    }

    public var user: EmbeddedResponse.User? {
        get {
            return model.embedded?.user
        }
    }

    public var links: LinksResponse? {
        get {
            return model.links
        }
    }
    
    public func canCancel() -> Bool {
        guard model.links?.cancel?.href != nil else {
            return false
        }

        return true
    }

    public func cancel(onSuccess: @escaping () -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        let completion: ((OktaAPIRequest.Result) -> Void) = { result in
            switch result {
            case .error(let error):
                onError(error)
            case .success(_):
                self.cancelled = true
                onSuccess()
            }
        }

        if canCancel() {
            api.cancelTransaction(with: model.links!.cancel!, stateToken: model.stateToken!, completion: completion)
        } else {
            api.cancelTransaction(stateToken: model.stateToken!, completion: completion)
        }
    }

    public func handleServerResponse(_ response: OktaAPIRequest.Result,
                                     onStatusChanged: @escaping (_ newState: OktaAuthStatus) -> Void,
                                     onError: @escaping (_ error: OktaError) -> Void)
    {
        if let responseHandler = self.responseHandler {
            responseHandler.handleServerStatusResponse(currentStatus: self, response: response)
            return
        }

        if cancelled {
            return
        }

        var authResponse : OktaAPISuccessResponse
        
        switch response {
        case .error(let error):
            onError(error)
            return
        case .success(let success):
            authResponse = success
        }
        
        do {
            let status = try self.createAuthStatus(basedOn: authResponse)
            onStatusChanged(status)
        } catch let error as OktaError {
            onError(error)
        } catch {
            onError(OktaError.unexpectedResponse)
        }
    }

    public func createAuthStatus(basedOn response: OktaAPISuccessResponse) throws -> OktaAuthStatus {
        // perform basic checks
        guard let status = response.status else {
            throw OktaError.invalidResponse
        }

        if case .success = status {
            guard response.sessionToken != nil else {
                throw OktaError.invalidResponse
            }
        } else {
            guard response.stateToken != nil else {
                throw OktaError.invalidResponse
            }
        }
        
        // create concrete status instance
        switch status {
            
        case .success:
            return OktaAuthStatusSuccess(currentState: self, model: response)
            
        case .passwordWarning:
            return OktaAuthStatusPasswordWarning(currentState: self, model: response)
            
        case .passwordExpired:
            return OktaAuthStatusPasswordExpired(currentState: self, model: response)
            
        case .passwordReset:
            return OktaAuthStatusPasswordReset(currentState: self, model: response)
            
        case .MFAEnroll:
            return OktaAuthStatusFactorEnroll(currentState: self, model: response)
            
        case .MFAEnrollActivate:
            return OktaAuthStatusFactorEnrollActivate(currentState: self, model: response)
            
        case .MFARequired:
            return OktaAuthStatusFactorRequired(currentState: self, model: response)
            
        case .MFAChallenge:
            return OktaAuthStatusFactorChallenge(currentState: self, model: response)
            
        case .lockedOut:
            return OktaAuthStatusLockedOut(currentState: self, model: response)
            
        case .recovery:
            return OktaAuthStatusRecovery(currentState: self, model: response)
            
        case .recoveryChallenge:
            return OktaAuthStatusRecoveryChallenge(currentState: self, model: response)
            
        case .unauthenticated:
            throw OktaError.wrongState("Wrong state")
            
        default:
            throw OktaError.unknownState(response)
        }
    }

    private var cancelled = false
}
