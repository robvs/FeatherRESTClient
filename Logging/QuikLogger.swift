//
//  QuikLogger.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 8/19/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//  https://github.com/robvs/FeatherRESTClient
//

import Foundation


// MARK: - Enums and protocols

/// Possible log levels, in order of precedence/verboseness.
enum QuikLoggerLevel: Int {
    
    /// For additional details that may be needed when debugging, but not necessarily every test run.
    /// i.e. When "tracing" the code to see precisely where something is happening.
    case trace = 1
    
    /// Items that are useful to see during typical test sessions.
    case debug
    
    /// Interesting runtime events that are logged inside and outside of debug builds.
    case info
    
    /// Indicates unexpected or undesired behavior, but doesn't necessarily affect normal operation of the app.
    case warn
    
    /// Indicates an error or unexpected behavior that can affect normal operation of the app.
    case error
    
    /// Indicates an unexpected error from which the application can not recover, or unexpected code
    /// execution that indicates a programming error.
    case fatal
}

struct QuikLogEntry {
    let date: Date
    let level: QuikLoggerLevel
    let fileName: String
    let function: String
    let line: Int
    let message: String
}

/// Implemented by objects that can act as a logging destination.
/// btw, "destining" is actually a real word :P
protocol QuikLoggerDestining {
    
    /// The minimum level at which messages are logged. All messages below this level are ignored.
    var minLevel: QuikLoggerLevel { get }
    
    /// Send the given log to the desired destination.
    func send(logEntry: QuikLogEntry)
}


// MARK: - Class definition

/// Provides a runtime logging mechanism that's a step or two better than `print("...")`.
final class QuikLogger {
    
    private var destinations: [QuikLoggerDestining]
    
    init() {
        self.destinations = []
    }
}


// MARK: - Public methods

extension QuikLogger {
    
    func addDestination(_ destination: QuikLoggerDestining) {
        destinations.append(destination)
    }
    
    /// For additional details that may be needed when debugging, but not necessarily every test run.
    /// i.e. When "tracing" the code to see precisely where something is happening.
    func trace(_ message: String, _ fileName: StaticString = #file, _ function: StaticString = #function, _ line: Int = #line) {
        send(level: .trace, message: message, fileName: fileName, function: function, line: line)
    }
    
    /// Items that are useful to see during typical test sessions.
    func debug(_ message: String, _ fileName: StaticString = #file, _ function: StaticString = #function, _ line: Int = #line) {
        send(level: .debug, message: message, fileName: fileName, function: function, line: line)
    }

    /// Interesting runtime events that are logged inside and outside of debug builds.
    func info(_ message: String, _ fileName: StaticString = #file, _ function: StaticString = #function, _ line: Int = #line) {
        send(level: .info, message: message, fileName: fileName, function: function, line: line)
    }

    /// Indicates unexpected or undesired behavior, but doesn't necessarily affect normal operation of the app.
    func warn(_ message: String, _ fileName: StaticString = #file, _ function: StaticString = #function, _ line: Int = #line) {
        send(level: .warn, message: message, fileName: fileName, function: function, line: line)
    }

    /// Indicates an error or unexpected behavior that can affect normal operation of the app.
    func error(_ message: String, _ fileName: StaticString = #file, _ function: StaticString = #function, _ line: Int = #line) {
        send(level: .error, message: message, fileName: fileName, function: function, line: line)
    }

    /// Indicates an unexpected error from which the application can not recover.
    func fatal(_ message: String, _ fileName: StaticString = #file, _ function: StaticString = #function, _ line: Int = #line) {
        send(level: .fatal, message: message, fileName: fileName, function: function, line: line)
    }
}


// MARK: - Private helpers

private extension QuikLogger {
    
    func send(level: QuikLoggerLevel, message: String, fileName: StaticString, function: StaticString, line: Int) {
        
        let logEntry = QuikLogEntry(date: Date(),
                                    level: level,
                                    fileName: fileName.description,
                                    function: function.description,
                                    line: line,
                                    message: message)
        
        destinations.forEach { (destination: QuikLoggerDestining) in
            if level.rawValue >= destination.minLevel.rawValue {
                destination.send(logEntry: logEntry)
            }
        }
        
        // if fatal, crash the app when running in debug mode.
        if level == .fatal {
            #if !TEST_TARGET
                assertionFailure(message)
            #endif
        }
    }
}
