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

import XCTest

@testable import OktaAuthNative

class TypesTests: XCTestCase {

    func testFactorType() {
        let factors: [FactorType] = [
            .question, .sms, .call, .TOTP, .push, .token, .tokenHardware, .web, .u2f, .email, .unknown("test")
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for factor in factors {
            do {
                let encodedData = try encoder.encode([factor])
                let decodedFactor = (try decoder.decode([FactorType].self, from: encodedData)).first

                XCTAssertEqual(factor, decodedFactor)
            } catch {
                XCTFail(error.localizedDescription)
                continue
            }
        }
    }

    func testFactorProvider() {
        let providers: [FactorProvider] = [
            .okta, .google, .rsa, .symantec, .yubico, .duo, .fido, .unknown("test")
        ]

        let encoder = JSONEncoder()
        let decoder = JSONDecoder()

        for provider in providers {
            do {
                let encodedData = try encoder.encode([provider])
                let decodedProvider = (try decoder.decode([FactorProvider].self, from: encodedData)).first

                XCTAssertEqual(provider, decodedProvider)
            } catch {
                XCTFail(error.localizedDescription)
                continue
            }
        }
    }

    func testOktaRecoveryFactors() {
        XCTAssertEqual(OktaRecoveryFactors.email.toFactorType(), FactorType.email)
        XCTAssertEqual(OktaRecoveryFactors.call.toFactorType(), FactorType.call)
        XCTAssertEqual(OktaRecoveryFactors.sms.toFactorType(), FactorType.sms)
    }
}
