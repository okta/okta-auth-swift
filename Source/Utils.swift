/*
 * Copyright (c) 2019, Okta, Inc. and/or its affiliates. All rights reserved.
 * The Okta software accompanied by this notice is provided pursuant to the Apache License, Version 2.0 (the "License.")
 *
 * You may obtain a copy of the License at http://www.apache.org/licenses/LICENSE-2.0.
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
 * WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 *
 * See the License for the specific language governing permissions and limitations under the License.
 */

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
