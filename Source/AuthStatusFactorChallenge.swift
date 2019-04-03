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

public class OktaAuthStatusFactorChallenge : OktaAuthStatus {

    init(oktaDomain: URL, model: OktaAPISuccessResponse) {
        super.init(oktaDomain: oktaDomain)
        self.model = model
        statusType = .MFAChallenge
    }

    public var factor: EmbeddedResponse.Factor? {
        get {
            return model?.embedded?.factor
        }
    }

    public var factorType: FactorType? {
        get {
            return model?.embedded?.factor?.factorType
        }
    }

    public func canResend() -> Bool {
        
        guard factor?.links?.resend?.first != nil else {
            return false
        }
        
        return true
    }

    public func canReturn() -> Bool {
        
        guard factor?.links?.prev != nil else {
            return false
        }
        
        return true
    }

    public func verifySmsChallenge(with code: String,
                                   onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                   onError: @escaping (_ error: OktaError) -> Void) {
        guard factor?.factorType != nil && factor!.factorType! == .sms else {
            onError(OktaError.factorNotAvailable(model!))
            return
        }

        self.verifyFactor(answer: nil,
                          passCode: code,
                          completion: { result in
                self.handleServerResponse(result,
                                          onStatusChanged: onStatusChange,
                                          onError: onError)
            })
    }

    public func verifyPushChallenge(with pollRate: TimeInterval = 3,
                                    onPushStateUpdate: @escaping (_ state: OktaAPISuccessResponse.FactorResult) -> Void,
                                    onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                    onError: @escaping (_ error: OktaError) -> Void) {
        guard factor?.factorType != nil && factor!.factorType! == .push else {
            onError(OktaError.factorNotAvailable(model!))
            return
        }

        guard let factorResult = model?.factorResult else {
            onError(.wrongState("Can't find 'factorResult' object in response"))
            return
        }

        onPushStateUpdate(factorResult)
        
        switch factorResult {
        case .waiting:
            let timer = Timer(timeInterval: pollRate, repeats: false) { [weak self] _ in
                self?.verifyFactor(answer: nil,
                                   passCode: nil,
                                   completion:
                    { [weak self] result in
                        var authResponse : OktaAPISuccessResponse
                        
                        switch result {
                        case .error(let error):
                            onError(error)
                            return
                        case .success(let success):
                            authResponse = success
                        }
                        
                        if authResponse.embedded?.factor?.factorType == .push {
                            self?.verifyPushChallenge(onPushStateUpdate: onPushStateUpdate,
                                                      onStatusChange: onStatusChange,
                                                      onError: onError)
                        } else {
                            self?.handleServerResponse(result,
                                                       onStatusChanged: onStatusChange,
                                                       onError: onError)
                        }
                })
            }
            RunLoop.main.add(timer, forMode: .common)
            factorResultPollTimer = timer
        default:
            break
        }
    }

    public func verifySecurityQuestionAnswer(answer: String,
                                             onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                             onError: @escaping (_ error: OktaError) -> Void) {
        guard factor?.factorType != nil && factor!.factorType! == .question else {
            onError(OktaError.factorNotAvailable(model!))
            return
        }
        
        self.verifyFactor(answer: answer,
                          passCode: nil,
                          completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }
    
    public func verifyTotpCode(totpCode: String,
                               onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                               onError: @escaping (_ error: OktaError) -> Void) {
        guard factor?.factorType != nil && factor!.factorType! == .TOTP else {
            onError(OktaError.factorNotAvailable(model!))
            return
        }

        self.verifyFactor(answer: nil,
                          passCode: totpCode,
                          completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void) {
        guard canResend() else {
            onError(.wrongState("Can't find 'resend' link in response"))
            return
        }

        self.api.perform(link: factor!.links!.resend!.first!,
                         stateToken: model!.stateToken!,
                         completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public func returnToPreviousStatus(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                       onError: @escaping (_ error: OktaError) -> Void) {
        guard canReturn() else {
            onError(.wrongState("Can't find 'prev' link in response"))
            return
        }
        
        self.api.perform(link: factor!.links!.prev!,
                         stateToken: model!.stateToken!,
                         completion: { result in
                            self.handleServerResponse(result,
                                                      onStatusChanged: onStatusChange,
                                                      onError: onError)
        })
    }

    public override func cancel(onSuccess: @escaping () -> Void,
                                onError: @escaping (OktaError) -> Void) {
        factorResultPollTimer?.invalidate()
        super.cancel(onSuccess: onSuccess, onError: onError)
    }

    internal var factorResultPollTimer: Timer? = nil

    func verifyFactor(answer: String?,
                      passCode: String?,
                      completion: ((OktaAPIRequest.Result) -> Void)? = nil) -> Void {
        if let link = factor!.links?.verify {
            self.api.verifyFactor(with: link,
                                  stateToken: model!.stateToken!,
                                  answer: nil,
                                  passCode: nil,
                                  rememberDevice: nil,
                                  autoPush: nil,
                                  completion: completion)
        } else {
            self.api.verifyFactor(factorId: factor!.id!,
                                  stateToken: model!.stateToken!,
                                  answer: nil,
                                  passCode: nil,
                                  rememberDevice: nil,
                                  autoPush: nil,
                                  completion: completion)
        }
    }
}
