//
//  AppFile.swift
//  FeatherRESTClient
//
//  Created by Rob Vander Sloot on 8/19/21.
//  Copyright © 2021 Random Visual, LLC. All rights reserved.
//
//  This source code is licensed under the MIT license found in the LICENSE file in the root directory of this source tree.
//  https://github.com/robvs/FeatherRESTClient
//

import Foundation


/// Set of static methods used to help with file handling.
struct AppFile {
    
    // MARK: Properties
    
    private static let appDirectoryName = "AvaSysTelehealth"
    
    private static let fileManager: FileManager = { return FileManager.default }()

    private static var appDirectory: URL = {
        guard let documentDirectory: URL = fileManager.urls(for: .documentDirectory, in: .userDomainMask).first else {
            logger.fatal("Could not get the user's documents directory.")
            return URL(fileURLWithPath: "/\(appDirectoryName)", isDirectory: true)
        }
        
        let appDirectoryUrl = documentDirectory.appendingPathComponent(appDirectoryName, isDirectory: true)
        createDirectory(appDirectoryUrl)
        
        return appDirectoryUrl
    }()
    
    static var loggingDirectory: URL = {
        let loggingDirectoryUrl = appDirectory.appendingPathComponent("logs", isDirectory: true)
        createDirectory(loggingDirectoryUrl)
        
        return loggingDirectoryUrl
    }()
    
    private static var directoryDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter
    }()
    
    private static var logFileDateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = NSLocale.current
        formatter.dateFormat = "yyyy-MM-dd"
        
        return formatter
    }()

    
    // MARK: Public methods
    
    static func getLogFileNames() -> [String] {
        
        return getFileNames(in: loggingDirectory)
    }
    
    static func getLogFileUrl(for date: Date) -> URL {
        
        let logFileName = "\(logFileDateFormatter.string(from: date))-log.txt"
        return loggingDirectory.appendingPathComponent(logFileName)
    }
}


// MARK: - Private helpers

private extension AppFile {
    
    static func getFileNames(in directory: URL) -> [String] {
        
        var fileNames: [String] = []
        
        do {
            let fileUrls = try fileManager.contentsOfDirectory(at: directory,
                                                               includingPropertiesForKeys: [URLResourceKey.isRegularFileKey],
                                                               options: [])
            fileNames = fileUrls.map({ return $0.lastPathComponent }).sorted(by: { $0 > $1 })
        }
        catch {
            logger.error("Error: Failed to get file names from directory (\(directory.absoluteString)): " +
                         "\(error.localizedDescription)")
        }
        
        return fileNames
    }
    
    static func createDirectory(_ targetDirectory: URL) {
        
        // NOTE: This DOES NOT check if the directory exists first because Apple's documentation indicates otherwise:
        //       From a note on `FileManager.fileExists()`:
        //       "Attempting to predicate behavior based on the current state of the file system or a particular file
        //        on the file system is not recommended. Doing so can cause odd behavior or race conditions. It’s far
        //        better to attempt an operation (such as loading a file or creating a directory), check for errors,
        //        and handle those errors gracefully than it is to try to figure out ahead of time whether the
        //        operation will succeed."
        
        do {
            try FileManager.default.createDirectory(at: targetDirectory,
                                                    withIntermediateDirectories: true,
                                                    attributes: nil)
        }
        catch {
            logger.error("The directory (\(targetDirectory.absoluteString) could not be created: \(error.localizedDescription)")
        }
    }
}
