//
//  Types.swift
//  OktaAuthNative iOS
//
//  Created by Alex Lebedev on 1/24/19.
//

import Foundation

public enum Factor {
    case securityQuestion
    case sms
    case call
    case TOTP
    case push
    case googleAuthenicator
    case RSASecurID
    case symantecVIP
    case yubiKey
    case duo
    case U2F
}

extension Factor {
    var description: String {
        switch self {
        case .securityQuestion:
            return "Security Question"
        case .sms:
            return "SMS"
        case .call:
            return "Call"
        case .TOTP:
            return "TOTP"
        case .push:
            return "Push"
        case .googleAuthenicator:
            return "Google Authenicator"
        case .RSASecurID:
            return "RSA Security ID"
        case .symantecVIP:
            return "Symantec VIP"
        case .yubiKey:
            return "YubiKey"
        case .duo:
            return "DUO"
        case .U2F:
            return "U2F"
        }
    }
}
