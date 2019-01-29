# Authentication SDK for Swift

> :warning: Beta alert! This library is in beta. See [release status](#release-status) for more information.

* [Release status](#release-status)
* [Need help?](#need-help)
* [Getting started](#getting-started)
* [Usage guide](#usage-guide)
* [API Reference](#api-reference)
    * [authenticate](#authenticate)
    * [cancel](#cancel)
    * [updateStatus](#updateStatus)
    * [changePassword](#changePassword)
    * [performLink](#performLink)
    * [resetStatus](#resetStatus)
    * [handleStatusChange](#handleStatusChange)
* [Contributing](#contributing)
 
The Okta Authentication SDK is a convenience wrapper around [Okta's Authentication API](https://developer.okta.com/docs/api/resources/authn.html).

**NOTE:** Using OAuth 2.0 or OpenID Connect to integrate your application instead of this library will require much less work, and has a smaller risk profile. Please see [this guide](https://developer.okta.com/use_cases/authentication/) to see if using this API is right for your use case.

Okta's Authentication API is built around a [state machine](https://developer.okta.com/docs/api/resources/authn#transaction-state). In order to use this library you will need to be familiar with the available states. You will need to implement a handler for each state you want to support.  

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
 
Okta is available through [CocoaPods](http://cocoapods.org). To install
it, simply add the following line to your Podfile:

```ruby
pod "OktaAuth"
```
 
Construct a client instance by passing it your Okta domain name and API token:
 
[//]: # (method: createClient)
```swift
let client = AuthenticationClient(oktaDomain: URL(string: "https://{yourOktaDomain}")!, delegate: self)
```
[//]: # (end: createClient)
 
Hard-coding the Okta domain works for quick tests, but for real projects you should use a more secure way of storing these values (such as environment variables). 

The client must implement the [`AuthenticationClientDelegate`](AuthenticationClientDelegate) protocol. 

## Usage guide

These examples will help you understand how to use this library.

Once you initialize a `AuthenticationClient`, you can call methods to make requests to the Okta Authentication API.

### Authenticate a User

An authentication flow usually starts with a call to `authenticate`:

```swift
client.authenticate(username: username, password: password)
```

### AuthenticationClientDelegate

This protocol allows the client to provide handlers for each state that the Authentication API may return. (This prevents you from needing a huge switch statement after each response.) Also delegate is used to resolve states requiring user input (e.g. reset password when user should be prompted to enter new password).

```swift
extension ViewController: AuthenticationClientDelegate {
    func handleSuccess(sessionToken: String) {
        // update UI accordingly
        presentAlert("Sign In Succeeded!")
    }

    func handleError(_ error: OktaError) {
        // update UI accordingly
        presentAlert("Sign In Failed!")
    }

    func handleChangePassword(canSkip: Bool, callback: @escaping (_ old: String?, _ new: String?, _ skip: Bool) -> Void) {
        // Ask user to enter old and new password, and resume flow by calling callback
        presentChangePasswordForm(
            canSkip: canSkip,
            completion: { oldPassword, newPassword, skip in
                callback(oldPassword, newPassword, false)
            }
            skip: {
                callback(nil, nil, true)
            }
        )
    }

    func handleMultifactorAuthenication(callback: @escaping (String) -> Void) {
        // Ask user to perform factor auth, enter auth code, and resume flow by calling callback
        presentMFAForm(){ code in
            guard let code = code else {
                self.client.cancel()
                return
            }
            
            callback(code)
        }
    }
    
    func transactionCancelled() {
        // Update UI accordingly
    }
}
```

## API Reference

### authenticate

Start the authorization flow by simply calling `authenticate` with user credentials. Use the [`handleStatusChange`](#handle-status-change) method to take more control over authorization flow.

```swift
    client.authenticate(username: username, password: password)
```

### cancel
To cancel authorization call `cancel`. It will cancel current transaction and reset auth status. 

```swift
    client.cancel()
```

### updateStatus

To update application auth status call `updateStatus`. This operation can be performed if  `stateToken` is available.

```swift
    client.updateStatus()
```

### changePassword

When auth state is `PASSWORD_WARN` or `PASSWORD_EXPIRED` user should be prompted to reset the password. To complete this operation call `changePassword`.

```swift
    client.changePassword(oldPassword: old, newPassword: new)
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
