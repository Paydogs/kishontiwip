//
//  AppleLoggerAdapter.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

import Foundation
import Logging

struct AppleLoggerAdapter: LoggerInterface {
    private let logger = Logger(label: "")
    
    static func bootstrapStandardOutputWithLogLevel(level: Logger.Level = .trace) {
        LoggingSystem.bootstrap { (label: String) -> any LogHandler in
            var handler = StreamLogHandler.standardOutput(label: label)
            handler.logLevel = level
            return handler
        }
    }
    
    func trace(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        logger.trace(.init(stringLiteral: message()))
    }
    
    func debug(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        logger.debug(.init(stringLiteral: message()))
    }
    
    func info(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        logger.info(.init(stringLiteral: message()))
    }
    
    func warn(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        logger.warning(.init(stringLiteral: message()))
    }
    
    func error(_ message: @autoclosure () -> String, file: String, function: String, line: Int) {
        logger.error(.init(stringLiteral: message()))
    }
    
    func fatal(_ message: @autoclosure () -> String, file: String, function: String, line: Int) -> Never {
        logger.critical(.init(stringLiteral: message()))
        fatalError(message())
    }
}
