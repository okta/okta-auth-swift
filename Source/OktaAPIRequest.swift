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

    public init(baseURL: URL,
                urlSession: URLSession,
                completion: @escaping (OktaAPIRequest, Result) -> Void) {
        self.baseURL = baseURL
        self.urlSession = urlSession
        self.completion = completion
        decoder = JSONDecoder()
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSSZ"
        decoder.dateDecodingStrategy = .formatted(formatter)
    }

    public var method: Method = .post
    public var baseURL: URL
    public var path: String?
    public var urlParams: [String: String]?
    public var bodyParams: [String: Any]?
    public var additionalHeaders: [String: String]?

    public enum Method: String {
        case get, post, put, delete, options
    }

    public func buildRequest() -> URLRequest? {
        guard var components = URLComponents(url: baseURL, resolvingAgainstBaseURL: true) else {
            return nil
        }
        components.scheme = "https"
        if let path = path {
            components.path = path
        }
        components.queryItems = urlParams?.map { URLQueryItem(name: $0.key, value: $0.value) }
        guard let url = components.url else {
            return nil
        }

        var urlRequest = URLRequest(url: url, cachePolicy: .reloadIgnoringLocalAndRemoteCacheData, timeoutInterval: 60)
        urlRequest.httpMethod = method.rawValue.uppercased()
        urlRequest.setValue("application/json", forHTTPHeaderField: "Accept")
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue(buildUserAgent(), forHTTPHeaderField: "User-Agent")
        additionalHeaders?.forEach { urlRequest.setValue($0.value, forHTTPHeaderField: $0.key) }

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
    private var decoder: JSONDecoder
    private var completion: (OktaAPIRequest, Result) -> Void

    internal func handleResponse(data: Data?, response: HTTPURLResponse) {
        guard let data = data else {
            callCompletion(.error(.emptyServerResponse))
            return
        }
        guard 200 ..< 300 ~= response.statusCode else {
            do {
                let errorResponse = try decoder.decode(OktaAPIErrorResponse.self, from: data)
                callCompletion(.error(.serverRespondedWithError(errorResponse)))
            } catch let e {
                callCompletion(.error(.responseSerializationError(e)))
            }
            return
        }
        do {
            let successResponse = try decoder.decode(OktaAPISuccessResponse.self, from: data)
            callCompletion(.success(successResponse))
        } catch let e {
            callCompletion(.error(.responseSerializationError(e)))
        }
    }

    internal func handleResponseError(error: Error) {
        callCompletion(.error(.connectionError(error)))
    }

    internal func callCompletion(_ result: Result) {
        DispatchQueue.main.async {
            self.completion(self, result)
        }
    }
}
