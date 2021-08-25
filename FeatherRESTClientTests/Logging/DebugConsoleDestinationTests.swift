//
//  DebugConsoleDestinationTests.swift
//  FeatherRESTClientTests
//
//  Created by Rob Vander Sloot on 8/24/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//

import XCTest

class DebugConsoleDestinationTests: XCTestCase {
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    func test_formatOfLoggedString() {
        
        // setup
        let writer             = MockDebugConsoleWriter()
        let destination        = DebugConsoleDestination(withWriter: writer)
        let logger             = QuikLogger()
        let expectedMessage    = "debug-message"
        let expectedDateString = LoggerDateFormat.dateFormat.string(from: Date())
        let expectedLevel      = "▪️" + String(describing: QuikLoggerLevel.debug).uppercased()
        
        logger.addDestination(destination)

        // execute
        logger.debug(expectedMessage); let expectedLine = #line
        
        // validate
        guard writer.logStrings.count == 1 else {
            XCTFail("Wrong number of logged strings: \(writer.logStrings.count)")
            return
        }
        
        let expectedFileName = "\(URL(fileURLWithPath: #file).lastPathComponent):\(expectedLine)"
        
        let logComponents    = writer.logStrings.first!.components(separatedBy: " ")
        let actualDateString = logComponents[0]
        let actualTimeString = logComponents[1]
        let actualLevel      = logComponents[2]
        let actualFileName   = logComponents[3]
        let actualFunction   = logComponents[4]
        let actualMessage    = logComponents[5]
        
        XCTAssertEqual(actualDateString, expectedDateString)
        XCTAssertEqual(actualTimeString.count, 12)  // note: comparing the actual time value is problematic.
        XCTAssertEqual(actualLevel, expectedLevel)
        XCTAssertEqual(actualFileName, expectedFileName)
        XCTAssertEqual(actualFunction, #function)
        XCTAssertEqual(actualMessage, expectedMessage)
    }
}


// MARK: - Private helpers

fileprivate final class MockDebugConsoleWriter: DebugConsoleDestinationWriting {
    
    private (set) var logStrings = [String]()
    
    func writeString(_ logString: String) {
        logStrings.append(logString)
    }
}

fileprivate struct LoggerDateFormat {
    
    static var dateFormat: DateFormatter {
        
        let formatter = DateFormatter()
        
        formatter.locale = NSLocale.current
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter
    }
    
    static var timeFormat: DateFormatter {
        
        let formatter = DateFormatter()
        
        formatter.locale = NSLocale.current
        formatter.dateFormat = "HH:mm:ss.SSS"
        
        return formatter
    }
}
