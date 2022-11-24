//
//  Logs.swift
//  EDKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Foundation
import OSLog

public enum LogType: CaseIterable {

    case verbose, info, warn, error
    
    public static var allCases: [LogType] = [.verbose, .info, warn, .error]
    
}

public struct LogItem {

    public var message: String
    public var type: LogType
    public var tag: String?
    public var file: String
    public var line: Int
    public var function: String
    
    public init(message: String, type: LogType, tag: String?, file: String, line: Int, function: String) {
        self.message = message
        self.type = type
        self.tag = tag
        self.file = file
        self.line = line
        self.function = function
    }
    
}

public protocol LogFormatting {
    func format(_ item: LogItem) -> String
}

public protocol Logging: AnyObject {
    var formatter: LogFormatting { get set}
    
    func log(_ item: LogItem)
}


public class DefaultLogFormatter: LogFormatting {
    public func format(_ item: LogItem) -> String {
        let prefix: String
        switch item.type {
        case .verbose:
            prefix = "🔵"
        case .info:
            prefix = "🟢"
        case .warn:
            prefix = "🟡"
        case .error:
            prefix = "🔴"
        }
        return prefix +
        " [\((item.file as NSString).lastPathComponent):\(item.line) \(item.function)]" +
        "\(item.tag != nil ? " <\(item.tag!)>" : "")" +
        " -> \(item.message)"
    }
}

public class ConsoleLogger: Logging {
        
    public static let shared = ConsoleLogger()

    public var allowedLogTypes: [LogType] = LogType.allCases
    public var allowedLogTags: [String]?  // nil means all are allowed
            
    public var formatter: LogFormatting = DefaultLogFormatter()
        
    private var subsystem: String?
    private var category: String?
    
    private lazy var oslogger: OSLog = {
        guard let subsystem = subsystem, let category = category else {
            return OSLog.default
        }
        
        return OSLog(subsystem: subsystem, category: category)
    }()
    
    /**
     Designated initializer
     
     - parameter subsystem: Desired subsystem in log. E.g. "org.example"
     - parameter category: Desired category in log. E.g. "Point of interests."
     
     - note: If both parameters are nil, this method will return a logger configured with `OS_LOG_DEFAULT`.
             If both parameters are non-nil, it will return a logger configured with `os_log_create(subsystem, category)`
     */
    public init(subsystem: String? = nil, category: String? = nil) {
        self.subsystem = subsystem
        self.category = category
    }
    
    public func log(_ item: LogItem) {
        if !allowedLogTypes.contains(item.type) {
            return
        }
        
        if let allowedLogTags = allowedLogTags {
            if let tag = item.tag {
                if !allowedLogTags.contains(tag) {
                    return
                }
            } else {
                return
            }
        }
                
        let formattedMessage = formatter.format(item)
        
        if #available(iOS 12.0, *) {
            let osLogType: OSLogType
            switch item.type {
            case .verbose:
                osLogType = .debug
            case .info, .warn:
                osLogType = .info
            case .error:
                osLogType = .error
            }
            os_log(osLogType, log: oslogger, "%{public}s", formattedMessage)
        } else {
            NSLog(formattedMessage)
        }
    }
    
}




public struct Logs {
    public private(set) static var loggers = [Logging]()
    
    public static func add(_ logger: Logging) {
        if loggers.contains(where: { logger === $0 }) {
            return
        }
        loggers.append(logger)
    }

    public static func remove(_ logger: Logging) {
        loggers.removeAll { logger === $0 }
    }

    public static func verbose(_ message: @autoclosure () -> String,
                               tag: String? = nil,
                               condition: @autoclosure () -> Bool = true,
                               file: String = #file,
                               function: String = #function,
                               line: Int = #line) {
        guard condition() else { return }
        
        loggers.forEach { logger in
            logger.log(LogItem(message: message(), type: .verbose, tag: tag, file: file, line: line, function: function))
        }
   }

    public static func info(_ message: @autoclosure () -> String,
                            tag: String? = nil,
                            condition: @autoclosure () -> Bool = true,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line) {
        guard condition() else { return }
        
        loggers.forEach { logger in
            logger.log(LogItem(message: message(), type: .info, tag: tag, file: file, line: line, function: function))
        }
    }
    
    public static func warn(_ message: @autoclosure () -> String,
                            tag: String? = nil,
                            condition: @autoclosure () -> Bool = true,
                            file: String = #file,
                            function: String = #function,
                            line: Int = #line) {
        guard condition() else { return }
        
        loggers.forEach { logger in
            logger.log(LogItem(message: message(), type: .warn, tag: tag, file: file, line: line, function: function))
        }
    }
    
    public static func error(_ message: @autoclosure () -> String,
                             tag: String? = nil,
                             condition: @autoclosure () -> Bool = true,
                             file: String = #file,
                             function: String = #function,
                             line: Int = #line) {
        guard condition() else { return }
        
        loggers.forEach { logger in
            logger.log(LogItem(message: message(), type: .error, tag: tag, file: file, line: line, function: function))
        }
    }
}
