//
//  QaLoggerDestination.swift
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
/// This allows injection into `QaLoggerDestination` to make unit testing easier.
protocol QaLoggerDestinationWriting {
    func writeString(_ logString: String, toUrl url: URL)
}


// MARK: - Class definition

/// QuikLogger destination that writes logging entries to a file.
final class QaLoggerDestination {
    
    private let maxLogFileCount = 7
    
    private let writer: QaLoggerDestinationWriting
    private let dateFormatter: DateFormatter
    private let timeFormatter: DateFormatter
    private let loggerQueue: DispatchQueue
    private var logUrl: URL

    /// Create a new instance that uses the given writer and specified date.
    /// - parameters:
    ///   - writer: Injected object that handles writing the logged string to a file.
    ///   - date:   The date that is used in the name of the initial log file. The default value
    ///             is expected to be used in production.
    init(withWriter writer: QaLoggerDestinationWriting = QaLoggerDestinationWriter(),
         date: Date = Date()) {
        
        self.writer = writer
        self.dateFormatter = DateFormatter()
        self.timeFormatter = DateFormatter()
        
        dateFormatter.locale = NSLocale.current
        timeFormatter.locale = NSLocale.current
        dateFormatter.dateFormat = "yyyy-MM-dd"
        timeFormatter.dateFormat = "HH:mm:ss.SSS"
        loggerQueue = DispatchQueue(label: "com.randomvisual.FeatherRESTClient.qa-logger", qos: .utility)
        
        logUrl = AppFile.getLogFileUrl(for: date)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(appWillEnterForeground),
                                               name: NSNotification.Name.UIApplicationWillEnterForeground,
                                               object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
}


// MARK: - Public methods

extension QaLoggerDestination {
    
    @objc func appWillEnterForeground() {
        
        // the log file name will change when the user foregrounds the app AND the date has changed.
        logUrl = AppFile.getLogFileUrl(for: Date())
    }
}


// MARK: - QuikLoggerDestining conformance

extension QaLoggerDestination: QuikLoggerDestining {
    
    var minLevel: QuikLoggerLevel { return .info }
    
    func send(logEntry: QuikLogEntry) {
        
        loggerQueue.async { [weak self] in
            guard let mySelf = self else { return }
            
            let dateString = mySelf.dateFormatter.string(from: logEntry.date)
            let timeString = mySelf.timeFormatter.string(from: logEntry.date)
            let levelMark  = mySelf.getLevelIndicator(for: logEntry.level)
            let level      = String(describing: logEntry.level).uppercased()
            
            mySelf.writer.writeString("\(dateString) \(timeString) \(levelMark)\(level): \(logEntry.message)",
                                      toUrl: mySelf.logUrl)
        }
        
        loggerQueue.async { [weak self] in
            self?.cleanup()
        }
    }
}


// MARK: - Private helpers

private extension QaLoggerDestination {
    
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
    
    func cleanup() {
        
        // sort the log file names so that the oldest files are at the beginning of the list.
        // delete the oldest files if we're over the maximum.
        var logFileNames = AppFile.getLogFileNames().sorted()
        while logFileNames.count > maxLogFileCount {
            let fileUrl = AppFile.loggingDirectory.appendingPathComponent(logFileNames.first!)
            do {
                try FileManager.default.removeItem(at: fileUrl)
            }
            catch {
                // note: there's no need to tell the user about this.
                logger.error("Error: Log file could not be deleted: \(error.localizedDescription) " +
                             "- \(fileUrl.absoluteString)")
            }
            
            logFileNames.remove(at: 0)
        }
    }
}


// MARK: - Standard console writer

fileprivate final class QaLoggerDestinationWriter: QaLoggerDestinationWriting {
    
    func writeString(_ logString: String, toUrl url: URL) {
        
        let logLine = logString + "\n"
        
        // NOTE: This DOES NOT use `FileManager.fileExists()` to check if the file exists first because Apple's
        //       documentation indicates that doing that can be problematic:
        //       "Attempting to predicate behavior based on the current state of the file system or a particular file
        //        on the file system is not recommended. Doing so can cause odd behavior or race conditions. It’s far
        //        better to attempt an operation (such as loading a file or creating a directory), check for errors,
        //        and handle those errors gracefully than it is to try to figure out ahead of time whether the
        //        operation will succeed."
        //       The unreliability of `FileManager.fileExists()` has also been confirmed in testing. For example,
        //       it still returns `false` shortly after `logString.write()` is called.
        
        guard let fileHandle = try? FileHandle(forWritingTo: url) else {
            // the file doesn't exists yet, so use `String.write()` to create it.
            do {
                try logLine.write(to: url, atomically: true, encoding: .utf8)
            }
            catch {
                print("Error: Creating log file failed: \(error.localizedDescription)\n" +
                      "  File path: \(url.absoluteString)")
            }

            return
        }
        
        guard let logData = logLine.data(using: .utf8) else {
            print("Error: Log message string (\(logString)) could not be converted to a Data object.")
            return
        }
        
        fileHandle.seekToEndOfFile()
        fileHandle.write(logData)
        fileHandle.closeFile()
    }
}
