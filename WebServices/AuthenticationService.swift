//
//  AuthenticationService.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 2/26/18.
//  Copyright © 2018 Rob Vander Sloot.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.

import Foundation


import Foundation


// MARK: Request data

/// Authentication and user session handling.
public struct RequestDataForAuthenticate: WebServiceRequestData {
    
    public let username: String
    public let password: String
    private let pathUrl = URL(string: "https://path.to.auth.url/")!

    // WebServiceRequestData conformance
    public var path:          String                      { return pathUrl.absoluteString }
    public var acceptHeaders: [String]                    { return [WebServiceHeader.applicationJson] }
    public var contentType:   String?                     { return WebServiceHeader.applicationJson }
    public var customHeaders: [String : String]?          { return nil }
    public var method:        WebServiceRequestMethod     { return .post }
    public var authorization: WebServiceAuthorizationType { return .none }
    
    public var body: Json? { return ["username" : username, "password" : password, "type" : "Domain"] }
}

/// Authentication and user session handling.
public struct RequestDataForRefreshToken: WebServiceRequestData {
    
    public let sessionInfo: WebServiceSessionModel
    private let pathUrl = URL(string: "https://path.to.refresh.url/")!

    // WebServiceRequestData conformance
    public var path:          String                      { return pathUrl.absoluteString }
    public var acceptHeaders: [String]                    { return [WebServiceHeader.applicationJson] }
    public var contentType:   String?                     { return WebServiceHeader.applicationJson }
    public var customHeaders: [String : String]?          { return nil }
    public var method:        WebServiceRequestMethod     { return .post }
    public var authorization: WebServiceAuthorizationType { return .none }
    
    public var body: Json? {
        return ["accessToken" : sessionInfo.authToken, "refreshToken" : sessionInfo.refreshToken]
    }
}
