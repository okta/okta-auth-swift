//
//  OktaAPIRequest.swift
//  OktaAuth iOS
//
//  Created by Alex on 13 Dec 18.
//

import Foundation

/// Constructs and runs Okta API URL request

public class OktaAPIRequest {

    public enum Result {
        case success(OktaAPISuccessResponse)
        case error(OktaError)
    }

    public init(urlSession: URLSession, completion: @escaping (OktaAPIRequest, Result) -> Void) {
        self.urlSession = urlSession
        self.completion = completion
    }

    public var method: Method = .post
    public var baseURL: URL?
    public var path: String?
    public var urlParams: [String: String]?
    public var bodyParams: [String: Any]?

    public enum Method: String {
        case get, post, puth, delete, options
    }

    public func buildRequest() -> URLRequest? {
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

    public func run() {
        guard let urlRequest = buildRequest() else {
            completion(self, .error(.errorBuildingURLRequest))
            return
        }

        // `self` captured here to keep `OktaAPIRequest` retained until request is finished
        let task = urlSession.dataTask(with: urlRequest) { data, response, error in
            guard error == nil else {
                self.handleResponseError(error: error!)
                return
            }
            let response = response as! HTTPURLResponse
            self.handleResponse(data: data, response: response)
        }
        task.resume()
    }

    // MARK: - Private

    private var urlSession: URLSession
    private var completion: (OktaAPIRequest, Result) -> Void

    private func handleResponse(data: Data?, response: HTTPURLResponse) {
        guard let data = data else {
            callCompletion(.error(.emptyServerResponse))
            return
        }

        guard response.statusCode == 200 else {
            do {
                let errorResponse = try JSONDecoder().decode(OktaAPIErrorResponse.self, from: data)
                callCompletion(.error(.serverRespondedWithError(errorResponse)))
            } catch let e {
                callCompletion(.error(.responseSerializationError(e)))
            }
            return
        }

        do {
            let successResponse = try JSONDecoder().decode(OktaAPISuccessResponse.self, from: data)
            callCompletion(.success(successResponse))
        } catch let e {
            callCompletion(.error(.responseSerializationError(e)))
        }
    }

    private func handleResponseError(error: Error) {
        callCompletion(.error(.connectionError(error)))
    }

    private func callCompletion(_ result: Result) {
        DispatchQueue.main.async {
            self.completion(self, result)
        }
    }
}
