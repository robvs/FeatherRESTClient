//
//  AuthenticationService.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 2/26/18.
//  Copyright © 2018 Rob Vander Sloot.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.

import Foundation


// MARK: - Data model

/// Container for the data returned by the api/session endpoint.
/// NOTE: The property names are expected to match the json keys in the response.
public struct AuthenticationInfo: Codable {
    
    var secondsRemaining: Int
    var apiToken: String
}


// MARK: Request data

/// Authentication and user session handling.
public struct RequestDataForAuthenticate: WebServiceRequestData {
    
    public let userId:   String
    public let password: String
    
    // WebServiceRequestData conformance
    public var path:          String                      { return WebServicePathBase.firebase + "authenticate.json?alt=media&token=e38b7558-fed3-4573-8994-91b52b91c9be" }
    public var accept:        String?                     { return WebServiceHeader.genericAccept }
    public var contentType:   String?                     { return nil }
    public var customHeaders: [String : String]?          { return nil }
    public var method:        WebServiceRequestMethod     { return .get }   // this would normally be a POST, but we're using a dummy endpoint.
    public var authorization: WebServiceAuthorizationType { return .none }
    
    // NOTE: The body would normally include the username and password, but it must be nil here
    //       since we're only using a dummy endpoint.
//    public var body: Json? { return ["Username" : userId, "Password" : password, "Type" : "Domain"] }
    public var body: Json? { return nil }
}

/// Authentication and user session handling.
public struct RequestDataForRenewToken: WebServiceRequestData {
    
    // WebServiceRequestData conformance
    public var path:          String                      { return WebServicePathBase.firebase + "authenticate.json?alt=media&token=e38b7558-fed3-4573-8994-91b52b91c9be" }
    public var accept:        String?                     { return WebServiceHeader.genericAccept }
    public var contentType:   String?                     { return nil }
    public var customHeaders: [String : String]?          { return nil }
    public var method:        WebServiceRequestMethod     { return .get }   // this would normally be a POST or PUT
    public var authorization: WebServiceAuthorizationType { return .none }
    public var body: Json? { return nil }
}
