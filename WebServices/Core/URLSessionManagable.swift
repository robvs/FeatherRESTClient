//
//  URLSessionManagable.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 3/13/18.
//  Copyright © 2018 Rob Vander Sloot.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import Foundation


// MARK: - ULRSession mimicking protocol

/// Mimic the properties and methods of URLSession that are used to enable injection of a mock URLSession object.
protocol URLSessionManageable {
    
    func invalidateAndCancel()
    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask
}

extension URLSession: URLSessionManageable {}


// MARK: - Apply ModelToJsonDataConvertable to data models
// Apply `ModelToJsonDataConvertable` to the data models to enable encoding to Json.

extension AuthenticationInfo: ModelToJsonDataConvertable {}

extension JokeResponse: ModelToJsonDataConvertable {}

extension JokeListResponse: ModelToJsonDataConvertable {}

extension JokeCategoryListResponse: ModelToJsonDataConvertable {}
