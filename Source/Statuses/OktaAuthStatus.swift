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

    public internal(set) var restApi: OktaAPI

    public internal(set) var statusType : AuthStatus = .unknown("Unknown status")

    public internal(set) var model: OktaAPISuccessResponse

    public internal(set) var responseHandler: OktaAuthStatusResponseHandler

    public init(oktaDomain: URL,
                responseHandler: OktaAuthStatusResponseHandler = OktaAuthStatusResponseHandler()) {
        self.restApi = OktaAPI(oktaDomain: oktaDomain)
        self.model = OktaAPISuccessResponse()
        self.responseHandler = responseHandler
    }

    public init(currentState: OktaAuthStatus, model: OktaAPISuccessResponse) throws {
        self.model = model
        self.restApi = currentState.restApi
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

    public func canReturn() -> Bool {
        guard model.links?.prev != nil else {
            return false
        }
        
        return true
    }

    public func returnToPreviousStatus(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                       onError: @escaping (_ error: OktaError) -> Void) {
        guard canReturn() else {
            onError(.wrongStatus("Can't find 'prev' link in response"))
            return
        }

        guard let stateToken = model.stateToken else {
            onError(.invalidResponse)
            return
        }
        
        restApi.perform(link: model.links!.prev!,
                        stateToken: stateToken,
                        completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }
    
    public func canCancel() -> Bool {
        guard model.links?.cancel?.href != nil else {
            return false
        }

        return true
    }

    public func cancel(onSuccess: @escaping () -> Void,
                       onError: @escaping (_ error: OktaError) -> Void) {
        guard statusType != .unauthenticated else {
            return
        }
        guard canCancel() else {
            onError(.wrongStatus("Can't find 'cancel' link in response"))
            return
        }
        guard let stateToken = model.stateToken else {
            onError(.invalidResponse)
            return
        }

        let completion: ((OktaAPIRequest.Result) -> Void) = { result in
            switch result {
            case .error(let error):
                onError(error)
            case .success(_):
                self.cancelled = true
                onSuccess()
            }
        }

        restApi.cancelTransaction(with: model.links!.cancel!, stateToken: stateToken, completion: completion)
    }

    // MARK: Internal
    internal var cancelled = false

    func fetchStatus(with stateToken: String,
                     onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                     onError: @escaping (_ error: OktaError) -> Void) {
        
        restApi.getTransactionState(stateToken: stateToken, completion: { result in
            self.handleServerResponse(result,
                                      onStatusChanged: onStatusChange,
                                      onError: onError)
        })
    }

    func handleServerResponse(_ response: OktaAPIRequest.Result,
                              onStatusChanged: @escaping (_ newState: OktaAuthStatus) -> Void,
                              onError: @escaping (_ error: OktaError) -> Void) {
        if cancelled {
            return
        }

        responseHandler.handleServerResponse(response,
                                             currentStatus: self,
                                             onStatusChanged: onStatusChanged,
                                             onError: onError)
    }
}
