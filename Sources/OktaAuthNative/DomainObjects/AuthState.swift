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

public enum AuthStatus {
    case unauthenticated
    case passwordWarning
    case passwordExpired
    case recovery
    case recoveryChallenge
    case passwordReset
    case lockedOut
    case MFAEnroll
    case MFAEnrollActivate
    case MFARequired
    case MFAChallenge
    case success
    case unknown(String)
}

public extension AuthStatus {
    init(raw: String) {
        switch raw {
        case "UNAUTHENTICATED":
            self = .unauthenticated
        case "PASSWORD_WARN":
            self = .passwordWarning
        case "PASSWORD_EXPIRED":
            self = .passwordExpired
        case "RECOVERY":
            self = .recovery
        case "RECOVERY_CHALLENGE":
            self = .recoveryChallenge
        case "PASSWORD_RESET":
            self = .passwordReset
        case "LOCKED_OUT":
            self = .lockedOut
        case "MFA_ENROLL":
            self = .MFAEnroll
        case "MFA_ENROLL_ACTIVATE":
            self = .MFAEnrollActivate
        case "MFA_REQUIRED":
            self = .MFARequired
        case "MFA_CHALLENGE":
            self = .MFAChallenge
        case "SUCCESS":
            self = .success
        default:
            self = .unknown(raw)
        }
    }
    
    var rawValue: String {
        switch self {
        case .unauthenticated:
            return "UNAUTHENTICATED"
        case .passwordWarning:
            return "PASSWORD_WARN"
        case .passwordExpired:
            return "PASSWORD_EXPIRED"
        case .recovery:
            return "RECOVERY"
        case .recoveryChallenge:
            return "RECOVERY_CHALLENGE"
        case .passwordReset:
            return "PASSWORD_RESET"
        case .lockedOut:
            return "LOCKED_OUT"
        case .MFAEnroll:
            return "MFA_ENROLL"
        case .MFAEnrollActivate:
            return "MFA_ENROLL_ACTIVATE"
        case .MFARequired:
            return "MFA_REQUIRED"
        case .MFAChallenge:
            return "MFA_CHALLENGE"
        case .success:
            return "SUCCESS"
        case .unknown(let raw):
            return raw
        }
    }

    @available(swift, deprecated: 1.2, obsoleted: 2.0, message: "This will be removed in v2.0. Please use rawValue instead.")
    var description: String {
        switch self {
        case .unauthenticated:
            return "Unauthenticated"
        case .passwordWarning:
            return "Password Warning"
        case .passwordExpired:
            return "Password Expired"
        case .recovery:
            return "Recovery"
        case .recoveryChallenge:
            return "Recovery Challenge"
        case .passwordReset:
            return "Password Reset"
        case .lockedOut:
            return "Locked Out"
        case .MFAEnroll:
            return "MFA Enroll"
        case .MFAEnrollActivate:
            return "MFA Enroll Activate"
        case .MFARequired:
            return "MFA Required"
        case .MFAChallenge:
            return "MFA Challenge"
        case .success:
            return "Success"
        case .unknown(let raw):
            return "Unknown (\(raw))"
        }
    }
}

extension AuthStatus : Equatable {}

extension AuthStatus : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self = AuthStatus(raw: stringValue)
    }
}
