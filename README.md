[<img src="https://devforum.okta.com/uploads/oktadev/original/1X/bf54a16b5fda189e4ad2706fb57cbb7a1e5b8deb.png" align="right" width="256px"/>](https://devforum.okta.com/)
[![CI Status](https://travis-ci.org/okta/okta-auth-swift.svg?branch=master)](https://travis-ci.org/okta/okta-auth-swift)
[![Carthage compatible](https://img.shields.io/badge/Carthage-compatible-4BC51D.svg?style=flat)](https://github.com/Carthage/Carthage)
[![Version](https://img.shields.io/cocoapods/v/OktaAuthSdk.svg?style=flat)](http://cocoapods.org/pods/OktaAuthSdk)
[![License](https://img.shields.io/cocoapods/l/OktaAuthSdk.svg?style=flat)](http://cocoapods.org/pods/OktaAuthSdk)
[![Platform](https://img.shields.io/cocoapods/p/OktaAuthSdk.svg?style=flat)](http://cocoapods.org/pods/OktaAuthSdk)
[![Swift](https://img.shields.io/badge/swift-4.2-orange.svg?style=flat)](https://developer.apple.com/swift/)

# Okta Swift Authentication SDK

The Okta Authentication SDK is a convenience wrapper around [Okta's Authentication API](https://developer.okta.com/docs/api/resources/authn.html).

* [Is This Library Right for Me?](#is-this-library-right-for-me)
* [Authentication State Machine](#authentication-state-machine)
* [Release status](#release-status)
* [Need help?](#need-help)
* [Getting started](#getting-started)
* [Usage guide](#usage-guide)
    * [Authenticate a User](#authenticate-a-user)
    * [Unlock account](#unlock-account)
    * [Forgot password](#forgot-password)
    * [Restore authentication or recover transaction with state token](#restore-authentication-or-recover-transaction-with-state-token)
* [API Reference - Status classes](#api-reference---status-classes)
    * [OktaAuthStatus](#oktaauthstatus)
    * [OktaAuthStatusFactorEnroll](#oktaauthstatusfactorenroll)
    * [OktaAuthStatusFactorEnrollActivate](#oktaauthstatusfactorenrollactivate)
    * [OktaAuthStatusFactorRequired](#oktaauthstatusfactorrequired)
    * [OktaAuthStatusFactorChallenge](#oktaauthstatusfactorchallenge)
    * [OktaAuthStatusPasswordExpired](#oktaauthstatuspasswordexpired)
    * [OktaAuthStatusPasswordWarning](#oktaauthstatuspasswordwarning)
    * [OktaAuthStatusRecoveryChallenge](#oktaauthstatusrecoverychallenge)
    * [OktaAuthStatusPasswordReset](#oktaauthstatuspasswordreset)
    * [OktaAuthStatusLockedOut](#oktaauthstatuslockedout)
* [API Reference - Factor classes](#api-reference---factor-classes)
    * [OktaFactorSms](#oktafactorsms)
    * [OktaFactorCall](#oktafactorcall)
    * [OktaFactorPush](#oktafactorpush)
    * [OktaFactorTotp](#oktafactortotp)
    * [OktaFactorQuestion](#oktafactorquestion)
    * [OktaFactorQuestion](#oktafactorquestion)
    * [OktaFactorToken](#oktafactortoken)
    * [OktaFactorOther](#oktafactorother)
* [SDK extension](#sdk-extension)
* [Contributing](#contributing)

## Is This Library Right for Me?

This SDK is a convenient wrapper for [Okta's Authentication API](https://developer.okta.com/docs/api/resources/authn/). These APIs are powerful and useful if you need to achieve one of these cases:

- You have an existing application that needs to accept primary credentials (username and password) and do custom logic before communicating with Okta.
- You have significantly custom authentication workflow or UI needs, such that Okta’s hosted sign-in page or [Sign-In Widget](https://github.com/okta/okta-signin-widget) do not give you enough flexibility.

The power of this SDK comes with more responsibility and maintenance: you will have to design your authentication workflow and UIs by hand, respond to all relevant states in Okta’s authentication state machine, and keep up to date with new features and states in Okta.

Otherwise, most applications can use the Okta hosted sign-in page or the Sign-in Widget. For these cases, you should use [Okta's OIDC SDK for iOS](https://github.com/okta/okta-oidc-ios) or other OIDC/OAuth 2.0 library.

## Authentication State Machine

Okta's Authentication API is built around a [state machine](https://developer.okta.com/docs/api/resources/authn#transaction-state). In order to use this library you will need to be familiar with the available states. You will need to implement a handler for each state you want to support.

![State Model Diagram](https://developer.okta.com/img/auth-state-model.png "State Model Diagram")

## Release status

This library uses semantic versioning and follows Okta's [library version policy](https://developer.okta.com/code/library-versions/).

| Version | Status                    |
| ------- | ------------------------- |
| 0.x | :warning: Retired |
| 1.x | :heavy_check_mark: Stable |

The latest release can always be found on the [releases page][github-releases].

## Need help?

If you run into problems using the SDK, you can

* Ask questions on the [Okta Developer Forums][devforum]
* Post [issues][github-issues] here on GitHub (for code errors)
* Check our [sample application](https://github.com/okta/samples-ios/tree/master/custom-sign-in)

## Prerequisites

If you do not already have a **Developer Edition Account**, you can create one at [https://developer.okta.com/signup/](https://developer.okta.com/signup/).

## Getting started

### CocoaPods
This SDK is available through [CocoaPods](http://cocoapods.org). To install it, simply add the following line to your Podfile:

```ruby
pod "OktaAuthSdk"
```

### Carthage
To integrate this SDK into your Xcode project using [Carthage](https://github.com/Carthage/Carthage), specify it in your Cartfile:
```ruby
github "okta/okta-auth-swift"
```

## Usage guide

The Authentication SDK helps you build the following flows using your own UI elements:
- Primary authentication - allows you to verify username and password credentials for a user.
- Multifactor authentication (MFA) - strengthens the security of password-based authentication by requiring additional verification of another factor such as a temporary one-time password or an SMS passcode. This SDK supports user enrollment with MFA factors enabled by the administrator, as well as MFA challenges based on your Okta Sign-On Policy.
- Unlock account - unlocks a user account if it has been locked out due to excessive failed login attempts. **This functionality is subject to the [security policy set by the administrator](https://www.okta.com/demo/password-policies)**.
- Recover password - allows users to securely reset their password if they've forgotten it. **This functionality is subject to the [security policy set by the administrator](https://www.okta.com/demo/password-policies/)**
- Restore authentication/unlock/recover transaction with the state token

To initiate a particular flow please make a call to one of the available functions in `OktaAuthSdk.swift`:
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

Please note that the closure `onStatusChange` returns `OktaAuthStatus` instance as a parameter. An instance of the `OktaAuthStatus` class represents the current status that is returned by the server. It's the developer's responsibilty to handle current status in order to proceed with the initiated flow. Check the status type by calling `status.statusType` and downcast to a concrete status class. Here is an example handler function:

```swift
func handleStatus(status: OktaAuthStatus) {

    switch status.statusType {
    case .success:
        let successState: OktaAuthStatusSuccess = status as! OktaAuthStatusSuccess
        handleSuccessStatus(successStatus: successStatus)

    case .passwordWarning:
        let warningPasswordStatus: OktaAuthStatusPasswordWarning = status as! OktaAuthStatusPasswordWarning
        handlePasswordWarning(passwordWarningStatus: warningPasswordStatus)

    case .passwordExpired:
        let expiredPasswordStatus: OktaAuthStatusPasswordExpired = status as! OktaAuthStatusPasswordExpired
        handleChangePassword(passwordExpiredStatus: expiredPasswordStatus)

    case .MFAEnroll:
        let mfaEnroll: OktaAuthStatusFactorEnroll = status as! OktaAuthStatusFactorEnroll
        handleEnrollment(enrollmentStatus: mfaEnrollStatus)

    case .MFAEnrollActivate:
        let mfaEnrollActivate: OktaAuthStatusFactorEnrollActivate = status as! OktaAuthStatusFactorEnrollActivate
        handleActivateEnrollment(enrollActivateStatus: mfaEnrollActivateStatus)

    case .MFARequired:
        let mfaRequired: OktaAuthStatusFactorRequired = status as! OktaAuthStatusFactorRequired
        handleFactorRequired(factorRequiredStatus: mfaRequiredStatus)

    case .MFAChallenge:
        let mfaChallenge: OktaAuthStatusFactorChallenge = status as! OktaAuthStatusFactorChallenge
        handleFactorChallenge(factorChallengeStatus: mfaChallengeStatus)

    case .recovery:
        let recovery: OktaAuthStatusRecovery = status as! OktaAuthStatusRecovery
        handleRecovery(recoveryStatus: recoveryStatus)

    case .recoveryChallenge:
        let recoveyChallengeStatus: OktaAuthStatusRecoveryChallenge = status as! OktaAuthStatusRecoveryChallenge
        handleRecoveryChallenge(recoveryChallengeStatus: recoveyChallengeStatus)

    case .passwordReset:
        let passwordResetStatus: OktaAuthStatuPasswordReset = status as! OktaAuthStatuPasswordReset
        handlePasswordReset(passwordResetStatus: passwordResetStatus)

    case .lockedOut:
        let lockedOutStatus: OktaAuthStatusLockedOut = status as! OktaAuthStatusLockedOut
        handleLockedOut(lockedOutStatus: lockedOutStatus)

    case .unauthenticated:
        let unauthenticatedStatus: OktaAuthUnauthenticated = status as! OktaAuthUnauthenticated
        handleUnauthenticated(unauthenticatedStatus: unauthenticatedStatus)
    }
}
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/AuthFlowCoordinator.swift#L41-L87)

### Authenticate a User

An authentication flow starts with a call to `authenticate` method:

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
Please refer to the [Primary Authentication](https://developer.okta.com/docs/api/resources/authn/#primary-authentication) section of API documentation for more information about this API request.
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/SignIn/SignInViewController.swift#L98-L108)

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
Please refer to the [Unlock Account](https://developer.okta.com/docs/api/resources/authn/#unlock-account) section of API documentation for more information about this API request.
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/SignIn/SignInViewController.swift#L67-L83)

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
Please refer to the [Forgot Password](https://developer.okta.com/docs/api/resources/authn/#forgot-password) section of API documentation for more information about this API request.
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/SignIn/SignInViewController.swift#L55-L65)

### Restore authentication or recover transaction with the state token

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
Please refer to the [Get Transaction State](https://developer.okta.com/docs/api/resources/authn/#get-transaction-state) section of API documentation for more information about this API request.

## API Reference - Status classes

Collection of status classes. Downcast the status instance to a status specific class to get access to status specific functions and properties.

### OktaAuthStatus

Base status class that implements some common functions for the statuses. Also contains `statusType` property that is used to check the actual status type.

#### canReturn

Returns `true` if current status can transition to the previous status.

```swift
open func canReturn() -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/AuthBaseViewController.swift#L39-L47)

#### [returnToPreviousStatus](https://developer.okta.com/docs/api/resources/authn/#previous-transaction-state)

Moves the current transaction state back to the previous state.

```swift
open func returnToPreviousStatus(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                                 onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/AuthBaseViewController.swift#L65-L71)

#### canCancel

Returns `true` if current flow can be cancelled.

```swift
open func canCancel() -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordManagementViewController.swift#L32-L33)

#### [cancel](https://developer.okta.com/docs/api/resources/authn/#previous-transaction-state)

Cancels the current transaction and revokes the state token.

```swift
open func cancel(onSuccess: (() -> Void)? = nil,
                 onError: ((_ error: OktaError) -> Void)? = nil)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/AuthBaseViewController.swift#L59)

### OktaAuthStatusUnauthenticated

This class is used to initiate authentication or recovery transactions.

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

### OktaAuthStatusSuccess

The transaction has completed successfully. Add a handler function to retrieve the session token.
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/UserProfile/UserProfileViewController.swift#L29-L51)

### OktaAuthStatusFactorEnroll

The user must select and enroll an available factor for additional verification. Add a handler function to enroll specific factor.

#### canEnrollFactor

Returns `true` if specific factor can be enrolled.

```swift
open func canEnrollFactor(factor: OktaFactor) -> Bool
```

#### canSkipEnrollment

Returns `true` if enrollment can be skipped.

```swift
open func canSkipEnrollment() -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/Enrollment/MFAEnrollmentViewController.swift#L30-L36)

#### [skipEnrollment](https://developer.okta.com/docs/api/resources/authn/#skip-transaction-state)

Skips the current transaction state and advance to the next state.

```swift
open func skipEnrollment(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/Enrollment/MFAEnrollmentViewController.swift#L41-L47)

#### [enrollFactor](https://developer.okta.com/docs/api/resources/authn/#enroll-factor)

Enrolls a user with a factor assigned by their MFA Policy.

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

Returns `true` if SDK can resend factor.

```swift
open func canResend(factor: OktaFactor) -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFASMSViewController.swift#L35)

#### [activateFactor](https://developer.okta.com/docs/api/resources/authn/#activate-factor)

Activates sms, call and token:software:totp factors to complete the enrollment process.

```swift
open func activateFactor(passCode: String?,
                         onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void)
```

#### resendFactor

Tries to resend activate request.

```swift
open func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFASMSViewController.swift#L58-L63)

### OktaAuthStatusFactorRequired

The user must provide additional verification with a previously enrolled factor.

#### selectFactor

Triggers the selected factor. Sends SMS/Call OTP or push notification to Okta Verify application.

```swift
open func selectFactor(_ factor: OktaFactor,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```

### OktaAuthStatusFactorChallenge

The user must verify the factor-specific challenge.

#### canVerify

Returns `true` if the SDK can verify challenge.

```swift
open func canVerify() -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFASMSViewController.swift#L30)

#### canResend

Returns `true` if the SDK can resend challenge for the selected factor.

```swift
open func canResend() -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFASMSViewController.swift#L29)

#### [verifyFactor](https://developer.okta.com/docs/api/resources/authn/#verify-factor)

Verifies an answer to a question factor or OTP code for SMS/Call/Totp/Token factors.

```swift
open func verifyFactor(passCode: String?,
                       answerToSecurityQuestion: String?,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```

#### resendFactor

Sends another OTP code or push notification if the user didn't receive the previous one due to timeout or error.

```swift
open func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFASMSViewController.swift#L50-L55)

### OktaAuthStatusPasswordExpired

The user's password was successfully validated but is expired.

### canChange

Returns `true` if password can be changed.

```swift
open func canChange() -> Bool
```

#### [changePassword](https://developer.okta.com/docs/api/resources/authn/#change-password)

Changes a user's password by providing the existing password and the new password.

```swift
open func changePassword(oldPassword: String,
                         newPassword: String,
                         onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordManagementViewController.swift#L42-L49)

### OktaAuthStatusPasswordWarning

The user's password was successfully validated but is about to expire and should be changed.

#### canChange

Returns `true` if password can be changed.

```swift
open func canChange() -> Bool
```

#### canSkip

Returns `true` if user may skip password change.

```swift
open func canSkip() -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordManagementViewController.swift#L29)

#### [changePassword](https://developer.okta.com/docs/api/resources/authn/#change-password)

Changes a user's password by providing the existing password and the new password.

```swift
open func changePassword(oldPassword: String,
                         newPassword: String,
                         onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                         onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordManagementViewController.swift#L52-L59)

#### [skipPasswordChange](https://developer.okta.com/docs/api/resources/authn/#skip-transaction-state)

Sends skip request to skip the password change state and advance to the next state.

```swift
open func skipPasswordChange(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                             onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordManagementViewController.swift#L66-L70)

### OktaAuthStatusRecovery

The user has requested a recovery token to reset their password or unlock their account.

#### canRecover

Returns `true` if recovery flow can be continued.

```swift
open func canRecover() -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordRecoveryViewController.swift#L29)

#### [recoverWithAnswer](https://developer.okta.com/docs/api/resources/authn/#answer-recovery-question)

Answers the user's recovery question

```swift
open func recoverWithAnswer(_ answer: String,
                            onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                            onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordRecoveryViewController.swift#L39-L47)

### OktaAuthStatusRecoveryChallenge

The user must verify the factor-specific recovery challenge.

#### canVerify

Returns `true` if the factor can be verified.

```swift
open func canVerify() -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordRecoveryChallengeViewController.swift#L38)

#### canResend

Returns `true` if the factor can be resent.

```swift
open func canResend() -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordRecoveryChallengeViewController.swift#L39)

#### [verifyFactor](https://developer.okta.com/docs/api/resources/authn/#verify-recovery-factor)

Verifies SMS/Call OTP(passCode) sent to the user's device for primary authentication for a recovery transaction.

```swift
open func verifyFactor(passCode: String,
                       onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordRecoveryChallengeViewController.swift#L55-L63)

#### [resendFactor](https://developer.okta.com/docs/api/resources/authn/#verify-sms-recovery-factor)

Resends SMS/Call OTP sent to the user's device for a recovery transaction.

```swift
open func resendFactor(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                       onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordRecoveryChallengeViewController.swift#L68-L74)

### OktaAuthStatusPasswordReset

The user successfully answered their recovery question and must set a new password.

#### canReset

Returns `true` if password can be reset.

```swift
open func canReset() -> Bool
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordResetViewController.swift#L29)

#### [resetPassword](https://developer.okta.com/docs/api/resources/authn/#reset-password)

Resets a user's password to complete a recovery transaction.

```swift
open func resetPassword(newPassword: String,
                        onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                        onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/PasswordManagement/PasswordResetViewController.swift#L38-L46)

### OktaAuthStatusLockedOut

The user account is locked; self-service unlock or administrator unlock is required.

#### canUnlock

Returns `true` if the user account can be unlocked.

```swift
open func canUnlock() -> Bool
```

#### [unlock](https://developer.okta.com/docs/api/resources/authn/#unlock-account)

Starts a new unlock recovery transaction for a given user and issues a recovery token that can be used to unlock a user's account.

```swift
open func unlock(username: String,
                 factorType: OktaRecoveryFactors,
                 onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                 onError: @escaping (_ error: OktaError) -> Void)
```

## API Reference - Factor classes

Collection of factor classes. Downcast the factor instance to a factor specific class to get access to factor specific functions and properties.

### OktaFactorSms

#### [enroll](https://developer.okta.com/docs/api/resources/authn/#enroll-okta-sms-factor)

Enrolls a user with the Okta SMS factor and an SMS profile. A text message with an OTP is sent to the device during enrollment.

```swift
public func enroll(phoneNumber: String?,
                   onStatusChange: @escaping (OktaAuthStatus) -> Void,
                   onError: @escaping (OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/Enrollment/MFAEnrollmentViewController.swift#L103-L117)

#### [activate](https://developer.okta.com/docs/api/resources/authn/#activate-sms-factor)

Activates an SMS factor by verifying the OTP.

```swift
public func activate(passCode: String?,
                     onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                     onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFASMSViewController.swift#L88-L98)

#### [select](https://developer.okta.com/docs/api/resources/authn/#verify-sms-factor)

Sends a new OTP to the device.

```swift
public func select(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                   onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFAViewController.swift#L65-L71)

#### [verify](https://developer.okta.com/docs/api/resources/authn/#verify-sms-factor)

Verifies an enrolled SMS factor by verifying the OTP.

```swift
public func verify(passCode: String?,
                   onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                   onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFASMSViewController.swift#L73-L84)

### OktaFactorCall

#### [enroll](https://developer.okta.com/docs/api/resources/authn/#enroll-okta-call-factor)

Enrolls a user with the Okta call factor and a Call profile. A voice call with an OTP is sent to the device during enrollment.

```swift
public func enroll(phoneNumber: String?,
                   onStatusChange: @escaping (OktaAuthStatus) -> Void,
                   onError: @escaping (OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/Enrollment/MFAEnrollmentViewController.swift#L103-L117)

#### [activate](https://developer.okta.com/docs/api/resources/authn/#activate-call-factor)

Activates a call factor by verifying the OTP.

```swift
public func activate(passCode: String?,
                     onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                     onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFASMSViewController.swift#L88-L98)

#### [select](https://developer.okta.com/docs/api/resources/authn/#verify-call-factor)

Sends a new OTP to the device.
```swift
public func select(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                   onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFAViewController.swift#L65-L71)

#### [verify](https://developer.okta.com/docs/api/resources/authn/#verify-call-factor)

Verifies an enrolled call factor by verifying the OTP.

```swift
public func verify(passCode: String?,
                   onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                   onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFASMSViewController.swift#L73-L84)

### OktaFactorPush

#### [enroll](https://developer.okta.com/docs/api/resources/authn/#enroll-okta-verify-push-factor)

Enrolls a user with the Okta verify push factor. The factor must be activated on the device by scanning the QR code or visiting the activation link sent via email or SMS.
Use the published activation links to embed the QR code or distribute an activation email or SMS.

```swift
public func enroll(onStatusChange: @escaping (OktaAuthStatus) -> Void,
                   onError: @escaping (OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/Enrollment/MFAEnrollmentViewController.swift#L125-L134)

#### [activate](https://developer.okta.com/docs/api/resources/authn/#activate-call-factor)

Activation of push factors are asynchronous and must be polled for completion when the factorResult returns a WAITING status.
Activations have a short lifetime (minutes) and will TIMEOUT if they are not completed before the `expireAt` timestamp. Restart the activation process if the activation is expired.

```swift
public func activate(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                     onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/Enrollment/MFActivatePushTotpViewController.swift#L48-L62)

#### checkFactorResult

After the push notification is sent to user's device we need to know when the user completes the activation/challenge.

```swift
public func checkFactorResult(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                              onError: @escaping (_ error: OktaError) -> Void)
```

Keep calling `checkFactorResult` function while `status.factorResult` value equals `.waiting`.
**NOTE** Don't call `checkFactorResult` function too often, keep polling interval within 3-5 seconds to not cause extra load on the server
Example of polling logic:
```swift
func handlePushChallenge(factor: OktaFactorPush) {
    factor.checkFactorResult(onStatusChange: { (status) in
        if status.factorResult == .waiting {
            DispatchQueue.main.asyncAfter(deadline:.now() + 5.0) {
                self.handlePushChallenge(factor: factor)
            }   
        } else {
            self.handleStatus(status: status)
        }
    }, onError: { (error) in
        self.handleError(error)
    })
}
```

#### [sendActivationLinkViaSms](https://developer.okta.com/docs/api/resources/authn/#activate-push-factor)

Sends an activation SMS when the user is unable to scan the QR code provided as part of an Okta Verify transaction. If for any reason the user can't scan the QR code, they can use the link provided in SMS to complete the transaction.

```swift
public func sendActivationLinkViaSms(with phoneNumber:String,
                                     onSuccess: @escaping () -> Void,
                                     onError: @escaping (_ error: OktaError) -> Void)
```

#### [sendActivationLinkViaEmail](https://developer.okta.com/docs/api/resources/authn/#activate-push-factor)

Sends an activation email when when the user is unable to scan the QR code provided as part of an Okta Verify transaction. If for any reason the user can't scan the QR code, they can use the link provided in email to complete the transaction.

```swift
public func sendActivationLinkViaEmail(onSuccess: @escaping () -> Void,
                                       onError: @escaping (_ error: OktaError) -> Void)
```

#### [select](https://developer.okta.com/docs/api/resources/authn/#verify-push-factor)

Sends an asynchronous push notification (challenge) to the device for the user to approve or reject.

```swift
public func select(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                   onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFAViewController.swift#L65-L71)

#### [verify](https://developer.okta.com/docs/api/resources/authn/#verify-push-factor)

Sends an asynchronous push notification (challenge) to the device for the user to approve or reject. The `factorResult` for the transaction will have a result of WAITING, SUCCESS, REJECTED, or TIMEOUT.

```swift
public func verify(onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                   onError: @escaping (_ error: OktaError) -> Void)
```

### OktaFactorTotp

#### [enroll](https://developer.okta.com/docs/api/resources/authn/#enroll-okta-verify-totp-factor)

Enrolls a user with the Okta token:software:totp factor.

```swift
public func enroll(onStatusChange: @escaping (OktaAuthStatus) -> Void,
                   onError: @escaping (OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/Enrollment/MFAEnrollmentViewController.swift#L139-L148)

#### [activate](https://developer.okta.com/docs/api/resources/authn/#activate-totp-factor)

Activates a token:software:totp factor by verifying the OTP (passcode).

```swift
public func activate(passCode: String,
                     onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                     onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/Enrollment/MFActivatePushTotpViewController.swift#L75-L90)

#### [select](https://developer.okta.com/docs/api/resources/authn/#verify-totp-factor)

Selects TOTP factor from the list of required factors and verifies the OTP (passcode).

```swift
public func select(passCode: String,
                   onStatusChange: @escaping (OktaAuthStatus) -> Void,
                   onError: @escaping (OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFAViewController.swift#L65-L71)

#### [verify](https://developer.okta.com/docs/api/resources/authn/#verify-totp-factor)

Verifies an OTP for a token:software:totp factor.

```swift
public func verify(passCode: String,
                   onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                   onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFATOTPViewController.swift#L39-L50)

### OktaFactorQuestion

#### [enroll](https://developer.okta.com/docs/api/resources/authn/#enroll-okta-security-question-factor)

Enrolls a user with the Okta question factor. List of security questions can be downloaded by `downloadSecurityQuestions` call.
**NOTE:** Security Question factor does not require activation and is ACTIVE after enrollment

```swift
public func enroll(questionId: String,
                   answer: String,
                   onStatusChange: @escaping (OktaAuthStatus) -> Void,
                   onError: @escaping (OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/Enrollment/MFAEnrollmentViewController.swift#L178-L190)

#### downloadSecurityQuestions

Downloads security questions for the user

```swift
public func downloadSecurityQuestions(onDownloadComplete: @escaping ([SecurityQuestion]) -> Void,
                                      onError: @escaping (_ error: OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/Enrollment/MFAEnrollmentViewController.swift#L154-L167)

#### [select](https://developer.okta.com/docs/api/resources/authn/#verify-security-question-factor)

Selects a question factor from the list of required factors and verifies the answer.

```swift
public func select(answerToSecurityQuestion: String,
                   onStatusChange: @escaping (OktaAuthStatus) -> Void,
                   onError: @escaping (OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFAViewController.swift#L65-L71)

#### [verify](https://developer.okta.com/docs/api/resources/authn/#verify-security-question-factor)

Verifies an answer to a question factor.

```swift
public func verify(answerToSecurityQuestion: String,
                   onStatusChange: @escaping (OktaAuthStatus) -> Void,
                   onError: @escaping (OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFASecurityQuestionViewController.swift#L36-L47)

### OktaFactorToken

#### [enroll](https://developer.okta.com/docs/api/resources/authn/#enroll-rsa-securid-factor)

Enrolls a user with a RSA SecurID factor and a token profile. RSA tokens must be verified with the current pin+passcode as part of the enrollment request.

```swift
public func enroll(credentialId: String,
                   passCode: String,
                   onStatusChange: @escaping (OktaAuthStatus) -> Void,
                   onError: @escaping (OktaError) -> Void)
```

#### select

Selects a token factor from the list of required factors and verifies the passcode.

```swift
public func select(passCode: String,
                   onStatusChange: @escaping (OktaAuthStatus) -> Void,
                   onError: @escaping (OktaError) -> Void)
```
Sample app [example](https://github.com/okta/samples-ios/blob/master/custom-sign-in/OktaNativeLogin/MFA/MFAViewController.swift#L65-L71)

#### verify

Verifies a passcode to a token factor.

```swift
public func verify(passCode: String,
                   onStatusChange: @escaping (_ newStatus: OktaAuthStatus) -> Void,
                   onError: @escaping (_ error: OktaError) -> Void)
```

### OktaFactorOther

SDK doesn't implement swift classes for all available factors. SDK returns `OktaFactorOther` instance for the non-implemented factors, e.g.: Google Authenticator, Symantec VIP Factor, U2F and etc. Use `OktaFactorOther` class to send arbitary data to the Okta server. For more information regarding payload please refer to the [API documentation](https://developer.okta.com/docs/api/resources/authn/#multifactor-authentication-operations)

#### sendRequest

Sends arbitrary `kayValuePayload` body in the https request.

```swift
public func sendRequest(with link: LinksResponse.Link,
                        keyValuePayload: Dictionary<String, Any>,
                        onStatusChange: @escaping (OktaAuthStatus) -> Void,
                        onError: @escaping (OktaError) -> Void)
```



## SDK Extension

You are open to subclass from any available status classes and add your custom implementation or extend with additional properties. In that case you have to also subclass from `OktaAuthStatusResponseHandler` class and override `handleServerResponse` or/and `createAuthStatus` methods.
This is useful in these situations:
- Okta added a new status in the state machine and you need to handle it
- You want to change status polling logic
- You created a class that is inherited from OktaAuthStatus* class

```swift
class MyResponseHandler: OktaAuthStatusResponseHandler {
    override func createAuthStatus(basedOn response: OktaAPISuccessResponse,
                                   and currentStatus: OktaAuthStatus) throws -> OktaAuthStatus {
        // implementation
    }
}

let unauthenticatedStatus = OktaAuthStatusUnauthenticated(oktaDomain: URL(string: "https://{yourOktaDomain}")!,
                                                          responseHandler: MyResponseHandler())
```

## Contributing

We're happy to accept contributions and PRs!

[devforum]: https://devforum.okta.com/
[github-issues]: https://github.com/okta/okta-auth-swift/issues
[github-releases]: https://github.com/okta/okta-auth-swift/releases
