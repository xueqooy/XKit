//
//  Asserts.swift
//  XKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Foundation

public struct Asserts {

    public static func failure(_ message: @autoclosure () -> String = "",
                               condition: @autoclosure () -> Bool = false,
                               tag: String? = nil,
                               file: String = #file,
                               function: String = #function,
                               line: Int = #line) {
        guard !condition() else { return }
        
        let msg = message()
        Logs.error(msg.isEmpty ? "Assertion failed." : "Assertion failed: \(msg)", tag: tag,  file: file, function: function, line: line)
        assertionFailure(msg)
    }
     
    public static func mainThread(tag: String? = nil,
                                  file: String = #file,
                                  function: String = #function,
                                  line: Int = #line) {
        failure("Must be on main thread", condition: Thread.isMainThread == true, tag: tag, file: file, function: function, line: line)
    }
    
    public static func notMainThread(tag: String? = nil,
                                     file: String = #file,
                                     function: String = #function,
                                     line: Int = #line) {
        failure("Must be called off the main thread", condition: Thread.isMainThread == false, tag: tag, file: file, function: function, line: line)
    }
}
