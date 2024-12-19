//
//  Atomic.swift
//  XKit
//
//  Created by xueqooy on 2022/9/21.
//

import Foundation

public final class Atomic<T> {
    private let lock: Lock
    private var _value: T

    public var value: T {
        lock.lock()
        let value = _value
        lock.unlock()

        return value
    }

    public init(value: T) {
        lock = Lock()
        _value = value
    }

    @discardableResult
    public func with<R>(_ f: (T) -> R) -> R {
        lock.lock()
        let result = f(_value)
        lock.unlock()

        return result
    }

    @discardableResult
    public func modify(_ f: (T) -> T) -> T {
        lock.lock()
        let result = f(_value)
        _value = result
        lock.unlock()

        return result
    }

    @discardableResult
    public func swap(_ value: T) -> T {
        lock.lock()
        let previous = _value
        _value = value
        lock.unlock()

        return previous
    }
}
