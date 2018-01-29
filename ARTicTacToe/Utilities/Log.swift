//
//  StringExtension.swift
//  ARTicTacToe
//
//  Created by Gaelle Le Hir on 12/01/2018.
//  Copyright © 2018 Eurelis. All rights reserved.
//

import UIKit


enum LogLevel:Int {
    case Debug = 0
    case Info
    case Warning
    case Error
    case NoLog
}


class Log {
    
    static func debug( log: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        printLog(logLevel: LogLevel.Debug, fileName: fileName, functionName: functionName, lineNumber: lineNumber, log: log)
    }
    
    static func info( log: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        printLog(logLevel: LogLevel.Info, fileName: fileName, functionName: functionName, lineNumber: lineNumber, log: log)
    }
    
    static func warning( log: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        printLog(logLevel: LogLevel.Warning, fileName: fileName, functionName: functionName, lineNumber: lineNumber, log: log)
    }
    
    static func error( log: @autoclosure () -> String?, functionName: String = #function, fileName: String = #file, lineNumber: Int = #line) {
        printLog(logLevel: LogLevel.Error, fileName: fileName, functionName: functionName, lineNumber: lineNumber, log: log)
    }

    private static func getCurrentTime() -> String {
        let currentTimeInterval = NSDate().timeIntervalSince1970
        let currentDate = NSDate(timeIntervalSince1970: currentTimeInterval)
        let dateFormatterDate = DateFormatter()
        dateFormatterDate.dateFormat = "yyyy-MM-dd HH:mm:ss.SSS"
        let time = dateFormatterDate.string(from: currentDate as Date)
        return time
    }
    
    private static func printLog(logLevel: LogLevel, fileName: String = #file, functionName: String = #function, lineNumber: Int = #line, log: () -> String?) {
        if logLevel.rawValue >= GlobalVars.debugLevel  {
            var icon:String
            var type:String
            switch logLevel {
                case LogLevel.Debug:
                    icon = "🌀"
                    type = "Debug"
                case LogLevel.Info:
                    icon = "🍀"
                    type = "Info"
                case LogLevel.Warning:
                    icon = "⚠️"
                    type = "Warning"
                case LogLevel.Error:
                    icon = "❌"
                    type = "Error"
                case LogLevel.NoLog:
                    icon = ""
                    type = ""
            }
            
            // Remove parameter part of function name
            var finalFunctionName = functionName
            if let leftParenthesisPosition = functionName.index(of: "(") {
                finalFunctionName = String(functionName.prefix(upTo: leftParenthesisPosition))
            }
            
            if let logMessage = log() {
                let filePath:NSURL = NSURL(string: fileName)!
                
                // Remove parameter part of function name
                var finalFileName = filePath.lastPathComponent!
                if let dotPosition = finalFileName.index(of: ".") {
                    finalFileName = String(finalFileName.prefix(upTo: dotPosition))
                }
                
                print("\(icon) [\(type)][\(finalFileName)][\(finalFunctionName)-\(lineNumber)] \(logMessage)")
            }
        }
    }
}
