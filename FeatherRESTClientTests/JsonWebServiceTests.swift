//
//  JsonWebServiceTests.swift
//  FeatherRESTClientTests
//
//  Created by Rob Vander Sloot on 4/9/18.
//  Copyright © 2018 Random Visual, LLC. All rights reserved.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import XCTest

class JsonWebServiceTests: XCTestCase {

    let expectedAuthToken = "auth-token"
    
    // mock object that are expected to be initialized by each test that uses them.
    var mockSession:      MockURLSession!             = nil
    var mockTokenManager: MockWebServiceTokenManager! = nil
    var mockReachability: MockReachability!           = nil

    
    override func setUp() {
        super.setUp()
        
        // set to nil to ensure that each test reinitializes them.
        mockSession      = nil
        mockTokenManager = nil
        mockReachability = nil
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_sendRequest_getMethod() {
        testRequestMethod(.get)
    }
    
    func test_sendRequest_postMethod() {
        testRequestMethod(.post)
    }
    
    func test_sendRequest_putMethod() {
        testRequestMethod(.put)
    }
    
    func test_sendRequest_noAuthorization() {
        testAuthorization(.none)
    }
    
    func test_sendRequest_authTokenAuthorization() {
        testAuthorization(.authToken)
    }

    func test_sendRequest_noErrors() {
        
        // setup
        
        // inject mock data into the JsonWebService instance
        let expectedModel = SimpleModel(value1: 411, value2: "Starlord")
        resetJsonWebService(returnedData: expectedModel.toJsonData(), dataTaskError: nil, tokenError: nil, isConnected: true)
        
        let requestData = createRequestInfo(method: .get, authorization: .none)
        let expectation = self.expectation(description: "async_test")


        // execute
        JsonWebService.shared.sendRequest(requestData) { (serviceResult: WebServiceResult<SimpleModel>) in
            
            // validate
            switch serviceResult {
            case .success(let actualModel):
                XCTAssertEqual(actualModel?.value1, expectedModel.value1)
                XCTAssertEqual(actualModel?.value2, expectedModel.value2)
            case .failure(let error):
                XCTFail("Expected success, but received failure with error: \(error?.localizedDescription ?? "none")")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_sendRequest_sessionDataTaskError() {
        
        // setup
        
        // inject mock data into the JsonWebService instance
        let baseError     = createError(with: "error message")
        let expectedError = WebServiceError.urlSession(error: baseError)
        let model         = SimpleModel(value1: 411, value2: "Starlord")
        resetJsonWebService(returnedData: model.toJsonData(), dataTaskError: baseError, tokenError: nil, isConnected: true)

        let requestData = createRequestInfo(method: .get, authorization: .none)
        let expectation = self.expectation(description: "async_test")

        
        // execute
        JsonWebService.shared.sendRequest(requestData) { (serviceResult: WebServiceResult<SimpleModel>) in
            
            // validate
            switch serviceResult {
            case .success(let actualModel):
                XCTFail("Expected failure, but was successful with model: \(String(describing: actualModel))")
            case .failure(let actualError):
                XCTAssertEqual(actualError, expectedError)
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_sendRequest_tokenError() {
        
        // setup
        
        // inject mock data into the JsonWebService instance
        let baseError     = createError(with: "error message")
        let expectedError = WebServiceError.token(error: baseError)
        let model         = SimpleModel(value1: 411, value2: "Starlord")
        resetJsonWebService(returnedData: model.toJsonData(), dataTaskError: nil, tokenError: baseError, isConnected: true)
        
        let requestData = createRequestInfo(method: .get, authorization: .authToken)
        let expectation = self.expectation(description: "async_test")

        
        // execute
        JsonWebService.shared.sendRequest(requestData) { (serviceResult: WebServiceResult<SimpleModel>) in
            
            // validate
            switch serviceResult {
            case .success(let actualModel):
                XCTFail("Expected failure, but was successful with model: \(String(describing: actualModel))")
            case .failure(let actualError):
                XCTAssertEqual(actualError, expectedError)
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_sendRequest_noConnection() {
        
        // setup
        
        // inject mock data into the JsonWebService instance
        let model = SimpleModel(value1: 411, value2: "Starlord")
        resetJsonWebService(returnedData: model.toJsonData(), dataTaskError: nil, tokenError: nil, isConnected: false)
        
        let requestData = createRequestInfo(method: .get, authorization: .none)
        let expectation = self.expectation(description: "async_test")

        
        // execute
        JsonWebService.shared.sendRequest(requestData) { (serviceResult: WebServiceResult<SimpleModel>) in
            
            // validate
            switch serviceResult {
            case .success(let actualModel):
                XCTFail("Expected failure, but was successful with model: \(String(describing: actualModel))")
            case .failure(let error):
                XCTAssertEqual(error, WebServiceError.noConnection)
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_sendRequest_invalidUrl() {
        
        // setup
        
        // inject mock data into the JsonWebService instance
        let model = SimpleModel(value1: 411, value2: "Starlord")
        resetJsonWebService(returnedData: model.toJsonData(), dataTaskError: nil, tokenError: nil, isConnected: true)
        
        let requestData = WebServiceRequestInfo(path: "bad url string",
                                                acceptHeaders: [],
                                                contentType: nil,
                                                customHeaders: nil,
                                                method: .get,
                                                authorization: .none,
                                                body: nil)

        let expectation = self.expectation(description: "async_test")
        
        
        // execute
        JsonWebService.shared.sendRequest(requestData) { (serviceResult: WebServiceResult<SimpleModel>) in
            
            // validate
            switch serviceResult {
            case .success(let actualModel):
                XCTFail("Expected failure, but was successful with model: \(String(describing: actualModel))")
            case .failure(let actualError):
                XCTAssertEqual(actualError, WebServiceError.urlPath)
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_sendRequest_invalidResponseCode() {
        
        // setup
        
        // inject mock data into the JsonWebService instance
        let expectedResponseCode = 404
        let model = SimpleModel(value1: 411, value2: "Starlord")
        resetJsonWebService(returnedData: model.toJsonData(), dataTaskError: nil, tokenError: nil, isConnected: true)
        mockSession.responseCode = expectedResponseCode
        
        let requestData = createRequestInfo(method: .get, authorization: .none)
        let expectation = self.expectation(description: "async_test")
        
        
        // execute
        JsonWebService.shared.sendRequest(requestData) { (serviceResult: WebServiceResult<SimpleModel>) in
            
            // validate
            switch serviceResult {
            case .success(let actualModel):
                XCTFail("Expected failure, but was successful with model: \(String(describing: actualModel))")
            case .failure(let actualError):
                if let actualError = actualError, case .statusCode(let actualCode) = actualError {
                    XCTAssertEqual(actualCode, expectedResponseCode)
                }
                else {
                    let actualErrorDescription = actualError?.localizedDescription ?? "none"
                    XCTFail("Expected status code error \(expectedResponseCode), but received error: \(actualErrorDescription)")
                }
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }

    func test_sendRequest_invalidResponseDataFormat() {
        
        // setup
        
        // inject mock data into the JsonWebService instance
        let returnedData = "this is not json".data(using: .utf8)
        resetJsonWebService(returnedData: returnedData, dataTaskError: nil, tokenError: nil, isConnected: true)
        
        let requestData = createRequestInfo(method: .get, authorization: .none)
        let expectation = self.expectation(description: "async_test")
        
        
        // execute
        JsonWebService.shared.sendRequest(requestData) { (serviceResult: WebServiceResult<SimpleModel>) in
            
            // validate
            switch serviceResult {
            case .success(let actualModel):
                XCTFail("Expected failure, but was successful with model: \(String(describing: actualModel))")
            case .failure(let actualError):
                if let actualError = actualError, case .responseData = actualError {
                    // expected value found
                }
                else {
                    XCTFail("Expected responseData error, but received error: \(actualError?.localizedDescription ?? "unknown")")
                }
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func test_sendRequest_csvResponseData() {
        
        // setup
        
        // inject mock data into the JsonWebService instance
        let expectedData = "\"csv\",\"data\""
        resetJsonWebService(returnedData: expectedData.data(using: .utf8),
                            headers: ["Content-Type" : "text/csv"],
                            dataTaskError: nil,
                            tokenError: nil,
                            isConnected: true)
        
        let requestData = createRequestInfo(method: .get, authorization: .none, acceptHeaders: ["text/csv"])
        let expectation = self.expectation(description: "async_test")


        // execute
        JsonWebService.shared.sendRequest(requestData) { (serviceResult: WebServiceResult<String>) in
            
            // validate
            switch serviceResult {
            case .success(let actualData):
                XCTAssertEqual(actualData, expectedData)
                
            case .failure(let error):
                XCTFail("Expected success, but received failure with error: \(error?.localizedDescription ?? "none")")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
}


// MARK: - Private helpers

private extension JsonWebServiceTests {
    
    func testRequestMethod(_ method: WebServiceRequestMethod) {
        
        // setup
        
        // inject mock data into the JsonWebService instance
        let model  = SimpleModel(value1: 411, value2: "Starlord")
        resetJsonWebService(returnedData: model.toJsonData(), dataTaskError: nil, tokenError: nil, isConnected: true)
        
        let requestData = createRequestInfo(method: method, authorization: .none)
        let expectation = self.expectation(description: "async_test")

        
        // execute1
        JsonWebService.shared.sendRequest(requestData) { [weak self] (serviceResult: WebServiceResult<SimpleModel>) in
            
            // validate
            XCTAssertEqual(self?.mockSession.resultingUrlRequest?.httpMethod, method.rawValue)
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }
    
    func testAuthorization(_ authorization: WebServiceAuthorizationType) {
        
        // setup
        
        // inject mock data into the JsonWebService instance
        let model = SimpleModel(value1: 411, value2: "Starlord")
        resetJsonWebService(returnedData: model.toJsonData(), dataTaskError: nil, tokenError: nil, isConnected: true)
        
        let requestData = createRequestInfo(method: .get, authorization: authorization)
        let expectation = self.expectation(description: "async_test")

        
        // execute
        JsonWebService.shared.sendRequest(requestData) { [unowned self] (serviceResult: WebServiceResult<SimpleModel>) in
            
            // validate
            if let actualHeaders = self.mockSession.resultingUrlRequest?.allHTTPHeaderFields {
                switch authorization {
                case .none:
                    XCTAssertNil(actualHeaders[WebServiceHeaderKey.authorization])
                case .authToken:
                    if let actualToken = actualHeaders[WebServiceHeaderKey.authorization] {
                        XCTAssertEqual(actualToken, "Bearer " + self.expectedAuthToken)
                    }
                    else {
                        XCTFail("apiToken expected in header but was nil.")
                    }
                }
            }
            else {
                XCTFail("Could not access header fields from mock session")
            }
            
            expectation.fulfill()
        }
        
        waitForExpectations(timeout: 2, handler: nil)
    }

    func resetJsonWebService(returnedData: Data?,
                             headers: [String : String]? = nil,
                             dataTaskError: Error?,
                             tokenError: Error?,
                             isConnected: Bool) {
        
        let token        = tokenError == nil ? expectedAuthToken : nil
        mockSession      = MockURLSession(data: returnedData, headers: headers, error: dataTaskError)
        mockTokenManager = MockWebServiceTokenManager(token: token, error: tokenError)
        mockReachability = MockReachability(response: isConnected)
        
        // ensure that this test doesn't make any real service calls or check the real reachability
        JsonWebService.resetSharedInstance(session: mockSession,
                                           tokenManager: mockTokenManager,
                                           reachability: mockReachability)
    }
    
    func createRequestInfo(method: WebServiceRequestMethod,
                           authorization: WebServiceAuthorizationType,
                           acceptHeaders: [String] = []) -> WebServiceRequestInfo {
        
        return WebServiceRequestInfo(path: "http://does.not.matter",
                                     acceptHeaders: acceptHeaders,
                                     contentType: nil,
                                     customHeaders: nil,
                                     method: method,
                                     authorization: authorization,
                                     body: nil)
    }
    
    func createError(with message: String) -> Error {
        
        let errorUserInfo = [NSLocalizedDescriptionKey : message]
        return NSError(domain: "json.web.service.test", code: -1, userInfo: errorUserInfo)
    }
}
