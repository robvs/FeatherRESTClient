//
//  BasicAuthManager.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 3/19/18.
//  Copyright © 2018 Random Visual, LLC. All rights reserved.
//

import Foundation


/// Provides convenience functions for managing web service authentication data.
final class BasicAuthManager {
    
    /// Singleton
    static let shared = BasicAuthManager()
    
    private let apiTokenKey = "apiToken"
    private let expirationTimeKey = "expirationTimeKey"
    
    /// Private init to enforce singleton.
    private init() {}
    
    
    var apiToken: String? {
        get { return UserDefaults.standard.string(forKey: apiTokenKey) }
    }
    
    var expirationTime: Double {
        get { return UserDefaults.standard.double(forKey: expirationTimeKey) }
    }
    
    var isSessionExpired: Bool {
        let rightNow = Date().timeIntervalSince1970 + 60.0 // add a minute for padding
        return rightNow > expirationTime
    }

    func update(apiToken: String, secondsRemaining: Int) {
        
        let expirationTime = Date().timeIntervalSince1970 + Double(secondsRemaining)
        
        UserDefaults.standard.set(apiToken, forKey: apiTokenKey)
        UserDefaults.standard.set(expirationTime, forKey: expirationTimeKey)
    }
}
