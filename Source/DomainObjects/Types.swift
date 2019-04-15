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

public enum FactorType {
    case question
    case sms
    case call
    case TOTP
    case push
    case token
    case tokenHardware
    case web
    case u2f
    case email
    case unknown(String)
}

public extension FactorType {
    public init(raw: String) {
        switch raw {
        case "question":
            self = .question
        case "sms", "SMS":
            self = .sms
        case "token:software:totp":
            self = .TOTP
        case "push":
            self = .push
        case "token":
            self = .token
        case "token:hardware":
            self = .tokenHardware
        case "web":
            self = .web
        case "u2f":
            self = .u2f
        case "email", "EMAIL":
            self = .email
        default:
            self = .unknown(raw)
        }
    }
}

public extension FactorType {
    var rawValue: String {
        switch self {
        case .question:
            return "question"
        case .sms:
            return "sms"
        case .call:
            return "call"
        case .TOTP:
            return "token:software:totp"
        case .push:
            return "push"
        case .token:
            return "token"
        case .tokenHardware:
            return "Htoken:hardware"
        case .web:
            return "Web"
        case .u2f:
            return "u2f"
        case .email:
            return "email"
        case .unknown(_):
            return "unknown"
        }
    }
}

public extension FactorType {
    var description: String {
        switch self {
        case .question:
            return "Security Question"
        case .sms:
            return "SMS"
        case .call:
            return "Call"
        case .TOTP:
            return "TOTP"
        case .push:
            return "Push Notification"
        case .token:
            return "Token"
        case .tokenHardware:
            return "Hardware Token"
        case .web:
            return "Web"
        case .u2f:
            return "U2F"
        case .email:
            return "Email"
        case .unknown(_):
            return "unknown"
        }
    }
}

extension FactorType : Equatable {}

extension FactorType : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self = FactorType(raw: stringValue)
    }
}

public enum FactorProvider: String, Codable {
    case okta = "OKTA"
    case google = "GOOGLE"
    case rsa = "RSA"
    case symantec = "SYMANTEC"
    case yubico = "YUBICO"
    case duo = "DUO"
    case fido = "FIDO"
}

public extension FactorProvider {
    var description: String {
        switch self {
        case .okta:
            return "Okta"
        case .google:
            return "Google"
        case .rsa:
            return "RSA"
        case .symantec:
            return "Symantec"
        case .yubico:
            return "Yubico"
        case .duo:
            return "DUO"
        case .fido:
            return "FIDO"
        }
    }
}
