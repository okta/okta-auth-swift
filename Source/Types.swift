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
    case email = "EMAIL"
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
            return "EMAIL"
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

public enum FactorProfile: Codable {
    
    public struct Question: Codable {
        public let question: String
        public let questionText: String
        public let answer: String
        
        public init(question: String, questionText: String, answer: String) {
            self.question = question
            self.questionText = questionText
            self.answer = answer
        }
    }
    
    public struct SMS: Codable {
        public let phoneNumber: String
        
        public init(phoneNumber: String) {
            self.phoneNumber = phoneNumber
        }
    }
    
    public struct Call: Codable {
        public let phoneNumber: String
        public let phoneExtension: String?

        public init(phoneNumber: String, phoneExtension: String?) {
            self.phoneNumber = phoneNumber
            self.phoneExtension = phoneExtension
        }
    }
    
    public struct Token: Codable {
        public let credentialId: String
    }
    
    public struct Web: Codable {
        public let credentialId: String
    }
    
    public struct Email: Codable {
        public let email: String
    }
    
    case question(Question)
    case sms(SMS)
    case call(Call)
    case token(Token)
    case web(Web)
    case email(Email)
    
    public init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        if let question = try? container.decode(Question.self) {
            self = .question(question)
        } else if let sms = try? container.decode(SMS.self) {
            self = .sms(sms)
        } else if let call = try? container.decode(Call.self) {
            self = .call(call)
        } else if let token = try? container.decode(Token.self) {
            self = .token(token)
        } else if let web = try? container.decode(Web.self) {
            self = .web(web)
        } else if let email = try? container.decode(Email.self) {
            self = .email(email)
        } else {
            throw DecodingError.typeMismatch(
                FactorType.self,
                DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for MFA Factor Profile")
            )
        }
    }
    
    public func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .question(let question):
            try container.encode(question)
        case .sms(let sms):
            try container.encode(sms)
        case .call(let call):
            try container.encode(call)
        case .token(let token):
            try container.encode(token)
        case .web(let web):
            try container.encode(web)
        case .email(let email):
            try container.encode(email)
        }
    }
}
