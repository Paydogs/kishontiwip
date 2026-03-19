//
//  Logger.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation

public enum Log {
    // Default so logging works before DI is ready
    private static var logger: LoggerInterface?
    
    static func install(_ newLogger: LoggerInterface) {
        logger = newLogger
    }
    
    public static func trace(_ message: @autoclosure () -> String,
                             file: String = #fileID,
                             function: String = #function,
                             line: Int = #line) {
        guard let logger else {
            fatalError("☠️ [\(file):\(line)] \(function) - \(message())")
        }
        logger.trace(message(), file: file, function: function, line: line)
    }
    
    public static func debug(_ message: @autoclosure () -> String,
                             file: String = #fileID,
                             function: String = #function,
                             line: Int = #line) {
        guard let logger else {
            fatalError("☠️ [\(file):\(line)] \(function) - \(message())")
        }
        logger.debug(message(), file: file, function: function, line: line)
    }
    
    public static func info(_ message: @autoclosure () -> String,
                            file: String = #fileID,
                            function: String = #function,
                            line: Int = #line) {
        guard let logger else {
            fatalError("☠️ [\(file):\(line)] \(function) - \(message())")
        }
        logger.info(message(), file: file, function: function, line: line)
    }
    
    public static func warn(_ message: @autoclosure () -> String,
                            file: String = #fileID,
                            function: String = #function,
                            line: Int = #line) {
        guard let logger else {
            fatalError("☠️ [\(file):\(line)] \(function) - \(message())")
        }
        logger.warn(message(), file: file, function: function, line: line)
    }
    
    public static func error(_ message: @autoclosure () -> String,
                             file: String = #fileID,
                             function: String = #function,
                             line: Int = #line) {
        guard let logger else {
            fatalError("☠️ [\(file):\(line)] \(function) - \(message())")
        }
        logger.error(message(), file: file, function: function, line: line)
    }
    
    public static func fatal(_ message: @autoclosure () -> String,
                             file: String = #fileID,
                             function: String = #function,
                             line: Int = #line) {
        guard let logger else {
            fatalError("☠️ [\(file):\(line)] \(function) - \(message())")
        }
        logger.fatal(message(), file: file, function: function, line: line)
    }
}

