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
        
        if let jsonData = JsonUtil.toData(model: self) {
            return jsonData
        }
        else {
            logger.fatal("Converting SimpleModel to json data failed. This shouldn't happen.")
            return Data()
        }
    }
}


// MARK: - JsonWebService helpers

struct JsonWebServiceTestUtil {
    
    static func resetSingleton(returnedData: Data?,
                               tokenUsername: String?,
                               headers: [String : String]? = nil,
                               dataTaskError: Error? = nil,
                               responseCode: Int = 200,
                               taskDelayMs: Int = 0) {
        
        let token = tokenUsername != nil ? createToken(withUsername: tokenUsername!) : nil
        let mockUrlSession   = MockURLSession(data: returnedData,
                                              headers: headers,
                                              error: dataTaskError,
                                              responseCode: responseCode,
                                              taskDelayMs: taskDelayMs)
        let mockTokenManager = MockWebServiceTokenManager(token: token, error: nil)
        let mockReachability = MockReachability(response: true)
        
        // ensure that this test doesn't make any real service calls or check the real reachability
        JsonWebService.resetSharedInstance(session: mockUrlSession,
                                           tokenManager: mockTokenManager,
                                           reachability: mockReachability)
    }
    
    static func createToken(withUsername username: String) -> String {
        
        let unencodedCore = """
{
    "uid": "3261b318-2cdf-4245-82e1-675b6ac3daf2",
    "un": "\(username)",
    "exp": 1549304270,
    "rls": [
        "Telehealth",
        "DeviceManagement",
        "ObserverAccess",
        "ViewEditor"
        ],
    "id": "241728b0-3ab1-4ec2-8559-4ed93ba0a008"
}
"""
        guard let encodedCore = unencodedCore.data(using: .utf8)?.base64EncodedString() else {
            return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9.eyJ1aWQiOiIzMjYxYjMxOC0yY2RmLTQyNDUtODJlMS02NzViNmFjM2RhZjI" +
                   "iLCJ1biI6Impva290by50ZXN0MyIsImV4cCI6MTU0OTMwNDI3MCwicmxzIjpbIlRlbGVoZWFsdGgiLCJEZXZpY2VNYW5hZ2V" +
                   "tZW50IiwiT2JzZXJ2ZXJBY2Nlc3MiLCJWaWV3RWRpdG9yIl0sImlkIjoiMjQxNzI4YjAtM2FiMS00ZWMyLTg1NTktNGVkOTN" +
                   "iYTBhMDA4In0.GtozfgXHk5rR4k9YVHChArqmUlv4GXuOl4VpguqrRys"
        }
        
        return "eyJ0eXAiOiJKV1QiLCJhbGciOiJIUzI1NiJ9." + encodedCore + ".GtozfgXHk5rR4k9YVHChArqmUlv4GXuOl4VpguqrRys"
    }
}


// MARK: - Implementation of WebServiceRequestData

struct WebServiceRequestInfo: WebServiceRequestData {
    
    var path: String
    var acceptHeaders: [String]
    var contentType: String?
    var customHeaders: [String : String]?
    var method: WebServiceRequestMethod
    var authorization: WebServiceAuthorizationType
    var body: Json?
}


// MARK: - Mock implementation of URLSessionManageable

class MockURLSession {
    
    var data: Data?
    let headers: [String : String]?
    var error: Error?
    var responseCode: Int
    var taskDelayMs: Int    // delay in milliseconds
    private (set) var resultingUrlRequest: URLRequest? = nil
    
    init(data: Data?, headers: [String : String]?, error: Error?, responseCode: Int = 200, taskDelayMs: Int = 0) {
        self.data = data
        self.headers = headers
        self.error = error
        self.responseCode = responseCode
        self.taskDelayMs = taskDelayMs
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
                                      headers: headers,
                                      error: error,
                                      delay: taskDelayMs,
                                      completion: completionHandler)
    }
}


// Mock data task used to override `resume()`, which is called in JsonWebService.sendRequest()
class MockURLSessionDataTask: URLSessionDataTask {
    
    let responseData: Data?
    let responseCode: Int
    let responseHeaders: [String : String]?
    let responseError: Error?
    let responseDelay: Int    // delay in milliseconds
    let sessionCompletionHandler: (Data?, URLResponse?, Error?) -> Void
    
    init(data: Data?, code: Int, headers: [String : String]?, error: Error?, delay: Int, completion: @escaping (Data?, URLResponse?, Error?) -> Void) {
        
        responseData = data
        responseCode = code
        responseHeaders = headers
        responseError = error
        responseDelay = delay
        sessionCompletionHandler = completion
    }
    
    override func resume() {
        
        let urlResponse = HTTPURLResponse(url: URL(fileURLWithPath:"http://something.com"),
                                          statusCode: responseCode,
                                          httpVersion: nil,
                                          headerFields: responseHeaders)
        
        // create local references to instance properties in case this instance goes out of scope
        // before the deadline.
        let completion = sessionCompletionHandler
        let data = responseData
        let error = responseError
        
        let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(responseDelay)
        DispatchQueue.main.asyncAfter(deadline: deadline) {
            completion(data, urlResponse, error)
        }
    }
}

// MARK: - Mock implementation of WebServiceTokenManageable

final class MockWebServiceTokenManager: WebServiceTokenManageable {
    
    private (set) var token: String?
    let error: Error?
    
    init(token: String?, error: Error?) {
        
        self.token = token
        self.error = error
    }
    
    var authTokenInfo: WebServiceAuthTokenInfo? {
        return decodeAuthToken(token)
    }
    
    func ensureValidToken(ofType tokenType: WebServiceAuthorizationType,
                          completion: @escaping (AuthorizationTokenResult) -> Void) {
        
        switch tokenType {
        case .none:
            completion((token: nil, error: nil))
        case .authToken:
            let tokenError: WebServiceError? = error != nil ? .token(error: error) : nil
            completion((token: token, error: tokenError))
        }
    }
    
    func clearAuthToken() {
        token = nil
    }
    
    private func decodeAuthToken(_ authToken: String?) -> WebServiceAuthTokenInfo? {
        
        guard let authToken = authToken else { return nil }
        
        let segments = authToken.components(separatedBy: ".")
        guard segments.count == 3 else { return nil }
        
        var base64String = segments[1]
        
        // add padding to the base64 string if necessary.
        if base64String.count % 4 != 0 {
            let padlen = 4 - base64String.count % 4
            base64String.append(contentsOf: repeatElement("=", count: padlen))
        }
        
        guard let tokenData = Data(base64Encoded: base64String) else { return nil }
        
        return JsonUtil.toModel(jsonData: tokenData)
    }

}


// MARK: - Mock implementation of ReachabilityCheckable

struct MockReachability: ReachabilityCheckable {
    
    let response: Bool
    
    func isConnected() -> Bool {
        
        return response
    }
}
