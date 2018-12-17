//
//  OktaAPIRequest.swift
//  OktaAuth iOS
//
//  Created by Alex on 13 Dec 18.
//

import Foundation

/// Constructs and runs Okta API URL request

class OktaAPIRequest {

    enum Result {
        case success(OktaAPISuccess)
        case error(APIRequestError)
    }

    enum APIRequestError: Error {
        case errorBuildingURLRequest
        case serverRespondedWithError(OktaAPIError)
    }

    init(urlSession: URLSession, completion: @escaping (OktaAPIRequest, Result) -> Void) {
        self.urlSession = urlSession
        self.completion = completion
    }

    var method: Method = .post
    var baseURL: URL?
    var path: String?
    var urlParams: [String: String]?
    var bodyParams: [String: Any]?

    enum Method: String {
        case get, post, puth, delete, options
    }

    func run() {
        guard let urlRequest = buildRequest() else {
            completion(self, .error(.errorBuildingURLRequest))
            return
        }
        let task = urlSession.dataTask(with: urlRequest) { data, response, error in

        }
        task.resume()
    }

    func buildRequest() -> URLRequest? {
        guard let baseURL = baseURL,
            let path = path,
            var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
                return nil
        }
        components.path = path
        components.queryItems = urlParams?.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else {
            return nil
        }

        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
        urlRequest.httpMethod = method.rawValue.uppercased()
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        if let bodyParams = bodyParams {
            guard let body = try? JSONSerialization.data(withJSONObject: bodyParams, options: []) else {
                return nil
            }
            urlRequest.httpBody = body
        }

        return urlRequest
    }

    // MARK: - Private

    private var urlSession: URLSession
    private var completion: (OktaAPIRequest, Result) -> Void


}
