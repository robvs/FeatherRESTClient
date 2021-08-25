//
//  IcndbService.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 2/28/18.
//  Copyright © 2018 Rob Vander Sloot.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//

import Foundation


// MARK: - Data models

/// Container for the data returned by the ICNDb "categories" endpoint.
/// NOTE: The property names are expected to match the json keys in the response.
public struct JokeCategoryListResponse: Codable {
    
    var type: String
    var value: [String]
}

/// Container for the data returned by an ICNDb endpoint that returns a single joke.
/// NOTE: The property names are expected to match the json keys in the response.
public struct JokeResponse: Codable {
    
    var type: String
    var value: Joke
}

/// Container for the data returned by an ICNDb endpoint that returns multiple jokes.
/// NOTE: The property names are expected to match the json keys in the response.
public struct JokeListResponse: Codable {
    
    var type: String
    var value: [Joke]
}

/// Container for a joke returned by an ICNDb endpoint.
/// NOTE: The property names are expected to match the json keys in the response.
public struct Joke: Codable {
    
    var id: Int
    var joke: String
    var categories: [String]
}

/// Base path to support web services.
struct WebServicePathBase {
    static var chuckNorris: String { return "https://api.icndb.com/" }
    static var firebase:    String { return "https://firebasestorage.googleapis.com/v0/b/featherrestclient.appspot.com/o/" }
}


// MARK: Request data

/// Request data for requesting a random joke.
public struct RequestDataForRandomJoke: WebServiceRequestData {
    
    // WebServiceRequestData conformance
    public var path:          String                      { return WebServicePathBase.chuckNorris + "jokes/random" }
    public var acceptHeaders: [String]                    { return [WebServiceHeader.applicationJson] }
    public var contentType:   String?                     { return WebServiceHeader.applicationJson }
    public var customHeaders: [String : String]?          { return nil }
    public var method:        WebServiceRequestMethod     { return .get }
    public var authorization: WebServiceAuthorizationType { return .none }
    public var body:          Json?                       { return nil }
}

/// Request data for requesting a specified number of random jokes.
public struct RequestDataForRandomJokes: WebServiceRequestData {
    
    let numberOfJokes: Int
    
    // WebServiceRequestData conformance
    public var path:          String                      { return WebServicePathBase.chuckNorris + "jokes/random/\(numberOfJokes)" }
    public var acceptHeaders: [String]                    { return [WebServiceHeader.applicationJson] }
    public var contentType:   String?                     { return WebServiceHeader.applicationJson }
    public var customHeaders: [String : String]?          { return nil }
    public var method:        WebServiceRequestMethod     { return .get }
    public var authorization: WebServiceAuthorizationType { return .none }
    public var body:          Json?                       { return nil }
}

/// Request data for requesting the list of joke categories.
public struct RequestDataForJokeCategories: WebServiceRequestData {
    
    // WebServiceRequestData conformance
    public var path:          String                      { return WebServicePathBase.chuckNorris + "categories" }
    public var acceptHeaders: [String]                    { return [WebServiceHeader.applicationJson] }
    public var contentType:   String?                     { return WebServiceHeader.applicationJson }
    public var customHeaders: [String : String]?          { return nil }
    public var method:        WebServiceRequestMethod     { return .get }
    public var authorization: WebServiceAuthorizationType { return .none }
    public var body:          Json?                       { return nil }
}
