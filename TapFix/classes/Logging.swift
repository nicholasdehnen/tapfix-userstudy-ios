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

func buildWillowLogger(name: String) -> Logger
{
    #if DEBUG
        return Logger(logLevels: [.all], writers: [ConsoleWriter(modifiers: [EmojiPrefixModifier(name: name)])])
    #else
        let osLogWriter = OSLogWriter(subsystem: "co.dehnen.tapfix", category: name)
        let appLogLevels: LogLevel = [.event, .info, .warn, .error]
        let asynchronousExec: Logger.ExecutionMethod = .asynchronous(
            queue: DispatchQueue(label: "co.dehnen.tapfix", qos: .utility))
        
        return Logger(logLevels: appLogLevels, writers: [osLogWriter], executionMethod: asynchronousExec)
    #endif
}
