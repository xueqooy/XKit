//
//  Associated.swift
//  EDKit
//
//  Created by xueqooy on 2023/8/18.
//

import Foundation

public class Association<T> {
    public enum Policy {
        case assign
        case retainNonatomic
        case copyNonatomic
        case retain
        case copy
    }
    
    public enum Wrap {
        case retain
        case weak
    }
    
    private class Retain<T> {
        let value: T
    
        init(_ value: T) {
            self.value = value
        }
    }
    
    private let associationPolicy: objc_AssociationPolicy
    private let wrap: Wrap?
    
    public init(policy: Policy = .retainNonatomic, wrap: Wrap? = .none) {
        switch policy {
        case .assign:
            associationPolicy = .OBJC_ASSOCIATION_ASSIGN
        case .retainNonatomic:
            associationPolicy = .OBJC_ASSOCIATION_RETAIN_NONATOMIC
        case .copyNonatomic:
            associationPolicy = .OBJC_ASSOCIATION_COPY_NONATOMIC
        case .retain:
            associationPolicy = .OBJC_ASSOCIATION_RETAIN
        case .copy:
            associationPolicy = .OBJC_ASSOCIATION_COPY
        }
        
        self.wrap = wrap
    }
    
    public subscript(index: AnyObject) -> T? {
        get {
            switch wrap {
            case .none:
                return objc_getAssociatedObject(index, key) as? T
            case .retain:
                return (objc_getAssociatedObject(index, key) as? Retain<T>)?.value
            case .weak:
                return (objc_getAssociatedObject(index, key) as? Weak<T>)?.value
            }
        }
        set {
            if let value = newValue {
                switch wrap {
                case .none:
                    objc_setAssociatedObject(index, key, value, associationPolicy)
                case .retain:
                    objc_setAssociatedObject(index, key, Retain(value), associationPolicy)
                case .weak:
                    objc_setAssociatedObject(index, key, Weak(value: value), associationPolicy)
                }
            } else {
                objc_setAssociatedObject(index, key, nil, associationPolicy)
            }
        }
    }
    
    private var key: UnsafeMutableRawPointer {
        Unmanaged.passUnretained(self).toOpaque()
    }
}
