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

open class OktaFactorOther : OktaFactor {

    public func sendRequest(with link: LinksResponse.Link,
                            keyValuePayload: Dictionary<String, Any>,
                            onStatusChange: @escaping (OktaAuthStatus) -> Void,
                            onError: @escaping (OktaError) -> Void) {
        self.restApi?.sendApiRequest(with: link,
                                     bodyParams: keyValuePayload,
                                     method: .post,
                                     completion: { result in
                                        self.handleServerResponse(response: result,
                                                                  onStatusChange: onStatusChange,
                                                                  onError: onError)
        })
    }

    // MARK: - Internal
    override init(factor: EmbeddedResponse.Factor,
                  stateToken:String,
                  verifyLink: LinksResponse.Link?,
                  activationLink: LinksResponse.Link?) {
        super.init(factor: factor, stateToken: stateToken, verifyLink: verifyLink, activationLink: activationLink)
    }
}
