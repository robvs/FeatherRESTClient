//
//  JsonWebService.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 2/23/18.
//  Copyright © 2018 Rob Vander Sloot.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import Foundation


// MARK: - Models & Protocols

/// Generic error model that is returned by the Admin Service.
public struct AdminServiceErrorModel: Codable {
    
    var requestPath: String
    var requestMethod: String
    var message: String?
    var statusCode: Int
}

/// type def that represents a json service response block.
public typealias JsonWebServiceResponseBlock<Model: Decodable> = (_ result: WebServiceResult<Model>) -> Void

/// Implemented by classes that make JSON web service calls.
public protocol JsonWebServiceable {
    
    /// The information stored in the authentication token (i.e. user id, user name, etc.).
    /// Returns nil if there is no auth token.
    var authTokenInfo: WebServiceAuthTokenInfo? { get }

    /// Send a web service request where a JSON response is expected.
    func sendRequest<Model: Decodable>(_ webRequestData: WebServiceRequestData,
                                       completion: @escaping JsonWebServiceResponseBlock<Model>)
}

/// Implemented by objects that can convert themselves to a JSON dictionary.
protocol JsonConvertable {
    
    func toJson() -> Json
}


// MARK: - Class core

/// A WebService implementation that handles json-based services.
final public class JsonWebService {
    
    /// Singleton
    /// This is initialized by resetSharedInstance(), which is expected to be called at startup.
    public private (set) static var shared: JsonWebService!
    
    private let session: URLSessionManageable
    private let tokenManager: WebServiceTokenManageable
    private let reachability: ReachabilityCheckable
    
    /// Injectable initializer.
    private init(session: URLSessionManageable,
                 tokenManager: WebServiceTokenManageable,
                 reachability: ReachabilityCheckable) {

        self.session      = session
        self.tokenManager = tokenManager
        self.reachability = reachability
    }

    /// Reset the singleton instance in order to enable injection for testing.
    static func resetSharedInstance(session: URLSessionManageable,
                                    tokenManager: WebServiceTokenManageable,
                                    reachability: ReachabilityCheckable) {
        
        shared = JsonWebService(session: session, tokenManager: tokenManager, reachability: reachability)
    }
    
    deinit {
        session.invalidateAndCancel()
    }
}


// MARK: - JsonWebServiceable conformance

extension JsonWebService: JsonWebServiceable {
    
    public var authTokenInfo: WebServiceAuthTokenInfo? { return tokenManager.authTokenInfo }
    
    /// Clear the auth token. e.g. log out the user.
    public func logOutUser() {
        
        tokenManager.clearAuthToken()
    }
    
    /// Perform a web service request using the given endpoint information.
    /// - parameter webRequest: Information on the endpoint that we're about to hit.
    /// - parameter completion: The block to be executed upon completion of the request.
    ///                         This block is guaranteed to be executed on the main queue
    public func sendRequest<Model: Decodable>(_ webRequestData: WebServiceRequestData,
                                              completion: @escaping (WebServiceResult<Model>) -> Void) {
        
        // if we're not connected to the internet, bail.
        guard reachability.isConnected() else {
            // ensure that the completion block is always executed on the main queue
            DispatchQueue.main.async {
                completion(WebServiceResult.failure(WebServiceError.noConnection))
            }
            return
        }
        
        // ensure that any required authorization tokens are current.
        checkForValidAuthorization(ofType: webRequestData.authorization)
        { [unowned self] (authorizationTokenResult) in  // unowned because this is a singleton class
            
            guard authorizationTokenResult.error == nil else {
                // ensure that the completion block is always executed on the main queue
                DispatchQueue.main.async {
                    completion(WebServiceResult.failure(authorizationTokenResult.error))
                }
                return
            }
            
            let createRequestResult = self.createRequest(from: webRequestData,
                                                         authorizationToken: authorizationTokenResult.token)
            guard let urlRequest = createRequestResult.request, createRequestResult.error == nil else {
                // ensure that the completion block is always executed on the main queue
                DispatchQueue.main.async {
                    completion(WebServiceResult.failure(createRequestResult.error))
                }
                return
            }
            
            let dataTaskCompletion: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
                if let error = error {
                    logger.trace("Data task error: \(error.localizedDescription)")
                }
                
                // ensure that the completion block is always executed on the main queue
                DispatchQueue.main.async {
                    let serviceResult: WebServiceResult<Model> = self.handleRequestResponse(data, response: response, error: error)
                    completion(serviceResult)
                }
            }
            
            // We're finally ready to make the web request.
            self.session.dataTask(with: urlRequest, completionHandler: dataTaskCompletion).resume()
        }
    }
}


// MARK: - Private helpers

private extension JsonWebService {
    
    /// Create a URLRequest object that is based on the information given in the webRequest.
    /// - parameter from:       The information upon which the created request is based.
    /// - parameter completion: Block that is called upon completion.
    typealias CreateRequestResult = (request: URLRequest?, error: WebServiceError?)
    func createRequest(from webRequestData: WebServiceRequestData,
                       authorizationToken: String?) -> CreateRequestResult {
        
        // is the url path valid?
        guard let url = URL(string: webRequestData.path) else {
            logger.error("Not a valid URL path: \(webRequestData.path)")
            return (request: nil, error: WebServiceError.urlPath)
        }
        
        // is the request body valid?
        var requestBody: Data? = nil
        if let json = webRequestData.body {
            if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) {
                requestBody = jsonData
            }
            else {
                logger.error("JSON could not be converted into a Data object.")
                return (request: nil, error: WebServiceError.unexpected)
            }
        }
        
