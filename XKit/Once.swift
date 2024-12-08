//
//  Once.swift
//  XKit
//
//  Created by 🌊 薛 on 2022/10/18.
//

import UIKit

public struct Once {
    private static let lock = Lock()
    private static var executedIdentifiers = Set<String>()
    
    public static func execute(_ identifier: String, work: () -> Void) {
        lock.lock()
        if !executedIdentifiers.contains(identifier) {
            executedIdentifiers.insert(identifier)
            work()
        }
        lock.unlock()
    }
    
    @available(*, unavailable)
    public init() {}
}
