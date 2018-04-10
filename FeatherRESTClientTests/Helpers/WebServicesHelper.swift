//
//  WebServicesHelper.swift
//  FeatherRESTClientTests
//
//  Created by Rob Vander Sloot on 4/9/18.
//  Copyright © 2018 Random Visual, LLC. All rights reserved.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import Foundation


// MARK: - Simple model used for web service tests

struct SimpleModel: Codable {
    var value1: Int
    var value2: String
    
    func toJsonData() -> Data {
        
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(self)
            return jsonData
        }
        catch {
            assertionFailure("Converting SimpleModel to json data failed. This shouldn't happen.")
            return Data()
        }
    }
}


// MARK: - Implementation of WebServiceRequestData

struct WebServiceRequestInfo: WebServiceRequestData {
    
    var path: String
    var accept: String?
    var contentType: String?
    var customHeaders: [String : String]?
    var method: WebServiceRequestMethod
    var authorization: WebServiceAuthorizationType
    var body: Json?
}


// MARK: - Mock implementation of URLSessionManageable

class MockURLSession {
    
    var data: Data?
    var error: Error?
    var responseCode: Int
    private (set) var resultingUrlRequest: URLRequest? = nil
    
    init(data: Data?, error: Error?, responseCode: Int = 200) {
        self.data = data
        self.error = error
        self.responseCode = responseCode
        resultingUrlRequest = nil
    }
}

extension MockURLSession: URLSessionManageable {
    
    func invalidateAndCancel() {
        // do nothing
    }
    
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {
        
        resultingUrlRequest = request
        return MockURLSessionDataTask(data: data,
                                      code: responseCode,
                                      error: error,
                                      completionHandler: completionHandler)
    }
}


// Mock data task used to override `resume()`, which is called in JsonWebService.sendRequest()
class MockURLSessionDataTask: URLSessionDataTask {
    
    let responseData: Data?
    let responseCode: Int
    let responseError: Error?
    let sessionCompletionHandler: (Data?, URLResponse?, Error?) -> Void
    
    init(data: Data?, code: Int, error: Error?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        responseData = data
        responseCode = code
        responseError = error
        sessionCompletionHandler = completionHandler
    }
    
    override func resume() {
        let urlResponse = HTTPURLResponse(url: URL(fileURLWithPath:"http://something.com"),
                                          statusCode: responseCode,
                                          httpVersion: nil,
                                          headerFields: nil)
        sessionCompletionHandler(responseData, urlResponse, responseError)
    }
}


// MARK: - Mock implementation of WebServiceTokenManageable

struct MockWebServiceTokenManager: WebServiceTokenManageable {
    
    let token: String?
    let error: Error?
    
    func ensureValidToken(ofType tokenType: WebServiceAuthorizationType,
                          completion: @escaping (AuthorizationTokenResult) -> Void) {
        
        switch tokenType {
        case .none:
            completion((token: nil, error: nil))
        case .basicAuth:
            let tokenError: WebServiceError? = error != nil ? .token(error: error) : nil
            completion((token: token, error: tokenError))
        }
    }
}


// MARK: - Mock implementation of ReachabilityCheckable

struct MockReachability: ReachabilityCheckable {
    
    let response: Bool
    
    func isConnected() -> Bool {
        
        return response
    }
}
