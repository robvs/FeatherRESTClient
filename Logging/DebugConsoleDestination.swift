//
//  DebugConsoleDestination.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 8/19/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//  https://github.com/robvs/FeatherRESTClient
//

import Foundation


// MARK: - Protocol definitions

/// Implemented by an object that handles writing the log message strings.
/// This allows injection into `DebugConsoleDestination` to make unit testing easier.
protocol DebugConsoleDestinationWriting {
    func writeString(_ logString: String)
}


// MARK: - Class definition

/// QuikLogger destination that writes logging entries to the debug console.
final class DebugConsoleDestination {
    
    private let writer: DebugConsoleDestinationWriting
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter

    init(withWriter writer: DebugConsoleDestinationWriting = DebugConsoleDestinationWriter()) {
        
        self.writer = writer
        self.dateFormatter = DateFormatter()
        self.timeFormatter = DateFormatter()
        
        dateFormatter.locale = NSLocale.current
        timeFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        timeFormatter.dateFormat = "HH:mm:ss.SSS"
    }
}


// MARK: - QuikLoggerDestining conformance

extension DebugConsoleDestination: QuikLoggerDestining {
    
    var minLevel: QuikLoggerLevel { return .trace }
    
    func send(logEntry: QuikLogEntry) {
        
        let dateString = dateFormatter.string(from: logEntry.date)
        let timeString = timeFormatter.string(from: logEntry.date)
        let levelMark  = getLevelIndicator(for: logEntry.level)
        let level      = String(describing: logEntry.level).uppercased()
        let fileName   = URL(fileURLWithPath: logEntry.fileName).lastPathComponent
        
        writer.writeString("\(dateString) \(timeString) \(levelMark)\(level) \(fileName):\(logEntry.line) \(logEntry.function) \(logEntry.message)")
    }
}


// MARK: - Private helpers

private extension DebugConsoleDestination {
    
    func getLevelIndicator(for level: QuikLoggerLevel) -> String {
        
        switch level {
        case .trace:
            return "▫️"
        case .debug:
            return "▪️"
        case .info:
            return "🔹"
        case .warn:
            return "🔸"
        case .error:
            return "🔴"
        case .fatal:
            return "‼️"
        }
    }
}


// MARK: - Standard console writer

fileprivate final class DebugConsoleDestinationWriter: DebugConsoleDestinationWriting {
    
    func writeString(_ logString: String) {
        print(logString)
    }
}
