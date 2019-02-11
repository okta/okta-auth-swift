//
//  Utils.swift
//  OktaAuth iOS
//
//  Created by Alex on 18 Dec 18.
//

import Foundation

#if os(iOS) || os(watchOS) || os(tvOS)
import UIKit
#endif

internal func buildUserAgent() -> String {
    let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") ?? "?"
    let device = "Device/\(deviceModel())"
    #if os(iOS)
    let os = "iOS/\(UIDevice.current.systemVersion)"
    #elseif os(watchOS)
    let os = "watchOS/\(UIDevice.current.systemVersion)"
    #elseif os(tvOS)
    let os = "tvOS/\(UIDevice.current.systemVersion)"
    #elseif os(macOS)
    let osVersion = ProcessInfo.processInfo.operatingSystemVersion
    let os = "macOS/\(osVersion.majorVersion).\(osVersion.minorVersion).\(osVersion.patchVersion)"
    #endif
    let string = "okta-auth-swift/\(version) \(os) \(device)"
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

internal extension Encodable {
    func toDictionary() -> [String: Any] {
        guard let data = try? JSONEncoder().encode(self),
            let object = try? JSONSerialization.jsonObject(with: data, options: .allowFragments),
            let dictionary = object as? [String: Any] else {
            return [:]
        }
        
        return dictionary
    }
}
