//
//  WillowLogModifiers.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2024-03-08.
//

import Foundation
import Willow

struct PrefixModifier : LogModifier {
    let prefix: String
    func modifyMessage(_ message: String, with logLevel: LogLevel) -> String {
        return "[\(prefix)] \(message)"
    }
}

struct EmojiPrefixModifier: LogModifier {
    let name: String
    
    func modifyMessage(_ message: String, with logLevel: LogLevel) -> String {
        
        switch logLevel {
        case .debug:
            return "🔬 [\(name)] => \(message)"
        case .info:
            return "💡 [\(name)] => \(message)"
        case .event:
            return "🔵 [\(name)] => \(message)"
        case .warn:
            return "⚠️ [\(name)] => \(message)"
        case .error:
            return "🚨 [\(name)] => \(message)"
        default:
            return "[\(name)] => \(message)"
        }
    }
}

class FileWriter: LogWriter {
    
    private var fileHandle: FileHandle?
    private let fileManager = FileManager.default
    private let logFilePath: String
    private static var sessionTimeStamp: String = ""

    init?(for loggerName: String = "log", useSessionTimeStamp: Bool = true) {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)[0]
        let logDirectory = "\(documentsDirectory)/Logs"
        
        // Generate logFileName
        var logFileName = loggerName
        if useSessionTimeStamp && FileWriter.sessionTimeStamp.isEmpty {
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "dd-MM-yyy_hh-mm"
            let formattedDate = dateFormatter.string(from: Date.now)
            FileWriter.sessionTimeStamp = formattedDate
        }
        if useSessionTimeStamp {
            logFileName += "_\(FileWriter.sessionTimeStamp)"
        }
        logFileName += ".txt"

        // Create Logs directory if it doesn't exist
        if !fileManager.fileExists(atPath: logDirectory) {
            do {
                try fileManager.createDirectory(atPath: logDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                print("Failed to create log directory: \(error)")
                return nil
            }
        }

        self.logFilePath = "\(logDirectory)/\(logFileName)"

        // Create log file if it doesn't exist
        if !fileManager.fileExists(atPath: logFilePath) {
            fileManager.createFile(atPath: logFilePath, contents: nil, attributes: nil)
        }

        // Open the file for writing
        if let fileHandle = FileHandle(forWritingAtPath: logFilePath) {
            self.fileHandle = fileHandle
        } else {
            print("Failed to open file handle for log file at path: \(logFilePath)")
            return nil
        }
    }

    deinit {
        fileHandle?.closeFile()
    }
    
    func writeMessage(_ message: any Willow.LogMessage, logLevel: Willow.LogLevel) {
        let message = "\(message.name): \(message.attributes)"
        self.writeMessage(message, logLevel: logLevel)
    }
    
    public func writeMessage(_ message: String, logLevel: Willow.LogLevel, modifiers: [Willow.LogModifier]?) {
        var message = message
        modifiers?.forEach { message = $0.modifyMessage(message, with: logLevel) }
        self.writeMessage(message, logLevel: logLevel)
    }

    public func writeMessage(_ message: String, logLevel: LogLevel) {
        guard let fileHandle = fileHandle else { return }

        if let data = "\(message)\n".data(using: .utf8) {
            // Move to the end of the file to append the log message
            fileHandle.seekToEndOfFile()
            fileHandle.write(data)
        }
    }
}


func buildWillowLogger(name: String) -> Logger
{
    #if DEBUG
        return Logger(logLevels: [.all], writers: [FileWriter()!, ConsoleWriter(modifiers: [EmojiPrefixModifier(name: name)])])
    #else
        let osLogWriter = OSLogWriter(subsystem: "co.dehnen.tapfix", category: name)
        let appLogLevels: LogLevel = .all //[.event, .info, .warn, .error]
        let asynchronousExec: Logger.ExecutionMethod = .asynchronous(
            queue: DispatchQueue(label: "co.dehnen.tapfix", qos: .utility))
        
    return Logger(logLevels: appLogLevels, writers: [osLogWriter, FileWriter(for: name)!], executionMethod: asynchronousExec)
    #endif
}
