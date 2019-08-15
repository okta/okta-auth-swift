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

@testable import OktaAuthNative

enum TestResponse: String {
    case MFA_ENROLL_NotEnrolled = "MFA_ENROLL_NotEnrolled"
    case MFA_ENROLL_PartiallyEnrolled = "MFA_ENROLL_PartiallyEnrolled"
    case MFA_ENROLL_ACTIVATE_SMS = "MFA_ENROLL_ACTIVATE_SMS"
    case MFA_ENROLL_ACTIVATE_CALL = "MFA_ENROLL_ACTIVATE_CALL"
    case MFA_ENROLL_ACTIVATE_Push = "MFA_ENROLL_ACTIVATE_Push"
    case MFA_ENROLL_ACTIVATE_TOTP = "MFA_ENROLL_ACTIVATE_TOTP"
    case MFA_REQUIRED = "MFA_REQUIRED"
    case MFA_CHALLENGE_SMS = "MFA_CHALLENGE_SMS"
    case MFA_CHALLENGE_TOTP = "MFA_CHALLENGE_TOTP"
    case MFA_CHALLENGE_WAITING_PUSH = "MFA_CHALLENGE_WAITING_PUSH"
    case SUCCESS = "SUCCESS"
    case SUCCESS_UNLOCK = "SUCCESS_UNLOCK"
    case PASSWORD_WARNING = "PASSWORD_WARN"
    case PASSWORD_EXPIRED = "PASSWORD_EXPIRED"
    case PASSWORD_RESET = "PASSWORD_RESET"
    case LOCKED_OUT = "LOCKED_OUT"
    case RECOVERY = "RECOVERY"
    case RECOVERY_CHALLENGE_SMS = "RECOVERY_CHALLENGE_SMS"
    case RECOVERY_CHALLENGE_EMAIL = "RECOVERY_CHALLENGE_EMAIL"
    case Unknown_State_And_FactorResult = "Unknown_State_And_FactorResult"
    
    func data() -> Data? {
        guard let file = Bundle(for: OktaAPIMock.self).url(forResource: self.rawValue, withExtension: nil),
              let data = try? Data(contentsOf: file) else {
            return nil
        }
        
        return data
    }
    
    func parse() -> OktaAPISuccessResponse? {
        guard let data = data() else {
            return nil
        }
        
        let decoder = JSONDecoder()
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(formatter)

        return try? decoder.decode(OktaAPISuccessResponse.self, from: data)
    }
}
