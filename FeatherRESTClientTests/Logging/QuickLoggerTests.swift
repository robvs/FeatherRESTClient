//
//  QuickLoggerTests.swift
//  FeatherRESTClientTests
//
//  Created by Rob Vander Sloot on 8/24/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//

import XCTest

let logger = QuikLogger()

class QuickLoggerTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_capturesDateLevelFileFunctionLineMessage() {
        
        // setup
        let destination = MockDestination(withMinLevel: .info)
        let logger = QuikLogger()
        let message = "yyz"
        
        logger.addDestination(destination)
        
        // execute
        logger.info(message); let expectedLine = #line
        
        // validate
        guard let log = destination.logs.first else {
            XCTFail("Wrong number of logged messages.")
            return
        }
        
        XCTAssertEqual(log.date.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.01)
        XCTAssertEqual(log.level,    .info)
        XCTAssertEqual(log.fileName, #file)
        XCTAssertEqual(log.function, #function)
        XCTAssertEqual(log.line,     expectedLine)
        XCTAssertEqual(log.message,  message)
    }
    
    func test_traceLogged_whenDestinationIsTrace() {
        
        // setup
        let destination = MockDestination(withMinLevel: .trace)
        let logger = QuikLogger()
        let message = "subdivisions"
        
        logger.addDestination(destination)

        // execute
        logger.trace(message); let expectedLine = #line
        
        // validate
        guard let log = destination.logs.first else {
            XCTFail("Wrong number of logged messages.")
            return
        }
        
        XCTAssertEqual(log.date.timeIntervalSince1970, Date().timeIntervalSince1970, accuracy: 0.01)
        XCTAssertEqual(log.level,    .trace)
        XCTAssertEqual(log.fileName, #file)
        XCTAssertEqual(log.function, #function)
        XCTAssertEqual(log.line,     expectedLine)
        XCTAssertEqual(log.message,  message)
    }
    
    func test_traceNotLogged_whenDestinationIsDebug() {
        
        // setup
        let destination = MockDestination(withMinLevel: .debug)
        let logger = QuikLogger()
        let message = "subdivisions"
        
        logger.addDestination(destination)

        // execute
        logger.trace(message)
        
        // validate
        XCTAssertEqual(destination.logs.count, 0)
    }
    
    func test_debugLogged_whenDestinationIsTrace() {
        
        // setup
        let destination = MockDestination(withMinLevel: .trace)
        let logger = QuikLogger()
        let message = "tom sawyer"
        
        logger.addDestination(destination)

        // execute
        logger.debug(message)
        
        // validate
        guard let log = destination.logs.first else {
            XCTFail("Wrong number of logged messages.")
            return
        }
        
        XCTAssertEqual(log.message,  message)
        XCTAssertEqual(log.level,    .debug)
    }

    func test_multipleDestinationsMultipleLevels() {
        
        // setup
        let traceDestination = MockDestination(withMinLevel: .trace)
        let debugDestination = MockDestination(withMinLevel: .debug)
        let infoDestination  = MockDestination(withMinLevel: .info)
        let warnDestination  = MockDestination(withMinLevel: .warn)
        let errorDestination = MockDestination(withMinLevel: .error)
        let fatalDestination = MockDestination(withMinLevel: .fatal)
        let logger = QuikLogger()
        let message = "limelight"
        
        logger.addDestination(traceDestination)
        logger.addDestination(debugDestination)
        logger.addDestination(infoDestination)
        logger.addDestination(warnDestination)
        logger.addDestination(errorDestination)
        logger.addDestination(fatalDestination)
        
        // execute
        logger.trace(message)
        logger.debug(message)
        logger.info(message)
        logger.warn(message)
        logger.error(message)

        // validate
        XCTAssertEqual(traceDestination.logs.count, 5)
        XCTAssertEqual(debugDestination.logs.count, 4)
        XCTAssertEqual(infoDestination.logs.count, 3)
        XCTAssertEqual(warnDestination.logs.count, 2)
        XCTAssertEqual(errorDestination.logs.count, 1)
        XCTAssertEqual(fatalDestination.logs.count, 0)  // can't execute fatal logging because it would crash the app.
    }
}


// MARK: - MockDestination

class MockDestination: QuikLoggerDestining {
    
    let minLevel: QuikLoggerLevel
    private (set) var logs: [QuikLogEntry]
    
    init(withMinLevel minLevel: QuikLoggerLevel) {
        
        self.minLevel = minLevel
        self.logs = []
    }
    
    func send(logEntry: QuikLogEntry) {
        logs.append(logEntry)
    }
}
