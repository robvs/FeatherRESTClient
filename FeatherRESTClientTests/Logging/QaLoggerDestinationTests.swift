//
//  QaLoggerDestinationTests.swift
//  FeatherRESTClientTests
//
//  Created by Rob Vander Sloot on 8/24/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//

import XCTest

class QaLoggerDestinationTests: XCTestCase {
    
    private var writer: MockQaLoggerWriter!
    private var logger: QuikLogger!

    
    override func setUp() {
        super.setUp()
        
        writer = MockQaLoggerWriter()
        logger = QuikLogger()
    }
    
    override func tearDown() {
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        super.tearDown()
    }
    
    
    func test_loggedString_format() {
        
        // setup
        let destination = QaLoggerDestination(withWriter: writer, date: Date())
        logger.addDestination(destination)
        
        let expectedMessage    = "debug-message"
        let expectedDateString = LoggerDateFormat.dateFormat.string(from: Date())
        let expectedLevel      = "🔹" + String(describing: QuikLoggerLevel.info).uppercased() + ":"
        
        // execute
        logger.info(expectedMessage)
        
        // validate
        // this destination writes asynchronously, so we need to wait until it's done.
        waitFor(writer, logCount: 1)
        
        guard writer.logStrings.count == 1 else {
            XCTFail("Wrong number of logged strings: \(writer.logStrings.count)")
            return
        }
        
        let logComponents    = writer.logStrings.first!.string.components(separatedBy: " ")
        let actualDateString = logComponents[0]
        let actualTimeString = logComponents[1]
        let actualLevel      = logComponents[2]
        let actualMessage    = logComponents[3]
        
        XCTAssertEqual(actualDateString, expectedDateString)
        XCTAssertEqual(actualTimeString.count, 12)  // note: comparing the actual time value is problematic.
        XCTAssertEqual(actualLevel, expectedLevel)
        XCTAssertEqual(actualMessage, expectedMessage)
    }
    
    func test_logFileName_consecutiveLoggedStringsHaveSameName() {
        
        // setup
        let startDate   = Date()
        let destination = QaLoggerDestination(withWriter: writer, date: startDate)
        logger.addDestination(destination)
        
        let expectedFileName = AppFile.getLogFileUrl(for: startDate).lastPathComponent
        
        // execute
        logger.info("message 1")
        logger.info("message 2")
        logger.info("message 3")
        logger.info("message 4")

        // validate
        // this destination writes asynchronously, so we need to wait until it's done.
        waitFor(writer, logCount: 4)

        guard writer.logStrings.count == 4 else {
            XCTFail("Wrong number of logged strings: \(writer.logStrings.count)")
            return
        }
        
        let actualFileNames = writer.logStrings.map { return $0.url.lastPathComponent }
        for actualFileName in actualFileNames {
            XCTAssertEqual(actualFileName, expectedFileName)
        }
    }
    
    func test_logFileName_noChangeWhenDateChangesAndNoForgroundingNotification() {
        
        // setup
        let startDate   = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let destination = QaLoggerDestination(withWriter: writer, date: startDate)
        logger.addDestination(destination)
        
        let expectedFileName = AppFile.getLogFileUrl(for: startDate).lastPathComponent
        
        // execute
        logger.info("message 1")
        logger.info("message 2")
        
        // validate
        // this destination writes asynchronously, so we need to wait until it's done.
        waitFor(writer, logCount: 2)

        guard writer.logStrings.count == 2 else {
            XCTFail("Wrong number of logged strings: \(writer.logStrings.count)")
            return
        }
        
        let actualFileNames = writer.logStrings.map { return $0.url.lastPathComponent }
        for actualFileName in actualFileNames {
            XCTAssertEqual(actualFileName, expectedFileName)
        }
    }
    
    func test_logFileName_changesWhenDateChangesAndForgroundingNotification() {
        
        // setup
        let startDate   = Calendar.current.date(byAdding: .day, value: -2, to: Date())!
        let destination = QaLoggerDestination(withWriter: writer, date: startDate)
        logger.addDestination(destination)
        
        let expectedFileName1 = AppFile.getLogFileUrl(for: startDate).lastPathComponent
        let expectedFileName2 = AppFile.getLogFileUrl(for: Date()).lastPathComponent

        
        // execute
        logger.info("message 1")
        logger.info("message 2")
        
        // wait until the first two messages are logged before faking will-enter-forground.
        waitFor(writer, logCount: 2)

        destination.appWillEnterForeground()
        
        logger.info("message 3")
        logger.info("message 4")

        
        // validate
        // this destination writes asynchronously, so we need to wait until it's done.
        waitFor(writer, logCount: 4)

        guard writer.logStrings.count == 4 else {
            XCTFail("Wrong number of logged strings: \(writer.logStrings.count)")
            return
        }
        
        let actualFileNames = writer.logStrings.map { return $0.url.lastPathComponent }
        XCTAssertEqual(actualFileNames[0], expectedFileName1)
        XCTAssertEqual(actualFileNames[1], expectedFileName1)
        XCTAssertEqual(actualFileNames[2], expectedFileName2)
        XCTAssertEqual(actualFileNames[3], expectedFileName2)
    }
    
    func test_logLevel_traceAndDebugNotLogged() {
        
        // setup
        let destination = QaLoggerDestination(withWriter: writer, date: Date())
        logger.addDestination(destination)
        
        let expectedMessage = "debug-message"
        
        // execute
        logger.trace(expectedMessage)
        logger.debug(expectedMessage)
        logger.info(expectedMessage)
        logger.warn(expectedMessage)
        logger.error(expectedMessage)
        logger.fatal(expectedMessage)

        // validate
        // this destination writes asynchronously, so we need to wait until it's done.
        waitFor(writer, logCount: 4)

        guard writer.logStrings.count == 4 else {
            XCTFail("Wrong number of logged strings: \(writer.logStrings.count)")
            return
        }

        let actualLevel1 = writer.logStrings[0].string.components(separatedBy: " ")[2]
        let actualLevel2 = writer.logStrings[1].string.components(separatedBy: " ")[2]
        let actualLevel3 = writer.logStrings[2].string.components(separatedBy: " ")[2]
        let actualLevel4 = writer.logStrings[3].string.components(separatedBy: " ")[2]

        XCTAssertEqual(actualLevel1, "🔹" + String(describing: QuikLoggerLevel.info).uppercased() + ":")
        XCTAssertEqual(actualLevel2, "🔸" + String(describing: QuikLoggerLevel.warn).uppercased() + ":")
        XCTAssertEqual(actualLevel3, "🔴" + String(describing: QuikLoggerLevel.error).uppercased() + ":")
        XCTAssertEqual(actualLevel4, "‼️" + String(describing: QuikLoggerLevel.fatal).uppercased() + ":")
    }
}


// MARK: - Private helpers

private extension QaLoggerDestinationTests {
    
    func waitFor(_ writer: MockQaLoggerWriter, logCount: Int) {
        
        let predicate = NSPredicate { (evalObject, _) -> Bool in
            return (evalObject as! MockQaLoggerWriter).logStrings.count == logCount
        }
        
        if wait(forPredicate: predicate, evaluateWith: writer, timeout: 2.0) == false {
            XCTFail("Waiting for predicate timed out.")
        }
    }
}


final class MockQaLoggerWriter: QaLoggerDestinationWriting {
    
    private (set) var logStrings = [(string: String, url: URL)]()

    func writeString(_ logString: String, toUrl url: URL) {
        logStrings.append((string: logString, url: url))
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
