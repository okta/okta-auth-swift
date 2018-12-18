//
//  Utils.swift
//  OktaAuth iOS
//
//  Created by Alex on 18 Dec 18.
//

import Foundation

internal func buildUserAgent() -> String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "?"
    let device = "Device/\(deviceModel())"
    let string = "okta-auth-swift/\(version) \(device)"
    return string
}

internal func deviceModel() -> String {
    var system = utsname()
    uname(&system)
    let model = withUnsafePointer(to: &system.machine.0) { ptr in
        return String(cString: ptr)
    }
    return model
}
