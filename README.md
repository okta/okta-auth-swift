# Authentication SDK for Swift

> :warning: Beta alert! This library is in beta. See [release status](#release-status) for more information.

* [Release status](#release-status)
* [Need help?](#need-help)
* [Getting started](#getting-started)
* [Usage guide](#usage-guide)
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

## Usage guide

These examples will help you understand how to use this library.

Once you initialize a `AuthenticationClient`, you can call methods to make requests to the Okta Authentication API.

### Authenticate a User

An authentication flow usually starts with a call to `logIn`:

```swift
client.logIn(username: username, password: password)
```

The client must implement the [`AuthenticationClientDelegate`](https://github.com/okta/okta-auth-swift/blob/dev/Source/AuthenticationClient.swift) protocol. This protocol allows the client to provide handlers for each state that the Authentication API may return. (This prevents you from needing a huge switch statement after each response.)
 
## Contributing
 
We're happy to accept contributions and PRs!

[devforum]: https://devforum.okta.com/
[github-issues]: https://github.com/okta/okta-auth-swift/issues
[github-releases]: https://github.com/okta/okta-auth-swift/releases
