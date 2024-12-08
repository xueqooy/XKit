//
//  Atomic.swift
//  XKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Foundation

public final class Atomic<T> {
    private let lock: Lock
    private var _value: T
    
    public var value: T {
        lock.enter()
        let value = self._value
        lock.leave()
        
        return value
    }
    
    public init(value: T) {
        lock = Lock()
        _value = value
    }
    
    @discardableResult
    public func with<R>(_ f: (T) -> R) -> R {
        lock.enter()
        let result = f(_value)
        lock.leave()
        
        return result
    }
    
    @discardableResult
    public func modify(_ f: (T) -> T) -> T {
        lock.enter()
        let result = f(_value)
        _value = result
        lock.leave()
        
        return result
    }
    
    @discardableResult
    public func swap(_ value: T) -> T {
        lock.enter()
        let previous = self._value
        self._value = value
        lock.leave()
        
        return previous
    }
}

