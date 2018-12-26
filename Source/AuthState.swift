//
//  AuthState.swift
//  OktaAuth iOS
//
//  Created by Alex on 18 Dec 18.
//

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
    public init(raw: String) {
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

    public var description: String {
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
