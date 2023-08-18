//
//  Associated.swift
//  EDKit
//
//  Created by xueqooy on 2023/8/18.
//

import Foundation

public class AssociatedWrapper<Base> {
    let base: Base
    init(_ base: Base) {
        self.base = base
    }
}

public protocol AssociatedCompatible {
    associatedtype AssociatedCompatibleType
    var associated: AssociatedCompatibleType { get }
}

public extension AssociatedCompatible {
    var associated: AssociatedWrapper<Self> {
        get { return AssociatedWrapper(self) }
    }
}

extension NSObject: AssociatedCompatible {}

public extension AssociatedWrapper where Base: NSObject {
    enum Policy {
        case nonatomic
        case atomic
    }
    
    func get<T>(_ key: UnsafeRawPointer) -> T? {
        guard let value = objc_getAssociatedObject(base, key) else {
            return nil
        }
        return (value as! T)
        // 💣 Xcode 14.0 iOS12 Release Mode Crash
        //objc_getAssociatedObject(base, key) as? T
    }
    
    /// OBJC_ASSOCIATION_ASSIGN
    func set(assign key: UnsafeRawPointer, _ value: Any) {
        objc_setAssociatedObject(base, key, value, .OBJC_ASSOCIATION_ASSIGN)
    }
    
    /// OBJC_ASSOCIATION_RETAIN_NONATOMIC / OBJC_ASSOCIATION_RETAIN
    func set(retain key: UnsafeRawPointer, _ value: Any?, _ policy: Policy = .nonatomic) {
        switch policy {
        case .nonatomic:
            objc_setAssociatedObject(base, key, value, .OBJC_ASSOCIATION_RETAIN_NONATOMIC)
        case .atomic:
            objc_setAssociatedObject(base, key, value, .OBJC_ASSOCIATION_RETAIN)
        }
    }
    
    /// OBJC_ASSOCIATION_COPY_NONATOMIC / OBJC_ASSOCIATION_COPY
    func set(copy key: UnsafeRawPointer, _ value: Any?, _ policy: Policy = .nonatomic) {
        switch policy {
        case .nonatomic:
            objc_setAssociatedObject(base, key, value, .OBJC_ASSOCIATION_COPY_NONATOMIC)
        case .atomic:
            objc_setAssociatedObject(base, key, value, .OBJC_ASSOCIATION_COPY)
        }
    }
}
