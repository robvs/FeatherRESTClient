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


// MARK: - Protocols

/// type def that represents a json dictionary
public typealias Json = [String : Any]

/// type def that represents a json service response block.
public typealias JsonWebServiceResponseBlock<Model: Decodable> = (_ result: WebServiceResult<Model>) -> Void

/// Implemented by classes that make JSON web service calls.
public protocol JsonWebServiceable {
    
    /// Send a web service request where a JSON response is expected.
    func sendRequest<Model: Decodable>(_ webRequestData: WebServiceRequestData,
                                       completion: @escaping JsonWebServiceResponseBlock<Model>)
}


// MARK: - Class core

/// A `JsonWebServiceable` implementation that handles json-based services.
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
    
    /// Perform a web service request using the given endpoint information.
    /// - parameters:
    ///   - webRequestData: Information on the endpoint that we're about to hit.
    ///   - completion:     The block to be executed upon completion of the request.
    ///                     This block is guaranteed to be executed on the main queue
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
            
            // this is called when the web request completes.
            let dataTaskCompletion: (Data?, URLResponse?, Error?) -> Void = { (data, response, error) in
                if let error = error {
                    // TODO: log the error
                    print("\(#file) - \(#function) data task error: \(error.localizedDescription)")
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
    /// - parameters:
    ///   - webRequestData: The information upon which the created request is based.
    ///   - completion:     Block that is called upon completion.
    typealias CreateRequestResult = (request: URLRequest?, error: WebServiceError?)
    func createRequest(from webRequestData: WebServiceRequestData,
                       authorizationToken: String?) -> CreateRequestResult {
        
        // is the url path valid?
        guard let url = URL(string: webRequestData.path) else {
            // TODO: log the error
            return (request: nil, error: WebServiceError.urlPath)
        }
        
        // is the request body valid?
        var requestBody: Data? = nil
        if let json = webRequestData.body {
            if let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) {
                requestBody = jsonData
            }
            else {
                // TODO: log the error
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
            request.addValue(contentType, forHTTPHeaderField: WebServiceHeader.contentTypeKey)
        }
        
        if let accept = webRequestData.accept {
            request.addValue(accept, forHTTPHeaderField: WebServiceHeader.acceptKey)
        }
        
        switch webRequestData.authorization {
        case .none:
            break
        case .basicAuth:
            if let authorizationToken = authorizationToken {
                request.addValue(authorizationToken, forHTTPHeaderField: WebServiceHeader.apiTokenKey)
            }
            else {
                // This should theoretically never happen.
                assertionFailure("Authorization type \(webRequestData.authorization) requested, but token is nil.")
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
    /// - parameters:
    ///   - authorizationType: The type of authorization required by the request.
    ///   - completion:        Block that is called upon completion.
    func checkForValidAuthorization(ofType authorizationType: WebServiceAuthorizationType,
                                    completion: @escaping (AuthorizationTokenResult) -> Void) {
        
        switch authorizationType {
        case .none:
            completion((token: nil, error: nil))
        case .basicAuth:
            tokenManager.ensureValidToken(ofType: authorizationType, completion: completion)
        }
    }
    
    /// Handle the response data returned by a web service request. If there are no errors, convert
    /// the data to a json dictionary.
    /// - parameters:
    ///   - data:     The data returned by the web service request. Presumably json data.
    ///   - response: HTTP response data from the web service request.
    ///   - error:    Error reported by the web service.
    func handleRequestResponse<Model: Decodable>(_ data: Data?,
                                                 response: URLResponse?,
                                                 error: Error?) -> WebServiceResult<Model> {
        
        // check for request error
        if let error = error {
            // TODO: log the error
            print("\(#file) - \(#function) JsonWebService response error: \(error.localizedDescription)")
            return .failure(WebServiceError.urlSession(error: error))
        }
        
        // check for expected response object type
        guard let response = response as? HTTPURLResponse else {
            // TODO: log the error
            print("\(#file) - \(#function) JsonWebService response is not HTTPURLResponse")
            return .failure(WebServiceError.serverResponse)
        }
        
        // check for error response from server
        guard 200...299 ~= response.statusCode else {
            // TODO: log the error
            print("\(#file) - \(#function) JsonWebService response code is not 200. It is \(response.statusCode)")
            return .failure(WebServiceError.statusCode(code: response.statusCode))
        }
        
        // check for response data
        guard let data = data else {
            // The get request succeeded, but there was no response data. Treat it as success.
            return .success(nil)
        }
        
        // parse the response data into a model object.
        let decoder = JSONDecoder()
        do {
            let model = try decoder.decode(Model.self, from: data)
            return .success(model)
        }
        catch {
            // TODO: log the error
            if let decodingError = error as? DecodingError {
                print("\(#file) - \(#function) decode error: ", decodingError.detailedDescription)
            }
            else {
                print("\(#file) - \(#function) decode error: \(error.localizedDescription)")
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
        }
    }
}
