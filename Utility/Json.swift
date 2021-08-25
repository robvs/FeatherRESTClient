//
//  Json.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 8/19/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//  https://github.com/robvs/FeatherRESTClient
//

import Foundation


/// Type def that represents a json dictionary
public typealias Json = [String : Any]


/// Utility functions for manipulating Json data.
struct JsonUtil {

    /// The key applied to JSON data that is provided as an array of JSON instead of an object so that the array
    /// can be presented as Json, not [Json].
    static let arrayKey = "items"

    static func toData<Model: Encodable>(model: Model) -> Data? {
        return try? JSONEncoder().encode(model)
    }
    
    static func toModel<Model: Decodable>(json: Json) -> Model? {
        
        guard let jsonData = try? JSONSerialization.data(withJSONObject: json, options: []) else {
            logger.error("Could not convert a JSON object to a Data object.")
            return nil
        }
        
        return toModel(jsonData: jsonData)
    }
    
    static func toModel<Model: Decodable>(jsonData: Data) -> Model? {
        
        let decoder = JSONDecoder()
        do {
            let model = try decoder.decode(Model.self, from: jsonData)
            return model
        }
        catch {
            var errorMessage = "Json decode error: "
            if let decodingError = error as? DecodingError {
                errorMessage += decodingError.detailedDescription
            }
            else {
                errorMessage += error.localizedDescription
            }
            
            if let json = toJson(data: jsonData), let jsonString = toString(json: json) {
                errorMessage += "\n" + jsonString
            }
            
            logger.error(errorMessage)
            return nil
        }
    }
    
    static func toString<Model: Encodable>(model: Model) -> String? {
        
        guard let jsonData = toData(model: model) else { return nil }
        return String(data: jsonData, encoding: .utf8)
    }
    
    static func toString(json: Json) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: json,
                                                      options: JSONSerialization.WritingOptions.prettyPrinted)
            return String(data: jsonData, encoding: .utf8)
        }
        catch {
            print(error.localizedDescription)
        }
        
        return nil
    }

    static func toJson<Model: Encodable>(model: Model) -> Json? {
        
        guard let jsonData = toData(model: model) else { return nil }
        return toJson(data: jsonData)
    }
    
    static func toJson(data: Data) -> Json? {
        
        let json = try? JSONSerialization.jsonObject(with: data, options: [])
        return json as? Json
    }
    
    static func toJson(jsonString: String) -> Json? {
        
        guard let jsonData = jsonString.data(using: .utf8) else { return nil }
        return toJson(data: jsonData)
    }
}


// MARK: - ModelToJsonDataConvertable

protocol ModelToJsonDataConvertable {}

extension ModelToJsonDataConvertable where Self: Encodable {
    
    func toJsonData() -> Data {
        
        let encoder = JSONEncoder()
        do {
            let jsonData = try encoder.encode(self)
            return jsonData
        }
        catch {
            logger.fatal("Converting model to json data failed. This shouldn't happen.")
            return Data()
        }
    }
}
