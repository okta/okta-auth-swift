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
