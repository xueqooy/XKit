//
//  Lock.swift
//  XKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Darwin

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
typealias UnfairLock = os_unfair_lock_t

@available(macOS 10.12, iOS 10.0, tvOS 10.0, watchOS 3.0, *)
extension UnsafeMutablePointer where Pointee == os_unfair_lock_s {
    internal init() {
        let l = UnsafeMutablePointer.allocate(capacity: 1)
        l.initialize(to: os_unfair_lock())
        self = l
    }
    
    internal func cleanupLock() {
        deinitialize(count: 1)
        deallocate()
    }
    
    internal func lock() {
        os_unfair_lock_lock(self)
    }
    
    internal func tryLock() -> Bool {
        let result = os_unfair_lock_trylock(self)
        return result
    }
    
    internal func unlock() {
        os_unfair_lock_unlock(self)
    }
}

public class Lock {
    
    private let _lock: UnfairLock
    
    public init() {
        _lock = UnfairLock()
    }
    
    deinit {
        _lock.cleanupLock()
    }
    
    public func lock() {
        _lock.lock()
    }
    
    public func unlock() {
        _lock.unlock()
    }
    
    public func tryLock() -> Bool {
        return _lock.tryLock()
    }
    
    @discardableResult
    public func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock()
        defer { unlock() }
        return try body()
    }
}


