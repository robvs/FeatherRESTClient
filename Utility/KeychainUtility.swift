//
//  KeychainUtility.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 8/19/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//  https://github.com/robvs/FeatherRESTClient
//

import Foundation


final class KeychainUtility {
    
    /// Singleton
    static let shared = KeychainUtility()
    
    private let serviceName: String
    private let accessGroup: String?
    private let stringEncoding = String.Encoding.utf8
    
    init() {
        
        serviceName = Bundle.main.bundleIdentifier ?? "AvaTelApp"
        accessGroup = nil
    }
    
    /// Get the string value for the given key.
    /// - parameter key: The key for which the value is retrieved.
    func getString(for key: String) -> String? {
        
        var query = createKeychainQuery(for: key)
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        query[kSecReturnAttributes as String] = kCFBooleanTrue
        query[kSecReturnData as String] = kCFBooleanTrue
        
        // Try to fetch the existing keychain item that matches the query.
        var queryResult: AnyObject?
        let status = withUnsafeMutablePointer(to: &queryResult) {
            SecItemCopyMatching(query as CFDictionary, UnsafeMutablePointer($0))
        }
        
        // Check the return status
        guard status != errSecItemNotFound else {
            logger.trace("No entry found in keychain for key `\(key)`")
            return nil
        }
        
        guard status == noErr else {
            logger.error("Error attempting to retrieve entry in keychain for key `\(key)`. OSStatus: \(status)")
            return nil
        }
        
        // Parse the value from the query result.
        guard
            let existingItem = queryResult as? [String : AnyObject],
            let valueData = existingItem[kSecValueData as String] as? Data,
            let value = String(data: valueData, encoding: stringEncoding) else {
                return nil
        }

        return value
    }
    
    /// Save the string value for the given key. If a value already exists for the key, the value is updated.
    /// - parameter value: The strin value to be saved.
    /// - parameter key:   The key under which which the value is saved.
    /// - returns: True if successful.
    func saveString(value: String, forKey key: String) -> Bool {
        
        // Encode the value into an Data object.
        let valueData = value.data(using: stringEncoding)!
        
        var query: [String:Any] = createKeychainQuery(for: key)
        query[kSecValueData as String] = valueData
        query[kSecAttrAccessible as String] = kSecAttrAccessibleWhenUnlocked

        let status: OSStatus = SecItemAdd(query as CFDictionary, nil)
        
        if status == errSecSuccess || status == noErr {
            return true
        }
        else if status == errSecDuplicateItem {
            var attributesToUpdate = [String : AnyObject]()
            attributesToUpdate[kSecValueData as String] = valueData as AnyObject?
            
            query = createKeychainQuery(for: key)
            let status = SecItemUpdate(query as CFDictionary, attributesToUpdate as CFDictionary)
            
            let success = status == noErr || status == errSecSuccess
            if success == false {
                logger.error("Error attempting to update entry in keychain for key `\(key)`. OSStatus: \(status)")
            }
            
            return success
        }
        else {
            logger.error("Error attempting to save entry in keychain for key `\(key)`. OSStatus: \(status)")
            return false
        }
    }
    
    func deleteValue(forKey key: String) -> Bool {
        
        let query = createKeychainQuery(for: key)
        let status = SecItemDelete(query as CFDictionary)
        
        let success = status == noErr || status == errSecSuccess
        if success == false {
            logger.error("Error attempting to delete entry in keychain for key `\(key)`. OSStatus: \(status)")
        }
        
        return success
    }
}


// MARK: Private helpers

private extension KeychainUtility {
    
    private func createKeychainQuery(for key: String) -> [String : AnyObject] {
        
        var query = [String : AnyObject]()
        query[kSecClass as String] = kSecClassGenericPassword
        query[kSecAttrService as String] = serviceName as AnyObject?
        query[kSecAttrAccount as String] = key as AnyObject?

        if let accessGroup = accessGroup {
            query[kSecAttrAccessGroup as String] = accessGroup as AnyObject?
        }
        
        return query
    }
}
