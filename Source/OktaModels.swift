//
//  OktaModels.swift
//  OktaAuth iOS
//
//  Created by Alex on 13 Dec 18.
//

import Foundation

// OktaAPISuceess and OktaAPIError are models for REST API json responses

public struct OktaAPISuccessResponse: Codable {

    public private(set) var status: AuthStatus?
    public private(set) var stateToken: String?
    public private(set) var sessionToken: String?
    public private(set) var expirationDate: Date?
    public private(set) var relayState: String?
    public private(set) var factorResult: FactorResult?
    public private(set) var factorType: FactorType?
    public private(set) var embedded: EmbeddedResponse?
    public private(set) var links: LinksResponse?
    
    enum CodingKeys: String, CodingKey {
        case status
        case stateToken
        case sessionToken
        case expirationDate = "expiresAt"
        case relayState
        case factorResult
        case factorType
        case embedded = "_embedded"
        case links = "_links"
    }
}

public struct OktaAPIErrorResponse: Codable {
    public struct ErrorCause: Codable {
        var errorSummary: String?
    }

    var errorCode: String?
    var errorSummary: String?
    var errorLink: String?
    var errorId: String?
    var errorCauses: [ErrorCause]?
}

public struct LinksResponse: Codable {
    public struct Link: Codable {
        let href: URL
        let hints: [String:[String]]
    }
    
    let next: Link?
    let prev: Link?
    let cancel: Link?
    let skip: Link?
    let resend: Link?
}

public struct EmbeddedResponse: Codable {
    public let user: User?
    public let target: Target?
    public let policy: Policy?
    public let authentication: AuthenticationObject?
    public let factors: [Factor]?
    
    public struct Factor: Codable {
        public let id: String?
        public let factorType: String?
        public let provider: String?
        public let vendorName: String?
    }

    /// A subset of user properties published in an authentication or recovery transaction after the user successfully completes primary authentication.
    public struct User: Codable {
        
        /// Subset of profile properties for a user.
        public struct Profile: Codable {
            public let login: String?
            public let firstName: String?
            public let lastName: String?
            public let locale: String?
            public let timeZone: String?
        }
        
        /// User’s recovery question used for verification of a recovery transaction.
        public struct RecoveryQuestion: Codable {
            let question: String?
        }
        
        public let id: String?
        public let passwordChanged: Date?
        public let profile: Profile?
        public let recoveryQuestion: RecoveryQuestion?
        
        enum CodingKeys: String, CodingKey {
            case id
            case passwordChanged
            case profile
            case recoveryQuestion = "recovery_question"
        }
    }
    
    // Represents the target resource that user tried accessing. Typically this is the app that user is trying to sign-in.
    public struct Target: Codable {
        public let type: String?
        public let name: String?
        public let label: String?
        public let links: LinksResponse?
        
        enum CodingKeys: String, CodingKey {
            case type
            case name
            case label
            case links = "_links"
        }
    }
    
    // Represents the authentication details that the target resource is using.
    public struct AuthenticationObject: Codable {

        /// The protocol of authentication.
        public enum AuthProtocol: String, Codable {
            case saml_2_0 = "SAML2.0"
            case saml_1_1 = "SAML1.1"
            case ws_fed = "WS-FED"
        }
        
        /// The issuer that generates the assertion after the authentication finishes.
        public struct Issuer: Codable {
            public let id: String?
            public let name: String?
            public let uri: String?
        }
        
        public let authProtocol: AuthProtocol?
        public let issuer: Issuer?
        
        enum CodingKeys: String, CodingKey {
            case authProtocol = "protocol"
            case issuer
        }
    }
    
    public enum Policy: Codable {
        /// A subset of policy settings of the Sign-On Policy or App Sign-On Policy.
        public struct RememberDevice: Codable {
            public let allowRememberDevice: Bool?
            public let rememberDeviceByDefault: Bool?
            public let rememberDeviceLifetimeInMinutes: Int?
        }
        
        /// A subset of policy settings for the user’s assigned password policy.
        public struct Password: Codable {

            // Specifies the password age requirements of the assigned password policy.
            public struct PasswordExpiration: Codable {
                public let passwordExpireDays: Int?
            }
            
            /// Specifies the password complexity requirements of the assigned password policy.
            public struct PasswordComplexity: Codable {
                public let minLength: Int?
                public let minLowerCase: Int?
                public let minUpperCase: Int?
                public let minNumber: Int?
                public let minSymbol: Int?
                public let excludeUsername: Bool
            }

            public let expiration: PasswordExpiration?
            public let complexity: PasswordComplexity?
        }
    
        case rememberDevice(RememberDevice)
        case password(Password)
        
        public init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if let rememberDevice = try? container.decode(RememberDevice.self) {
                self = .rememberDevice(rememberDevice)
            } else if let password = try? container.decode(Password.self) {
                self = .password(password)
            } else {
                throw DecodingError.typeMismatch(
                    Policy.self,
                    DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Wrong type for Policy")
                )
            }
        }
        
        public func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .rememberDevice(let rememberDevice):
                try container.encode(rememberDevice)
            case .password(let password):
                try container.encode(password)
            }
        }
    }
}

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

// Provides additional context for the last factor verification attempt.
public enum FactorResult: String, Codable {
    case waiting = "WAITING"
    case cancelled = "CANCELLED"
    case timeout = "TIMEOUT"
    case timeWindowExceeded = "TIME_WINDOW_EXCEEDED"
    case passcodeReplayed = "PASSCODE_REPLAYED"
    case error = "ERROR"
}

public enum FactorType: String, Codable {
    case sms = "SMS"
    case email = "EMAIL"
}
