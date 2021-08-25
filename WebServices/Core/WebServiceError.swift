//
//  WebServiceError.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 2/26/18.
//  Copyright © 2018 Rob Vander Sloot.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import Foundation


/// Error types that can be returned in a WebServiceResult.
public enum WebServiceError: Error {
    case unexpected
    case noConnection
    case urlPath
    case token(error: Error?)
    case serverResponse
    case statusCode(code: Int)
    case responseData(error: Error?)
    case urlSession(error: Error?)
    
    /// User-friendly description that can be displayed to the user.
    var friendlyDescription: String {
        switch self {
        case .unexpected:
            return "An unexpected service error occurred. Please contact tech support if this error continues."
        case .noConnection:
            return "There is no network connection. Please connect to continue."
        case .urlPath:
            return "An internal service error occurred. Please contact tech support if this error continues."
        case .token:
            return "An authentication error occurred. Please sign-out then sign back in."
        case .serverResponse:
            return "An unexpected service response was received. Please contact tech support if this error continues."
        case .statusCode(let statusCode):
            switch statusCode {
            case 200...299:
                return "No error"
            case 401, 403:
                return "Authorization failed. Please sign in with a valid user id and password."
            default:
                return "A server error occurred (\(statusCode)). Please contact tech support if this error continues."
            }
        case .responseData:
            return "An unexpected response was received. Please contact tech support if this error continues."
        case .urlSession:
            return "A service error occurred. Please contact tech support if this error continues."
        }
    }
    
    var localizedDescription: String {
        switch self {
        case .unexpected, .noConnection, .urlPath, .serverResponse, .statusCode:
            return friendlyDescription
        case .token(let error):
            return error?.localizedDescription ?? friendlyDescription
        case .responseData(let error):
            return error?.localizedDescription ?? friendlyDescription
        case .urlSession(let error):
            return error?.localizedDescription ?? friendlyDescription
        }
    }
}

// MARK: - LocalizedError conformance
extension WebServiceError: LocalizedError {
    
    public var errorDescription: String? {
        return localizedDescription
    }
}

// MARK: - Equatable conformance
extension WebServiceError: Equatable {
    
    public static func ==(lhs: WebServiceError, rhs: WebServiceError) -> Bool {
        
        switch lhs {
        case .unexpected:
            guard case .unexpected = rhs else { return false }
            return true
            
        case .noConnection:
            guard case .noConnection = rhs else { return false }
            return true

        case .urlPath:
            guard case .urlPath = rhs else { return false }
            return true

        case .token(let lhsError):
            if case .token(let rhsError) = rhs {
                return lhsError?.localizedDescription == rhsError?.localizedDescription
            }
            else {
                return false
            }
            
        case .serverResponse:
            guard case .serverResponse = rhs else { return false }
            return true

        case .statusCode(let lhsCode):
            if case .statusCode(let rhsCode) = rhs {
                return lhsCode == rhsCode
            }
            else {
                return false
            }
            
        case .responseData(let lhsError):
            if case .responseData(let rhsError) = rhs {
                return lhsError?.localizedDescription == rhsError?.localizedDescription
            }
            else {
                return false
            }
            
        case .urlSession(let lhsError):
            if case .urlSession(let rhsError) = rhs {
                return lhsError?.localizedDescription == rhsError?.localizedDescription
            }
            else {
                return false
            }
        }
    }
}
