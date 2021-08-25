//
//  FakeUrlSessionManager.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 8/24/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//

import Foundation


/// This class is used to provide hard-coded web service responses to help with testing when the web service is not available.
final class FakeUrlSessionManager {
}


// MARK: URLSessionManageable conformance

extension FakeUrlSessionManager: URLSessionManageable {

    func invalidateAndCancel() {
        // do nothing
    }

    func dataTask(with request: URLRequest,
                  completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) -> URLSessionDataTask {

        let data: Data?
        switch request.url!.absoluteString {
        case let urlString where urlString.range(of: "authenticate.json") != nil:
            data = AuthenticationInfo(accessToken: "access-token", refreshToken: "refresh-token", secondsRemaining: 600, roles: []).toJsonData()

        case let urlString where urlString.hasSuffix("jokes/random/10"):  // assumes http://api.icndb.com/
            data = createRandomJokeListResponse().toJsonData()

        case let urlString where urlString.hasSuffix("jokes/random"):     // assumes http://api.icndb.com/
            data = createRandomJokeResponse().toJsonData()

        case let urlString where urlString.hasSuffix("categories"):       // assumes http://api.icndb.com/
            data = createJokeCategoryList().toJsonData()

        default:
            data = nil
        }

        return FakeUrlSessionDataTask(data: data,
                                      code: 200,
                                      error: nil,
                                      completionHandler: completionHandler)
    }


    // MARK: Private helpers

    /// Provides the raw data for a set of joke objects.
    private enum FakeJoke {
        case joke1, joke2, joke3

        var id: Int {
            switch self {
            case .joke1: return 77
            case .joke2: return 557
            case .joke3: return 534
            }
        }

        var joke: String {
            switch self {
            case .joke1: return "Chuck Norris can divide by zero."
            case .joke2: return "Chuck Norris can read from an input stream."
            case .joke3: return "Chuck Norris is the ultimate mutex, all threads fear him."
            }
        }

        var categories: [String] {
            switch self {
            case .joke1: return []
            case .joke2: return ["nerdy"]
            case .joke3: return ["nerdy"]
            }
        }
    }

    /// Create a new random joke response.
    private func createRandomJokeResponse() -> JokeResponse {

        let jokes: [FakeJoke] = [.joke1, .joke2, .joke3]
        let randomIndex = Int(arc4random_uniform(UInt32(jokes.count)))
        let joke = jokes[randomIndex]

        return JokeResponse(type: "success", value: Joke(id: joke.id, joke: joke.joke, categories: joke.categories))
    }

    /// Create a new random joke list response.
    private func createRandomJokeListResponse() -> JokeListResponse {

        var jokes = [Joke]()

        jokes.append(Joke(id: FakeJoke.joke1.id, joke: FakeJoke.joke1.joke, categories: FakeJoke.joke1.categories))
        jokes.append(Joke(id: FakeJoke.joke2.id, joke: FakeJoke.joke2.joke, categories: FakeJoke.joke2.categories))
        jokes.append(Joke(id: FakeJoke.joke3.id, joke: FakeJoke.joke3.joke, categories: FakeJoke.joke3.categories))

        return JokeListResponse(type: "success", value: jokes)
    }

    /// Create a new category list response.
    private func createJokeCategoryList() -> JokeCategoryListResponse {

        return JokeCategoryListResponse(type: "success", value: ["explicit", "nerdy"])
    }
}

/// Fake data task used to override `resume()`, which is called in JsonWebService.sendRequest()
class FakeUrlSessionDataTask: URLSessionDataTask {

    let responseData: Data?
    let responseCode: Int
    let responseError: Error?
    let sessionCompletionHandler: (Data?, URLResponse?, Error?) -> Void

    init(data: Data?, code: Int, error: Error?, completionHandler: @escaping (Data?, URLResponse?, Error?) -> Void) {
        responseData = data
        responseCode = code
        responseError = error
        sessionCompletionHandler = completionHandler
    }

    override func resume() {
        let urlResponse = HTTPURLResponse(url: URL(fileURLWithPath:"http://something.com"),
                                          statusCode: responseCode,
                                          httpVersion: nil,
                                          headerFields: nil)
        sessionCompletionHandler(responseData, urlResponse, responseError)
    }
}

