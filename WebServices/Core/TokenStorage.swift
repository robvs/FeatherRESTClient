//
//  TokenStorage.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 8/19/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//

import Foundation


final class TokenStorage {
    
    private let authTokenExpirationKey = "authTokenExpirationKey"
    private let authTokenKey = "authTokenKey"
    private let refreshTokenKey = "refreshTokenKey"
    private var authTokenExpirationDate: Date?
}


// MARK: TokenPersisting conformance

extension TokenStorage: TokenPersisting {
    
    func isCloseToExpiration() -> Bool {
        
        authTokenExpirationDate = authTokenExpirationDate ?? getTokenExpirationDate()
        
        guard let expirationDate = authTokenExpirationDate else { return false }
        
        return expirationDate < Date().addingTimeInterval(30.0)
    }
    
    func getAuthToken() -> String? {
        
        guard let authToken = KeychainUtility.shared.getString(for: authTokenKey) else {
            logger.error("Retrieving auth token from keychain failed.")
            return nil
        }
        
        return authToken
    }
    
    func getSessionModel() -> WebServiceSessionModel? {
        
        guard let expirationDate = authTokenExpirationDate else {
            logger.info("Retrieving session info was requested, but no session exists (exp date is nil).")
            return nil
        }

        guard let authToken = KeychainUtility.shared.getString(for: authTokenKey) else {
            logger.error("Retrieving auth token from keychain failed.")
            return nil
        }
        
        guard let refreshToken = KeychainUtility.shared.getString(for: refreshTokenKey) else {
            logger.error("Retrieving refresh token from keychain failed.")
            return nil
        }
        
        return WebServiceSessionModel(authToken: authToken,
                                      refreshToken: refreshToken,
                                      expirationTime: expirationDate)
    }
    
    func saveSessionModel(_ session: WebServiceSessionModel) {
        
        guard KeychainUtility.shared.saveString(value: session.authToken, forKey: authTokenKey) else {
            logger.error("Saving auth token to keychain failed.")
            return
        }
        
        guard KeychainUtility.shared.saveString(value: session.refreshToken, forKey: refreshTokenKey) else {
            logger.error("Saving refresh token to keychain failed.")
            return
        }
        
        setTokenExpirationDate(expirationDate: session.expirationTime)
        authTokenExpirationDate = session.expirationTime
    }
    
    func clearAuthToken() {
        
        guard authTokenExpirationDate != nil else {
            logger.debug("Request to clear auth token ignored because it is already cleared.")
            return
        }
        
        if KeychainUtility.shared.deleteValue(forKey: authTokenKey) == false {
            logger.error("Clearing auth token in keychain failed.")
        }
        
        if KeychainUtility.shared.deleteValue(forKey: refreshTokenKey) == false {
            logger.error("Clearing refresh token in keychain failed.")
        }
        
        setTokenExpirationDate(expirationDate: nil)
        authTokenExpirationDate = nil
    }
}


// MARK: Private helpers

private extension TokenStorage {
    
    func getTokenExpirationDate() -> Date? {
        
        let timeIntervalSince1970 = UserDefaults.standard.double(forKey: authTokenExpirationKey)
        
        guard timeIntervalSince1970 > 0 else { return nil }
        return Date(timeIntervalSince1970: timeIntervalSince1970)
    }
    
    func setTokenExpirationDate(expirationDate: Date?) {
        
        UserDefaults.standard.set(expirationDate?.timeIntervalSince1970, forKey: authTokenExpirationKey)
    }
}
