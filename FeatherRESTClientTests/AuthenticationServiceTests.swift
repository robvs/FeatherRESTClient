//
//  AuthenticationServiceTests.swift
//  FeatherRESTClientTests
//
//  Created by Rob Vander Sloot on 4/10/18.
//  Copyright © 2018 Random Visual, LLC. All rights reserved.
//

import XCTest

class AuthenticationServiceTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_decode_happyPath() {
        
        // setup
        let secondsRemaining = 900
        let accessToken      = "access-token"
        let refreshToken     = "refresh-token"
        let jsonString       = "{ \"secondsRemaining\": \(secondsRemaining), \"accessToken\": \"\(accessToken)\", \"refreshToken\": \"\(refreshToken)\", \"roles\": [] }"
        let jsonData         = jsonString.data(using: .utf8)!
        let decoder          = JSONDecoder()

        // execute & validate
        do {
            let model = try decoder.decode(AuthenticationInfo.self, from: jsonData)
            
            XCTAssertEqual(model.secondsRemaining, secondsRemaining)
            XCTAssertEqual(model.accessToken, accessToken)
        }
        catch {
            if let decodingError = error as? DecodingError {
                XCTFail("Decoding error: \(decodingError.detailedDescription)")
            }
            else {
                XCTFail("Error while decoding: \(error.localizedDescription)")
            }
        }
    }
    
    func test_decode_missingSecondsRemaining() {
        
        // setup
        let accessToken      = "access-token"
        let jsonString       = "{ \"accessToken\": \"\(accessToken)\" }"
        let jsonData         = jsonString.data(using: .utf8)!
        let decoder          = JSONDecoder()
        
        // execute & validate
        do {
            _ = try decoder.decode(AuthenticationInfo.self, from: jsonData)
            
            XCTFail("Decoding was expected to fail.")
        }
        catch {
            // success - decoding was expected to fail.
        }
    }
    
    func test_decode_missingApiToken() {
        
        // setup
        let secondsRemaining = 900
        let jsonString       = "{ \"secondsRemaining\": \(secondsRemaining) }"
        let jsonData         = jsonString.data(using: .utf8)!
        let decoder          = JSONDecoder()
        
        // execute & validate
        do {
            _ = try decoder.decode(AuthenticationInfo.self, from: jsonData)
            
            XCTFail("Decoding was expected to fail.")
        }
        catch {
            // success - decoding was expected to fail.
        }
    }
}
