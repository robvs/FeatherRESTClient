//
//  XCTestCase+Ext.swift
//  FeatherRESTClientTests
//
//  Created by Rob Vander Sloot on 8/24/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//

import Foundation
import XCTest


fileprivate let waitQueue = DispatchQueue(label: "com.randomvisual.FeatherRESTClientTests.wait-test", qos: .utility)

extension XCTestCase {
    
    /// Wait for the given predicate to evaluate to true or for the specified timeout to expire,
    /// whichever comes first.
    ///
    /// This extension performs the same task as:
    ///     let expectation = self.expectation(for: predicate, evaluatedWith: evaluationObject, handler: nil)
    ///     waitForExpectations(timeout: timeout, handler: nil)
    /// but there is apparently a bug that, under certain circumstances, produces an exception with the message:
    ///     "multiple calls made to -[XCTestExpectation fulfill] for async_test"
    func wait(forPredicate predicate: NSPredicate, evaluateWith evaluationObject: Any, timeout: TimeInterval) -> Bool {
        
        let expectation = self.expectation(description: "async test wait for predicate")
        var didSucceed = true
        
        check(predicate, evaluateWith: evaluationObject, startTime: Date(), timeout: timeout) { (didTimeout) in
            if didTimeout {
                didSucceed = false
                XCTFail("expectation timed out.")
            }
            
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout + 0.1)
        return didSucceed
    }
    
    /// Wait for the given amount of time.
    func wait(forTimeout timeout: TimeInterval) {
        
        let expectation = self.expectation(description: "async test wait for timeout")
        
        let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(20)
        waitQueue.asyncAfter(deadline: deadline) {
            expectation.fulfill()
        }
        
        wait(for: [expectation], timeout: timeout + 0.1)
        return
    }

    private func check(_ predicate: NSPredicate,
                       evaluateWith evaluationObject: Any,
                       startTime: Date,
                       timeout: TimeInterval,
                       completion: @escaping (_ didTimeout: Bool) -> Void) {

        guard startTime.timeIntervalSinceNow > -timeout else {
            completion(true)
            return
        }
        
        let deadline = DispatchTime.now() + DispatchTimeInterval.milliseconds(20)
        waitQueue.asyncAfter(deadline: deadline) { [weak self] in
            if predicate.evaluate(with: evaluationObject) {
                completion(false)
            }
            else {
                self?.check(predicate,
                            evaluateWith: evaluationObject,
                            startTime: startTime,
                            timeout: timeout,
                            completion: completion)
            }
        }
    }
}
