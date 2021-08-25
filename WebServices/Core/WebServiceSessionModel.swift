//
//  WebServiceSessionModel.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 8/19/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import Foundation


public struct WebServiceSessionModel {
    
    public let authToken: String
    public let refreshToken: String
    public let expirationTime: Date
}
