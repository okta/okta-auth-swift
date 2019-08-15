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
    init(raw: String) {
        switch raw {
        case "question":
            self = .question
        case "sms", "SMS":
            self = .sms
        case "token:software:totp":
            self = .TOTP
        case "call":
            self = .call
        case "push":
            self = .push
        case "token":
            self = .token
        case "token:hardware":
            self = .tokenHardware
        case "web", "Web":
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
            return "token:hardware"
        case .web:
            return "web"
        case .u2f:
            return "u2f"
        case .email:
            return "email"
        case .unknown(let raw):
            return raw
        }
    }
}

@available(swift, deprecated: 1.2, obsoleted: 2.0, message: "This will be removed in v2.0. Please use rawValue instead.")
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
        case .unknown(let raw):
            return raw
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

public enum FactorProvider {
    case okta
    case google
    case rsa
    case symantec
    case yubico
    case duo
    case fido
    case unknown(String)
}

public extension FactorProvider {
    init(raw: String) {
        switch raw {
        case "OKTA":
            self = .okta
        case "GOOGLE":
            self = .google
        case "RSA":
            self = .rsa
        case "SYMANTEC":
            self = .symantec
        case "YUBICO":
            self = .yubico
        case "DUO":
            self = .duo
        case "FIDO":
            self = .fido
        default:
            self = .unknown(raw)
        }
    }
}

public extension FactorProvider {
    var rawValue: String {
        switch self {
        case .okta:
            return "OKTA"
        case .google:
            return "GOOGLE"
        case .rsa:
            return "RSA"
        case .symantec:
            return "SYMANTEC"
        case .yubico:
            return "YUBICO"
        case .duo:
            return "DUO"
        case .fido:
            return "FIDO"
        case .unknown(let raw):
            return raw
        }
    }
}

extension FactorProvider : Equatable {}

extension FactorProvider : Codable {
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        try container.encode(self.rawValue)
    }
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let stringValue = try container.decode(String.self)
        self = FactorProvider(raw: stringValue)
    }
}

public enum OktaRecoveryFactors {
    case email
    case sms
    case call
}

public extension OktaRecoveryFactors {
    func toFactorType() -> FactorType {
        switch self {
        case .email:
            return .email
        case .sms:
            return .sms
        case .call:
            return .call
        }
    }
}
