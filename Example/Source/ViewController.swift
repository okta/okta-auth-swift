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

import UIKit
import OktaAuthNative

class ViewController: UIViewController {

    override func viewDidLoad() {
        super.viewDidLoad()
    
        OktaAuthSdk.authenticate(with: URL(string: "http://rain-admin.okta1.com:1802")!,
                                 username: "ildar.abdullin@okta.com",
                                 password: "password",
                                 onStatusChange: { authStatus in
                                    self.handleStatus(status: authStatus)
        },
                                 onError: { error in
            
        })
    }

    func handleStatus(status: OktaAuthStatus) {
        switch status.statusType {
            
        case .success:
            let successState: OktaAuthStatusSuccess = status as! OktaAuthStatusSuccess
            let alert = UIAlertController(title: "Hooray!", message: "We are logged in \(successState.sessionToken!)", preferredStyle: .alert)
            alert.addAction(UIAlertAction(title: "OK", style: .default, handler: nil))
            self.present(alert, animated: true, completion: nil)

        case .unauthenticated:
            print("Unknown state")
            
        case .passwordWarning:
            print("Unknown state")
        
        case .passwordExpired:
            let expiredState: OktaAuthStatusPasswordExpired = status as! OktaAuthStatusPasswordExpired
            expiredState.changePassword(oldPassword: "aSd98300", newPassword: "I love my family 98300!", onStatusChange: { status in
                self.handleStatus(status: status)
            }, onError: { error in
                
            })
        
        case .recovery:
            print("Unknown state")
        
        case .recoveryChallenge:
            print("Unknown state")
        
        case .passwordReset:
            print("Unknown state")
        
        case .lockedOut:
            print("Unknown state")
        
        case .MFAEnroll:
            let mfaEnroll: OktaAuthStatusFactorEnroll = status as! OktaAuthStatusFactorEnroll
            
            if mfaEnroll.canSkipEnrollment() {
                mfaEnroll.skipEnrollment(onStatusChange: { status in
                    self.handleStatus(status: status)
                }) { error in
                    
                }
                return
            }
            
            let factors = mfaEnroll.availableFactors
            for factor in factors! {
                if factor.factorType! == .question {
                    mfaEnroll.enrollSecurityQuestionFactor(factor, questionId: "disliked_food", answer: "kasha", onStatusChange: { status in
                        self.handleStatus(status: status)
                    }) { error in
                        
                    }
                    return
                }
            }
        
        case .MFAEnrollActivate:
            print("Unknown state")
        
        case .MFARequired:
            let mfaRequired: OktaAuthStatusFactorRequired = status as! OktaAuthStatusFactorRequired
            let factors = mfaRequired.availableFactors
            for factor in factors! {
                if factor.factorType! == .question {
                    mfaRequired.selectFactor(factor: factor, onStatusChange: { status in
                        self.handleStatus(status: status)
                    }) { error in
                        
                    }
                    return
                }
            }
        
        case .MFAChallenge:
            let mfaChallenge: OktaAuthStatusFactorChallenge = status as! OktaAuthStatusFactorChallenge
            mfaChallenge.verifySecurityQuestionAnswer(answer: "kasha", onStatusChange: { status in
                self.handleStatus(status: status)
            }) { error in
                
            }
        
        case .unknown(_):
            print("Unknown state")
        }
    }
}
