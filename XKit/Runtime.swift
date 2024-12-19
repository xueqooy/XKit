//
//  Runtime.swift
//  XKit
//
//  Created by 🌊 薛 on 2022/10/18.
//

import Foundation

/**
 Example code:
 ```
 class Human {
     @objc dynamic func walk() {
         print("walk")
     }

     @objc dynamic func swizzle_walk() {
         print("walk (swizzled)")
     }

     @objc dynamic func speak(_ words: String) {
         print(words)
     }

     @objc dynamic func doWork(_ task: String) -> String {
         if task.count > 5 {
             return "failure"
         } else {
             return "success"
         }
     }
 }

 // Swizzle
 exchangeImplementations(Human.self, originSelector: #selector(Human.walk), newSelector: #selector(Human.swizzle_walk))

 // Void Return Type and Empty Arg
 overrideImplementation(Human.self, selector: #selector(Human.walk)) { originClass, originSelector,    originIMPProvider in
     return ({ (object: AnyObject) -> Void in
         // call origin impl
         let oriIMP = unsafeBitCast(originIMPProvider(), to: (@convention(c) (AnyObject, Selector) -> Void).self)
         oriIMP(object, originSelector)

         print("has override walk method")
     } as @convention(block) (AnyObject) -> Void)
 }

 // Void Return Type and Single Arg
 overrideImplementation(Human.self, selector: #selector(Human.speak(_:))) { originClass, originSelector,    originIMPProvider in
     return ({ (object: AnyObject, words: String) -> Void in
         // call origin impl
         let oriIMP = unsafeBitCast(originIMPProvider(), to: (@convention(c) (AnyObject, Selector, String) -> Void).self)
         oriIMP(object, originSelector, words)

         print("has override speak method")
     } as @convention(block) (AnyObject, String) -> Void)
 }

 // Non-Void Return Type and Single Arg
 overrideImplementation(Human.self, selector: #selector(Human.doWork(_:))) { originClass, originSelector, originIMPProvider in
     return ({ (object: AnyObject, task: String) -> String in
         // call origin impl
         let oriIMP = unsafeBitCast(originIMPProvider(), to: (@convention(c) (AnyObject, Selector, String) -> String).self)
         let result = oriIMP(object, originSelector, task)

         print("has override doWork method")

         return result
     } as @convention(block) (AnyObject, String) -> String)
 }

 ```

 */

/// Whether the target class overrides instance method of the  superclass
public func hasOverrideSuperclassMethod(_ klass: AnyClass, selector: Selector) -> Bool {
    guard let method = class_getInstanceMethod(klass, selector) else {
        return false
    }

    guard let methodOfSuperclass = class_getInstanceMethod(class_getSuperclass(klass), selector) else {
        return true
    }

    return method != methodOfSuperclass
}

/// Swizzle method implementations.
///
/// - note: For swift, the key words of methods @objc and dynamic are necessary.
@discardableResult
public func exchangeImplementations(_ klass: AnyClass, originSelector: Selector, newSelector: Selector) -> Bool {
    guard let oriMethod = class_getInstanceMethod(klass, originSelector),
          let newMethod = class_getInstanceMethod(klass, newSelector)
    else {
        return false
    }

    // If the class does not have the IMP of the original method, it means that in the method implementation inherited from the superclass, we need to add an originalSelector method to the class, but use newMethod implementation.
    if class_addMethod(klass, originSelector, method_getImplementation(newMethod), method_getTypeEncoding(newMethod)) {
        class_replaceMethod(klass, newSelector,
                            method_getImplementation(oriMethod),
                            method_getTypeEncoding(oriMethod))
    } else {
        method_exchangeImplementations(oriMethod, newMethod)
    }
    return true
}

/// Ovrride method implementation with block.
///
/// - parameter block:  The block should return a block which signature should be: method_return_type ^(id self, method_args...).
/// - note: For swift, the key words of methods @objc, dynamic and @convention(block) are necessary.
@discardableResult
public func overrideImplementation(_ klass: AnyClass, selector: Selector, block: (_ originClass: AnyClass, _ originSelector: Selector, _ originIMPProvider: @escaping () -> IMP) -> Any) -> Bool {
    guard let originMethod = class_getInstanceMethod(klass, selector) else {
        return false
    }

    let imp = method_getImplementation(originMethod)
    let hasOverride = hasOverrideSuperclassMethod(klass, selector: selector)

    let originIMPProvider = {
        var result: IMP?
        if hasOverride {
            result = imp
        } else {
            // if not override, origin IMP is superclass's IMP
            let superclass: AnyClass? = class_getSuperclass(klass)
            result = class_getMethodImplementation(superclass, selector)
        }

        if result == nil {
            // This is a guarantee, to avoid crash
            result = imp_implementationWithBlock { (_: AnyObject) in
                Logs.warn("\(klass) has no original implementation for \(selector)\n \(Thread.callStackSymbols)")
            }
        }

        return result!
    }

    if hasOverride {
        method_setImplementation(originMethod, imp_implementationWithBlock(block(klass, selector, originIMPProvider)))
    } else {
        class_addMethod(klass, selector, imp_implementationWithBlock(block(klass, selector, originIMPProvider)), method_getTypeEncoding(originMethod))
    }

    return true
}

public class RuntimeObjc: NSObject {
    @discardableResult
    @objc public static func hasOverrideSuperclassMethod(_ klass: AnyClass, selector: Selector) -> Bool {
        XKit.hasOverrideSuperclassMethod(klass, selector: selector)
    }

    @discardableResult
    @objc public static func exchangeImplementations(_ klass: AnyClass, originSelector: Selector, newSelector: Selector) -> Bool {
        XKit.exchangeImplementations(klass, originSelector: originSelector, newSelector: newSelector)
    }

    @discardableResult
    @objc public static func overrideImplementation(_ klass: AnyClass, selector: Selector, block: (_ originClass: AnyClass, _ originSelector: Selector, _ originIMPProvider: @escaping () -> IMP) -> Any) -> Bool {
        XKit.overrideImplementation(klass, selector: selector, block: block)
    }
}
