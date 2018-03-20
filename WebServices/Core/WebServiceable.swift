//
//  WebServiceable.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 2/22/18.
//  Copyright © 2018 Rob Vander Sloot.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import Foundation


// MARK: - Token managing protocol

typealias AuthorizationTokenResult = (token: String?, error: WebServiceError?)
protocol WebServiceTokenManageable {
    
    func ensureValidToken(ofType tokenType: WebServiceAuthorizationType,
                          completion: @escaping (AuthorizationTokenResult) -> Void)
}


// MARK: - Reachability protocol

protocol ReachabilityCheckable {
    
    func isConnected() -> Bool
}


// MARK: - Generic web service types

/// Request states
public enum WebServiceRequestState {
    case notStarted
    case started
    case completeWithoutError
    case completeWithError(message: String)
}

/// Information that is required by the caller to perform a web services request.
public protocol WebServiceRequestData {
    
    var path:          String                      { get }
    var accept:        String?                     { get }
    var contentType:   String?                     { get }
    var customHeaders: [String : String]?          { get }
    var method:        WebServiceRequestMethod     { get }
    var authorization: WebServiceAuthorizationType { get }
    var body:          Json?                       { get }
}

/// Web service request standard header values
public struct WebServiceHeader {
    
    static var acceptKey:          String { return "Accept" }
    static var genericAccept:      String { return "application/json" }
    static var contentTypeKey:     String { return "Content-Type" }
    static var genericContentType: String { return "application/json" }
    static var apiTokenKey:        String { return "api-token" }
}

/// Types of results that can be returned by a service call.
public enum WebServiceResult<Model> {
    case success(Model?)           // Model will be nil for requests that return no data
    case failure(WebServiceError?)
}

/// Type of authorizations that are supported.
public enum WebServiceAuthorizationType {
    case none
    case basicAuth
}

/// Reqeust types that are supported. Note that the raw value is used set the method value in the URLRequest.
public enum WebServiceRequestMethod: String {
    case get  = "GET"
    case post = "POST"
    case put  = "PUT"
}

/// Base path to support web services.
struct WebServicePathBase {
    static var chuckNorris: String { return "https://api.icndb.com/" }
    static var firebase:    String { return "https://firebasestorage.googleapis.com/v0/b/featherrestclient.appspot.com/o/" }
}

