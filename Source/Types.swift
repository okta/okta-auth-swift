//
//  Types.swift
//  OktaAuthNative iOS
//
//  Created by Alex Lebedev on 1/24/19.
//

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
