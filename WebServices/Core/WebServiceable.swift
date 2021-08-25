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


// MARK: - Data models

/// Container for the data returned by the authentication endpoint.
/// NOTE: The property names are expected to match the json keys in the response.
public struct AuthenticationInfo: Codable {
    
    var accessToken: String
    var refreshToken: String
    var secondsRemaining: Int
    var roles: [String]
}

/// Model for the data that is stored in an authorization token.
public struct WebServiceAuthTokenInfo: Decodable {
    
    var userId: String
    var username: String
    
    enum CodingKeys: String, CodingKey {
        case userId = "uid"
        case username = "un"
    }
}


// MARK: - Token managing protocol

typealias AuthorizationTokenResult = (token: String?, error: WebServiceError?)

protocol WebServiceTokenManageable {
    
    /// The information stored in the authentication token (i.e. user id, user name, etc.).
    /// Returns nil if there is no auth token.
    var authTokenInfo: WebServiceAuthTokenInfo? { get }
    
    /// Get a valid token for the specified type. If the current token is expired, it is refreshed (if possible)
    /// before being returned.
    func ensureValidToken(ofType tokenType: WebServiceAuthorizationType,
                          completion: @escaping (AuthorizationTokenResult) -> Void)
    
    /// Clear the authentication token as well as the refresh token.
    func clearAuthToken()
}


// MARK: - Reachability protocol

protocol ReachabilityCheckable {
    
    func isConnected() -> Bool
}

protocol TokenPersisting {
    
    func isCloseToExpiration() -> Bool
    func getAuthToken() -> String?
    func getSessionModel() -> WebServiceSessionModel?
    func saveSessionModel(_ session: WebServiceSessionModel)
    func clearAuthToken()
}


// MARK: - Generic web service types

/// Request states
public enum WebServiceRequestState {
    case notStarted
    case started
    case completeWithoutError
    case completeWithError(message: String)
    
    var isStarted: Bool {
        switch self {
        case .started:
            return true
        default:
            return false
        }
    }
}

/// Information that is required by the caller to perform a web services request.
public protocol WebServiceRequestData {
    
    var path:          String   { get }
    var acceptHeaders: [String] { get }
    var contentType:   String?  { get }
    var customHeaders: [String : String]?          { get }
    var method:        WebServiceRequestMethod     { get }
    var authorization: WebServiceAuthorizationType { get }
    var body:          Json?   { get }
}

/// Web service request standard header values
public struct WebServiceHeader {
    
    static var applicationJson: String { return "application/json" }
    static var textCsv: String { return "text/csv" }
}

/// Types of results that can be returned by a service call.
public enum WebServiceResult<Model> {
    case success(Model?)           // Model will be nil for requests that return no data
    case failure(WebServiceError?)
}

/// Result model type used for requests that return no data
public struct WebServiceEmptyResultModel: Decodable { }

/// Type of authorizations that are supported.
public enum WebServiceAuthorizationType {
    case none
    case authToken
}

/// Reqeust types that are supported. Note that the raw value is used set the method value in the URLRequest.
public enum WebServiceRequestMethod: String {
    case get  = "GET"
    case post = "POST"
    case put  = "PUT"
}

struct WebServiceHeaderKey {
    static var contentType:   String { return "Content-Type" }
    static var accept:        String { return "Accept" }
    static var authorization: String { return "Authorization" }
}
