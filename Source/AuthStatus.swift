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

public class OktaAuthStatus {

    public internal(set) var url: URL

    public internal(set) var api: OktaAPI

    public internal(set) var statusType : AuthStatus = .unknown("Unknown status")

    public internal(set) var model: OktaAPISuccessResponse?

    init(oktaDomain: URL, model: OktaAPISuccessResponse? = nil) {
        
        self.url = oktaDomain
        self.api = OktaAPI(oktaDomain: oktaDomain)
        self.model = model
    }

    public var user: EmbeddedResponse.User? {
        get {
            return model?.embedded?.user
        }
    }

    public var links: LinksResponse? {
        get {
            return model?.links
        }
    }
    
    public func canCancel() -> Bool {
        guard model?.links?.cancel?.href != nil else {
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
            api.cancelTransaction(with: model!.links!.cancel!, stateToken: model!.stateToken!, completion: completion)
        } else {
            api.cancelTransaction(stateToken: model!.stateToken!, completion: completion)
        }
    }

    private var cancelled = false

    func handleServerResponse(_ response: OktaAPIRequest.Result,
                              onStatusChanged: @escaping (_ newState: OktaAuthStatus) -> Void,
                              onError: @escaping (_ error: OktaError) -> Void)
    {
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

    func createAuthStatus(basedOn response: OktaAPISuccessResponse) throws -> OktaAuthStatus {
        
        guard let status = response.status else {
            throw OktaError.invalidResponse
        }
        
        switch status {
            
        case .success:
            return OktaAuthStatusSuccess(oktaDomain: self.url, model:response)
            
        case .passwordWarning:
            return OktaAuthStatusPasswordWarning(oktaDomain: self.url, model:response)
            
        case .passwordExpired:
            return OktaAuthStatusPasswordExpired(oktaDomain: self.url, model:response)
            
        case .passwordReset:
            return OktaAuthStatusPasswordReset(oktaDomain: self.url, model:response)
            
        case .MFAEnroll:
            return OktaAuthStatusFactorEnroll(oktaDomain: self.url, model:response)
            
        case .MFAEnrollActivate:
            return OktaAuthStatusFactorEnrollActivate(oktaDomain: self.url, model:response)
            
        case .MFARequired:
            return OktaAuthStatusFactorRequired(oktaDomain: self.url, model:response)
            
        case .MFAChallenge:
            return OktaAuthStatusFactorChallenge(oktaDomain: self.url, model:response)
            
        case .lockedOut:
            return OktaAuthStatusLockedOut(oktaDomain: self.url, model:response)
            
        case .recovery:
            return OktaAuthStatusRecovery(oktaDomain: self.url, model:response)
            
        case .recoveryChallenge:
            return OktaAuthStatusRecoveryChallenge(oktaDomain: self.url, model:response)
            
        case .unauthenticated:
            throw OktaError.wrongState("Wrong state")
            
        default:
            throw OktaError.unknownState(response)
        }
    }
}
