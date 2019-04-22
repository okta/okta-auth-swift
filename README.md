[<img src="https://devforum.okta.com/uploads/oktadev/original/1X/bf54a16b5fda189e4ad2706fb57cbb7a1e5b8deb.png" align="right" width="256px"/>](https://devforum.okta.com/)
[![CI Status](http://img.shields.io/travis/okta/okta-auth-swift.svg?style=flat)](https://travis-ci.org/okta/okta-auth-swift)
[![Version](https://img.shields.io/cocoapods/v/OktaAuthSdk.svg?style=flat)](http://cocoapods.org/pods/OktaAuthSdk)
[![License](https://img.shields.io/cocoapods/l/OktaAuthSdk.svg?style=flat)](http://cocoapods.org/pods/OktaAuthSdk)
[![Platform](https://img.shields.io/cocoapods/p/OktaAuthSdk.svg?style=flat)](http://cocoapods.org/pods/OktaAuthSdk)
[![Swift](https://img.shields.io/badge/swift-4.2-orange.svg?style=flat)](https://developer.apple.com/swift/)

# Okta Swift Authentication SDK

* [Release status](#release-status)
* [Need help?](#need-help)
* [Getting started](#getting-started)
* [Usage guide](#usage-guide)
* [API Reference](#api-reference)
    * [authenticate](#authenticate)
    * [cancelTransaction](#cancelTransaction)
    * [fetchTransactionState](#fetchTransactionState)
    * [changePassword](#changePassword)
    * [verify](#verify)
    * [performLink](#performLink)
    * [resetStatus](#resetStatus)
    * [handleStatusChange](#handleStatusChange)
* [Contributing](#contributing)
 
The Okta Authentication SDK is a convenience wrapper around [Okta's Authentication API](https://developer.okta.com/docs/api/resources/authn.html).

**NOTE:** Using OAuth 2.0 or OpenID Connect to integrate your application instead of this library will require much less work, and has a smaller risk profile. Please see [this guide](https://developer.okta.com/use_cases/authentication/) to see if using this API is right for your use case.

![State Model Diagram](https://raw.githubusercontent.com/okta/okta.github.io/source/_source/_assets/img/auth-state-model.png "State Model Diagram")
 
## Release status

This library uses semantic versioning and follows Okta's [library version policy](https://developer.okta.com/code/library-versions/).

| Version | Status                    |
| ------- | ------------------------- |
| 0.x.0 | :warning: Retired |
| 1.x | :heavy_check_mark: Stable |
 
The latest release can always be found on the [releases page][github-releases].
 
## Need help?
 
If you run into problems using the SDK, you can
 
* Ask questions on the [Okta Developer Forums][devforum]
* Post [issues][github-issues] here on GitHub (for code errors)

## Prerequisites

If you do not already have a **Developer Edition Account**, you can create one at [https://developer.okta.com/signup/](https://developer.okta.com/signup/).
 
## Getting started
 
Okta is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "OktaAuthSdk"
```

## Usage guide

Okta's Authentication API is built around a [state machine](https://developer.okta.com/docs/api/resources/authn#transaction-state). In order to use this library you will need to be familiar with the available states. You will need to implement a handler for each state you want to support.

SDK implements the following flows:
- Authentication
- Unlock account
- Forgot password
- Restore authentication or recover transaction with state token

To initiate particular flow please make call to one of the available functions in `OktaAuthSdk.swift`:
```swift
// Authentication
public class func authenticate(with url: URL,
                               username: String,
                               password: String?,
                               onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                               onError: @escaping (_ error: OktaError) -> Void)

// Unlock account
public class func unlockAccount(with url: URL,
                                username: String,
                                factorType: OktaRecoveryFactors,
                                onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                onError: @escaping (_ error: OktaError) -> Void)

// Forgot password
public class func recoverPassword(with url: URL,
                                  username: String,
                                  factorType: OktaRecoveryFactors,
                                  onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                  onError: @escaping (_ error: OktaError) -> Void)

// Restore authentication
public class func fetchStatus(with stateToken: String,
                              using url: URL,
                              onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                              onError: @escaping (_ error: OktaError) -> Void)
```

Please note that closure `onStatusChange` returns `OktaAuthStatus` instance as a parameter. Instance of `OktaAuthStatus` class represents the current status that is returned by the server. It is developer's responsibilty to handle current status in order to proceed with the initiated flow. Please check the status type by calling `status.statusType` and downcast to concrete status class. Example of  handling function could the following:

```swift
func handleStatus(status: OktaAuthStatus) {

    self.currentStatus = status

    switch status.statusType {
    case .success:
        let successState: OktaAuthStatusSuccess = status as! OktaAuthStatusSuccess
        handleSuccessStatus(successStatus: successState)

    case .passwordWarning:
        let warningPasswordStatus: OktaAuthStatusPasswordWarning = status as! OktaAuthStatusPasswordWarning
        handlePasswordWarning(passwordWarningStatus: warningPasswordStatus)

    case .passwordExpired:
        let expiredPasswordStatus: OktaAuthStatusPasswordExpired = status as! OktaAuthStatusPasswordExpired
        handleChangePassword(passwordExpiredStatus: expiredPasswordStatus)

    case .MFAEnroll:
        let mfaEnroll: OktaAuthStatusFactorEnroll = status as! OktaAuthStatusFactorEnroll
        handleEnrollment(enrollmentStatus: mfaEnroll)

    case .MFAEnrollActivate:
        let mfaEnrollActivate: OktaAuthStatusFactorEnrollActivate = status as! OktaAuthStatusFactorEnrollActivate
        handleActivateEnrollment(enrollActivateStatus: mfaEnrollActivate)

    case .MFARequired:
        let mfaRequired: OktaAuthStatusFactorRequired = status as! OktaAuthStatusFactorRequired
        handleFactorRequired(factorRequiredStatus: mfaRequired)

    case .MFAChallenge:
        let mfaChallenge: OktaAuthStatusFactorChallenge = status as! OktaAuthStatusFactorChallenge
        handleFactorRequired(factorChallengeStatus: mfaChallenge)

    case .recovery:
        let recovery: OktaAuthStatusRecovery = status as! OktaAuthStatusRecovery
        handleFactorRequired(recoveryStatus: recovery)
    
    case .recoveryChallenge:
        let recoveyChallengeStatus: OktaAuthStatusRecoveryChallenge = status as! OktaAuthStatusRecoveryChallenge
        handleFactorRequired(recoveryChallengeStatus: recoveyChallengeStatus)
        
    case .passwordReset:
        let passwordResetStatus: OktaAuthStatuPasswordReset = status as! OktaAuthStatuPasswordReset
        handleFactorRequired(passwordResetStatus: passwordResetStatus)

    case .lockedOut:
        let lockedOutStatus: OktaAuthStatusLockedOut = status as! OktaAuthStatusLockedOut
        handleFactorRequired(lockedOutStatus: lockedOutStatus)

    case .unauthenticated:
        let unauthenticatedStatus: OktaAuthUnauthenticated = status as! OktaAuthUnauthenticated
        handleFactorRequired(unauthenticatedStatus: unauthenticatedStatus)
    }
}
```

### Authenticate a User

An authentication journey starts with a call to `authenticate`:

```swift
OktaAuthSdk.authenticate(with: URL(string: "https://{yourOktaDomain}")!,
                         username: "username",
                         password: "password",
                         onStatusChange: { authStatus in
                             handleStatus(status: authStatus)
},
                         onError: { error in
                             handleError(error)
})

```
Please refer to [Primary Authentication](https://developer.okta.com/docs/api/resources/authn/#primary-authentication) section of API documentation for more details behind that call.

### Unlock account

```swift
OktaAuthSdk.unlockAccount(with: URL(string: "https://{yourOktaDomain}")!,
                          username: "username",
                          factorType: .sms,
                          onStatusChange: { authStatus in
                              handleStatus(status: authStatus)
},
                          onError: { error in
                              handleError(error)
})
```
Please refer to [Unlock Account](https://developer.okta.com/docs/api/resources/authn/#unlock-account) section of API documentation for more details behind that call.

### Forgot password

```swift
OktaAuthSdk.recoverPassword(with: URL(string: "https://{yourOktaDomain}")!,
                            username: "username",
                            factorType: .sms,
                            onStatusChange: { authStatus in
                                handleStatus(status: authStatus)
},
                            onError: { error in
                                handleError(error)
})
```
Please refer to [Forgot Password](https://developer.okta.com/docs/api/resources/authn/#forgot-password) section of API documentation for more details behind that call.

### Restore authentication or recover transaction with state token

```swift
OktaAuthSdk.fetchStatus(with: "state_token",
                        using: URL(string: "https://{yourOktaDomain}")!,
                        onStatusChange: { authStatus in
                            handleStatus(status: authStatus)
},
                        onError: { error in
                            handleError(error)
})
```
Please refer to [Get Transaction State](https://developer.okta.com/docs/api/resources/authn/#get-transaction-state) section of API documentation for more details behind that call.

## API Reference - Status classes

### OktaAuthStatus class

Base status class that implements some common functions for the statuses. Please use `statusType` getter to check for the status type and perform downcast

#### canReturn

Returns `true` if current status can transit to the previous status 

```swift
open func canReturn() -> Bool
```

#### returnToPreviousStatus

Moves the current transaction state back to the previous state. [API link](https://developer.okta.com/docs/api/resources/authn/#previous-transaction-state)

```swift
open func returnToPreviousStatus(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                 onError: @escaping (_ error: OktaError) -> Void)
```

#### canCancel

Returns `true` if current flow can be cancelled

```swift
open func canCancel() -> Bool
```

#### cancel

Cancels the current transaction and revokes the state token.  [API link](https://developer.okta.com/docs/api/resources/authn/#previous-transaction-state)

```swift
open func cancel(onSuccess: (() -> Void)? = nil,
                 onError: ((_ error: OktaError) -> Void)? = nil)
```

### OktaAuthStatusUnauthenticated class

Class is used to initiate authentication or recovery transactions. You don't need to write handling function for that status.

```swift
open func authenticate(username: String,
                       password: String,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)

open func unlockAccount(username: String,
                        factorType: OktaRecoveryFactors,
                        onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                        onError: @escaping (_ error: OktaError) -> Void)

open func recoverPassword(username: String,
                          factorType: OktaRecoveryFactors,
                          onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                          onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusSuccess class

The transaction has completed successfully. Add handler function to retrieve session token

### OktaAuthStatusFactorEnroll

The user must select and enroll an available factor for additional verification. Add handler function to enroll specific factor

#### canEnrollFactor

Returns `true` if specific factor can be enrolled

```swift
open func canEnrollFactor(factor: OktaFactor) -> Bool
```

#### canSkipEnrollment

Returns `true` if enrollment can be skipped

```swift
open func canSkipEnrollment() -> Bool
```

#### skipEnrollment

Skips the current transaction state and advance to the next state. [API link](https://developer.okta.com/docs/api/resources/authn/#skip-transaction-state)

```swift
open func skipEnrollment(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void)
```

#### enrollFactor

Enrolls a user with a factor assigned by their MFA Policy.  [API link](https://developer.okta.com/docs/api/resources/authn/#enroll-factor)

```swift
open func enrollFactor(factor: OktaFactor,
                       questionId: String?,
                       answer: String?,
                       credentialId: String?,
                       passCode: String?,
                       phoneNumber: String?,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusFactorEnrollActivate

The user must activate the factor to complete enrollment.

#### canResend

Returns `true` if SDK can resend factor

```swift
open func canResend(factor: OktaFactor) -> Bool
```

#### activateFactor

Activates sms, call and token:software:totp factors to complete the enrollment process. [API link](https://developer.okta.com/docs/api/resources/authn/#activate-factor)

```swift
open func activateFactor(passCode: String?,
                         onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void,
                         onFactorStatusUpdate: ((_ state: OktaAPISuccessResponse.FactorResult) -> Void)? = nil)
```

#### resendFactor

Tries to resend activate request 

```swift
open func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusFactorRequired

The user must provide additional verification with a previously enrolled factor.

#### selectFactor

Triggers selected factor. Sends Sms/Call OTP or push notification to Okta Verify application 

```swift
open func selectFactor(_ factor: OktaFactor,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusFactorChallenge

The user must verify the factor-specific challenge.

#### canVerify

Returns `true` if SDK can verify challenge

```swift
open func canVerify() -> Bool
```

#### canResend

Returns `true` if SDK can resend challenge for the selected factor

```swift
open func canResend() -> Bool
```

#### verifyFactor

Verifies an answer to a question factor or OTP code for Sms/Call/Totp/Token factors.  [API link](https://developer.okta.com/docs/api/resources/authn/#verify-factor)

```swift
open func verifyFactor(passCode: String?,
                       answerToSecurityQuestion: String?,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void,
                       onFactorStatusUpdate: ((_ state: OktaAPISuccessResponse.FactorResult) -> Void)? = nil)
```

#### resendFactor

Sends another OTP code or push notification if the user didn't receive the previous one due to timeout or error.

```swift
open func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusPasswordExpired

The user's password was successfully validated but is expired.

### canChange

Returns `true` if password can be changed

```swift
open func canChange() -> Bool
```

#### changePassword

Changes a user's password by providing the existing password and the new password.  [API link](https://developer.okta.com/docs/api/resources/authn/#change-password)

```swift
open func changePassword(oldPassword: String,
                         newPassword: String,
                         onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusPasswordWarning

The user's password was successfully validated but is about to expire and should be changed.

#### canChange

Returns `true` if password can be changed

```swift
open func canChange() -> Bool
```

#### canSkip

Returns `true` if user may skip password change

```swift
open func canSkip() -> Bool
```

#### changePassword

Changes a user's password by providing the existing password and the new password.  [API link](https://developer.okta.com/docs/api/resources/authn/#change-password)

```swift
open func changePassword(oldPassword: String,
                         newPassword: String,
                         onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void)
```

#### skipPasswordChange

Changes a user's password by providing the existing password and the new password.  [API link](https://developer.okta.com/docs/api/resources/authn/#change-password)

```swift
open func skipPasswordChange(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusRecovery

The user has requested a recovery token to reset their password or unlock their account.

#### canRecover

Returns `true` if recovery flow can be continued

```swift
open func canRecover() -> Bool
```

#### recoverWithAnswer

Answers the user's recovery question. [API link](https://developer.okta.com/docs/api/resources/authn/#answer-recovery-question)

```swift
open func recoverWithAnswer(_ answer: String,
                            onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                            onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusRecoveryChallenge

The user must verify the factor-specific recovery challenge.

#### canVerify

Returns `true` if factor can be verified.

```swift
open func canVerify() -> Bool
```

#### canResend

Returns `true` if factor can be resent.

```swift
open func canResend() -> Bool
```

#### verifyFactor

Verifies Sms/Call OTP(passCode) sent to the user's device for primary authentication for a recovery transaction. [API link](https://developer.okta.com/docs/api/resources/authn/#verify-recovery-factor)

```swift
open func verifyFactor(passCode: String,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```

#### resendFactor

Resends Sms/Call OTP sent to the user's device for primary authentication for a recovery transaction. [API link](https://developer.okta.com/docs/api/resources/authn/#verify-sms-recovery-factor)

```swift
open func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusPasswordReset

The user successfully answered their recovery question and must to set a new password.

#### canReset

Returns `true` if password can be reset.

```swift
open func canReset() -> Bool
```

#### resetPassword

Resets a user's password to complete a recovery transaction. [API link](https://developer.okta.com/docs/api/resources/authn/#reset-password)

```swift
open func resetPassword(newPassword: String,
                        onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                        onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusLockedOut

The user account is locked; self-service unlock or administrator unlock is required.

#### canUnlock

Returns `true` if password can be reset.

```swift
open func canUnlock() -> Bool
```

#### unlock

Starts a new unlock recovery transaction for a given user and issues a recovery token that can be used to unlock a user's account. [API link](https://developer.okta.com/docs/api/resources/authn/#unlock-account)

```swift
open func unlock(username: String,
                 factorType: OktaRecoveryFactors,
                 onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                 onError: @escaping (_ error: OktaError) -> Void)
```

## API Reference - Factor classes

### OktaFactorSms

### OktaFactorCall

### OktaFactorPush

### OktaFactorTotp

### OktaFactorQuestion

### OktaFactorToken

### OktaFactorOther


## API Reference - Factor classes


## Contributing
 
We're happy to accept contributions and PRs!

[devforum]: https://devforum.okta.com/
[github-issues]: https://github.com/okta/okta-auth-swift/issues
[github-releases]: https://github.com/okta/okta-auth-swift/releases
