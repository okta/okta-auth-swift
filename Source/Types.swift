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

public enum FactorType: String, Codable {
    case question = "question"
    case sms = "sms"
    case call = "call"
    case TOTP = "token:software:totp"
    case push = "push"
    case token = "token"
    case tokenHardware = "token:hardware"
    case web = "web"
    case u2f = "u2f"
    case email = "email"
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
        }
    }
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
