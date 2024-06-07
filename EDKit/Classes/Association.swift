//
//  Associated.swift
//  EDKit
//
//  Created by xueqooy on 2023/8/18.
//

import Foundation

/**
struct CustomStruct {}
class CustomObject {}
typealias Block = () -> Void

extension UIView {
    private struct Associations {
        // The default is not to use wrap, that is, wrap to `none`
        static let objectAssociation = Association<CustomObject>()
 
        // Using `weak` wrap for weakly referenced associative object
        static let weakObjectAssociation = Association<CustomObject>(wrap: .weak)
 
        // It is recommended to use `retain` wrap for custom value types. For types that can be bridged to objc, such as String, Bool, Int, etc., Wrap may not be used
        // However, after Swift3, the custom value type will be converted to `SwiftValue` in objc, and Wrap may not be used.
        static let structAssociation = Association<CustomStruct>(wrap: .retain)
                
        // Associate closures must use `retain` wrap
        static let blockAssociation = Association<Block>(wrap: .retain)
    }

    var customStruct: CustomStruct? {
        get { Associations.structAssociation[self] }
        set { Associations.structAssociation[self] = newValue }
    }

    var customObject: CustomObject? {
        get { Associations.objectAssociation[self] }
        set { Associations.objectAssociation[self] = newValue }
    }

    var weakCustomObject: CustomObject? {
        get { Associations.weakObjectAssociation[self] }
        set { Associations.weakObjectAssociation[self] = newValue }
    }

    var block: Block? {
        get { Associations.blockAssociation[self] }
        set { Associations.blockAssociation[self] = newValue }
    }
}

*/

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
        case weak // Only used for class type
    }
    
    private class Retain<Value> {
        let value: Value
    
        init(_ value: Value) {
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
                return (objc_getAssociatedObject(index, key) as? UncheckedWeak<T>)?.value
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
                    objc_setAssociatedObject(index, key, UncheckedWeak(value), associationPolicy)
                }
            } else {
                objc_setAssociatedObject(index, key, nil, associationPolicy)
            }
        }
    }
    
    private var key: UnsafeRawPointer {
        UnsafeRawPointer(Unmanaged.passUnretained(self).toOpaque())
    }
}



// TODO: DELETE ME IN FUTURE
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
