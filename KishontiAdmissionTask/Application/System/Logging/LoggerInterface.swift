//
//  LoggerInterface.swift
//  KishontiAdmissionTask
//
//  Created by Andras Olah on 2026. 03. 19..
//

protocol LoggerInterface: Sendable {
    func trace(_ message: @autoclosure () -> String,
               file: String, function: String, line: Int)
    
    func debug(_ message: @autoclosure () -> String,
               file: String, function: String, line: Int)
    
    func info(_ message: @autoclosure () -> String,
              file: String, function: String, line: Int)
    
    func warn(_ message: @autoclosure () -> String,
              file: String, function: String, line: Int)
    
    func error(_ message: @autoclosure () -> String,
               file: String, function: String, line: Int)
    
    func fatal(_ message: @autoclosure () -> String,
               file: String, function: String, line: Int) -> Never
}
