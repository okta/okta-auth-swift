[<img src="https://devforum.okta.com/uploads/oktadev/original/1X/bf54a16b5fda189e4ad2706fb57cbb7a1e5b8deb.png" align="right" width="256px"/>](https://devforum.okta.com/)
[![CI Status](http://img.shields.io/travis/okta/okta-oidc-ios.svg?style=flat)](https://travis-ci.org/okta/okta-auth-swift)
[![Version](https://img.shields.io/cocoapods/v/OktaOidc.svg?style=flat)](http://cocoapods.org/pods/OktaAuthSdk)
[![License](https://img.shields.io/cocoapods/l/OktaOidc.svg?style=flat)](http://cocoapods.org/pods/OktaAuthSdk)
[![Platform](https://img.shields.io/cocoapods/p/OktaOidc.svg?style=flat)](http://cocoapods.org/pods/OktaAuthSdk)
[![Swift](https://img.shields.io/badge/swift-4.2-orange.svg?style=flat)](https://developer.apple.com/swift/)

# Authentication SDK for Swift

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
| 0.x     | :warning: Beta            |
 
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
- Restore authentication

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

### Restore authentication

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

Base status class that implements some common functions for the statuses.

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

### OktaAuthStatusFactorEnroll

### OktaAuthStatusFactorEnrollActivate

### OktaAuthStatusFactorRequired

### OktaAuthStatusFactorChallenge

### OktaAuthStatusPasswordExpired

### OktaAuthStatusPasswordWarning

### OktaAuthStatusRecovery

### OktaAuthStatusRecoveryChallenge

### OktaAuthStatusPasswordReset

### OktaAuthStatusLockedOut

## API Reference - Factor classes

### OktaFactorSms

### OktaFactorCall

### OktaFactorPush

### OktaFactorTotp

### OktaFactorQuestion

### OktaFactorToken

### OktaFactorOther






Start the authentication flow by simply calling `authenticate` with user credentials. Use the [`handleStatusChange`](#handle-status-change) method to take more control over authentication flow.

```swift
    client.authenticate(username: username, password: password)
```

### cancelTransaction
Call `cancelTransaction` to cancel active authentication flow. SDK will send cancel request and reset internal states upon completion. Use the  `transactionCancelled` delegate method to handle cancellation event. 

```swift
    client.cancelTransaction()
```

### fetchTransactionState

To retrieves the current transaction state for a state token call `fetchTransactionState`. Useful when user has state token only and wants to know details about current transaction state.

```swift
    client.fetchTransactionState()
```

### changePassword

When auth state is `PASSWORD_EXPIRED` user should be prompted to reset the password. In case of  `PASSWORD_WARN` state user also can be prompted to change their password (however there could be another flow). To complete this operation call `changePassword`.

```swift
    client.changePassword(oldPassword: old, newPassword: new)
```

### verify 

When auth state is `MFA_REQUIRED`  or  `MFA_CHALLENGE` user should be prompted to verify MFA factor. To complete this operation call `verify(factor:, passCode:, rememberDevice:, autoPush:)`. Also user can specify option to remember device or send push automatically (in case of `push` factor).

```swift
    client.verify(factor: factor,
        answer: "security question answer")

    client.verify(factor: factor,
        passCode: "user_passcode")
```

### performLink

If current auth state implies redirection to certain link, this can be implemented by calling `perform(link:)`. Note, you should use link from current auth state, in other case you can break consistency of current transaction. 

```swift
    perform(link: link)
```

### resetStatus

To reset current auth state and clear all the stored credentials call `resetStatus`.

```swift
    client.resetStatus()
```

### handleStatusChange

Default state machine implementation is described in `handleStatusChange`. Uses [`delegate`](#auth-client-delegate) to proceed auth flow if state requires user input.

Usually clients are not expected to call this method by their own. It is called when AuthenticationClient receives updated auth state. Method is used to handle every possible auth state and therefore proceed authentication transaction. 

Use the [`statusHandler`](#status-handler) property to provide custom implementation of state machine.

```swift
    client.handleStatusChange()
```

## Contributing
 
We're happy to accept contributions and PRs!

[devforum]: https://devforum.okta.com/
[github-issues]: https://github.com/okta/okta-auth-swift/issues
[github-releases]: https://github.com/okta/okta-auth-swift/releases
