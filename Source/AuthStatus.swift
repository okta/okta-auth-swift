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
    
    public func cancel(onSuccess: @escaping () -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        // implement
    }

    func handleServerResponse(_ response: OktaAPIRequest.Result,
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
        
        do {
            let status = try self.createAuthStatus(basedOn: authResponse, and: self)
            onStatusChanged(status)
        } catch let error as OktaError {
            onError(error)
        } catch {
            onError(OktaError.unexpectedResponse)
        }
    }

    func createAuthStatus(basedOn response: OktaAPISuccessResponse,
                          and previousStatus: OktaAuthStatus) throws -> OktaAuthStatus {
        
        guard let status = response.status else {
            throw OktaError.invalidResponse
        }
        
        switch status {
            
        case .success:
            return OktaAuthStatusSuccess(oktaDomain: previousStatus.url, model:response)
            
        case .passwordWarning:
            return OktaAuthStatusPasswordWarning(oktaDomain: previousStatus.url, model:response)
            
        case .passwordExpired:
            return OktaAuthStatusPasswordExpired(oktaDomain: previousStatus.url, model:response)
            
        case .passwordReset:
            return OktaAuthStatusPasswordReset(oktaDomain: previousStatus.url, model:response)
            
        case .MFAEnroll:
            return OktaAuthStatusMFAEnroll(oktaDomain: previousStatus.url, model:response)
            
        case .MFAEnrollActivate:
            return OktaAuthStatusMFAEnrollActivate(oktaDomain: previousStatus.url, model:response)
            
        case .MFARequired:
            return OktaAuthStatusFactorRequired(oktaDomain: previousStatus.url, model:response)
            
        case .MFAChallenge:
            return OktaAuthStatusFactorChallenge(oktaDomain: previousStatus.url, model:response)
            
        case .lockedOut:
            return OktaAuthStatusLockedOut(oktaDomain: previousStatus.url, model:response)
            
        case .recovery:
            return OktaAuthStatusRecovery(oktaDomain: previousStatus.url, model:response)
            
        case .recoveryChallenge:
            return OktaAuthStatusRecoveryChallenge(oktaDomain: previousStatus.url, model:response)
            
        case .unauthenticated:
            throw OktaError.wrongState("Wrong state")
            
        default:
            throw OktaError.unknownState(response)
        }
    }
}