        // assemble the request
        var request = URLRequest(url: url)
        request.httpMethod = webRequestData.method.rawValue
        request.httpBody = requestBody

        if let customHeaders = webRequestData.customHeaders {
            customHeaders.forEach{ (key, value) in request.addValue(value, forHTTPHeaderField: key) }
        }
        
        if let contentType = webRequestData.contentType {
            request.addValue(contentType, forHTTPHeaderField: WebServiceHeaderKey.contentType)
        }
        else {
            request.addValue("application/json", forHTTPHeaderField: WebServiceHeaderKey.contentType)
        }
        
        if webRequestData.acceptHeaders.count > 0 {
            webRequestData.acceptHeaders.forEach { (acceptHeader) in
                request.addValue(acceptHeader, forHTTPHeaderField: WebServiceHeaderKey.accept)
            }
        }
        else {
            request.addValue("application/json", forHTTPHeaderField: WebServiceHeaderKey.accept)
        }

        // add token to the header if needed.
        switch webRequestData.authorization {
        case .none:
            break
        case .authToken:
            if let authorizationToken = authorizationToken {
                let bearerToken = "Bearer \(authorizationToken)"
                request.addValue(bearerToken, forHTTPHeaderField: WebServiceHeaderKey.authorization)
            }
            else {
                // This should theoretically never happen.
                logger.fatal("Authorization type \(webRequestData.authorization) requested, but token is nil.")
            }
        }

        // Ignoring the default cache (from iOS, not our home grown cache) forces the network call.
        // Otherwise the iOS default is up to 24 hours.
        // http://nshipster.com/nsurlcache/
        // https://blackpixel.com/writing/2012/05/caching-and-nsurlconnection.html
        request.cachePolicy = .reloadIgnoringLocalCacheData   // Disable cached responses.
        
        return (request: request as URLRequest, error: nil)
    }
    
    /// Check that we are authorized to make the request. For api-token authorization, this
    /// will renew the token if necessary.
    /// - parameter authorizationType: The type of authorization required by the request.
    /// - parameter completion:        Block that is called upon completion.
    func checkForValidAuthorization(ofType authorizationType: WebServiceAuthorizationType,
                                    completion: @escaping (AuthorizationTokenResult) -> Void) {
        
        switch authorizationType {
        case .none:
            completion((token: nil, error: nil))
        case .authToken:
            tokenManager.ensureValidToken(ofType: authorizationType, completion: completion)
        }
    }
    
    /// Handle the response data returned by a web service request. If there are no errors, convert
    /// the data to a json dictionary.
    /// - parameter data:     The data returned by the web service request. Presumably json data.
    /// - parameter response: HTTP response data from the web service request.
    /// - parameter error:    Error reported by the web service.
    func handleRequestResponse<Model: Decodable>(_ data: Data?,
                                                 response: URLResponse?,
                                                 error: Error?) -> WebServiceResult<Model> {
        
        // check for request error
        if let error = error {
            logger.error("JsonWebService response error: \(error.localizedDescription)")
            return .failure(WebServiceError.urlSession(error: error))
        }
        
        // check for expected response object type
        guard let response = response as? HTTPURLResponse else {
            logger.error("JsonWebService response is not HTTPURLResponse")
            return .failure(WebServiceError.serverResponse)
        }
        
        // check for error response from server
        guard 200...299 ~= response.statusCode else {
            logger.error("JsonWebService response code is not 200. It is \(response.statusCode)")
            return .failure(WebServiceError.statusCode(code: response.statusCode))
        }
        
        // check for response data
        guard let data = data else {
            // The get request succeeded, but there was no response data. Treat it as success.
            return .success(nil)
        }
        
        // if the response data is csv text, decode it as a string.
        let contentType = response.allHeaderFields[WebServiceHeaderKey.contentType] as? String
        if let contentType = contentType,
            contentType == WebServiceHeader.textCsv,
            Model.self == String.self {
                return .success(String(bytes: data, encoding: .utf8) as? Model)
        }
        
        // the response data is expectd to be JSON. parse it into a model object.
        let decoder = JSONDecoder()
        do {
            let model = try decoder.decode(Model.self, from: data)
            return .success(model)
        }
        catch {
            if let decodingError = error as? DecodingError {
                logger.error("Decode error: " + decodingError.detailedDescription)
            }
            else {
                logger.error("Decode error: \(error.localizedDescription)")
            }
            return .failure(WebServiceError.responseData(error: error))
        }
    }
}


// MARK: - DecodingError extension

extension DecodingError {
    
    var detailedDescription: String {
        
        switch self {
        case .dataCorrupted(let context):
            return "Data corrupted: \(context.debugDescription)"
        case .keyNotFound(let codingKey, let context):
            return "Key not found: \(context.debugDescription) - codingKey: \(codingKey.stringValue)"
        case .typeMismatch(let type, let context):
            return "Type mismatch: \(type) - \(context.debugDescription)"
        case .valueNotFound(let type, let context):
            return "Value not found: \(type) - \(context.debugDescription)"
        @unknown default:
            logger.warn("Unhandled `DecodingError` type: \(self)")
            return "Unhandled DecodingError: \(self)"
        }
    }
}
