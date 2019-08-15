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

open class OktaAuthStatusResponseHandler {

    public init() {
    }

    open func handleServerResponse(_ response: OktaAPIRequest.Result,
                                   currentStatus: OktaAuthStatus,
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
            let status = try self.createAuthStatus(basedOn: authResponse, and: currentStatus)
            onStatusChanged(status)
        } catch let error as OktaError {
            onError(error)
        } catch {
            onError(OktaError.unexpectedResponse)
        }
    }
    
    open func createAuthStatus(basedOn response: OktaAPISuccessResponse,
                               and currentStatus: OktaAuthStatus) throws -> OktaAuthStatus {
        guard let statusType = response.status else {
            throw OktaError.invalidResponse
        }

        // create concrete status instance
        switch statusType {
            
        case .success:
            return try OktaAuthStatusSuccess(currentState: currentStatus, model: response)
            
        case .passwordWarning:
            return try OktaAuthStatusPasswordWarning(currentState: currentStatus, model: response)
            
        case .passwordExpired:
            return try OktaAuthStatusPasswordExpired(currentState: currentStatus, model: response)
            
        case .passwordReset:
            return try OktaAuthStatusPasswordReset(currentState: currentStatus, model: response)
            
        case .MFAEnroll:
            return try OktaAuthStatusFactorEnroll(currentState: currentStatus, model: response)
            
        case .MFAEnrollActivate:
            return try OktaAuthStatusFactorEnrollActivate(currentState: currentStatus, model: response)
            
        case .MFARequired:
            return try OktaAuthStatusFactorRequired(currentState: currentStatus, model: response)
            
        case .MFAChallenge:
            return try OktaAuthStatusFactorChallenge(currentState: currentStatus, model: response)
            
        case .lockedOut:
            return try OktaAuthStatusLockedOut(currentState: currentStatus, model: response)
            
        case .recovery:
            return try OktaAuthStatusRecovery(currentState: currentStatus, model: response)
            
        case .recoveryChallenge:
            return try OktaAuthStatusRecoveryChallenge(currentState: currentStatus, model: response)
            
        case .unauthenticated:
            throw OktaError.wrongStatus("Wrong state")
            
        default:
            throw OktaError.unknownStatus(response)
        }
    }
}
