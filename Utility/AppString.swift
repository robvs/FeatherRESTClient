//
//  AppString.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 8/24/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//

import Foundation


/// Ensures consistency across all `AppString` objects.
protocol AppStringFetchable {
    var key:   String { get }
    var table: String { get }
}

/// Convenience object that provides easy access to strings that are displayed in the app.
struct AppString {
    
    private static func getText(for appString: AppStringFetchable) -> String {
        return NSLocalizedString(appString.key, tableName: appString.table, comment: String(describing: appString))
    }
}


// MARK: - Error strings

extension AppString {
    
    static let appErrorDomain = "com.randomvisual.FeatherRESTClient"

    /// Error string keys
    enum AppError {
        case webServiceMissingToken
        case webServiceRenewTokenFailed
    }
    
    static func errorText(for error: AppError) -> String {
        
        switch error {
        case .webServiceMissingToken:     return "Attempted to call protected service but no token was found."
        case .webServiceRenewTokenFailed: return "Authorization token renewal failed. Please sign-out/sign-in if this error continues."
        }
    }
    
    static func error(for error: AppError, code: Int = 0, underlyingError: Error? = nil) -> Error {
        let errorMessage = errorText(for: error)
        var userInfo: [String : Any] = [NSLocalizedDescriptionKey: errorMessage]
        
        if let underlyingError = underlyingError {
            userInfo[NSUnderlyingErrorKey] = underlyingError
        }
        
        return NSError(domain: appErrorDomain, code: code, userInfo: userInfo)
    }
    
    static func error(with message: String, code: Int = 0) -> Error {
        
        let userInfo: [String : Any] = [NSLocalizedDescriptionKey: message]
        return NSError(domain: appErrorDomain, code: code, userInfo: userInfo)
    }
}
