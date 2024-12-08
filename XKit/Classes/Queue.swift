//
//  Queue.swift
//  XKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Foundation

public protocol Executing {
    var underlyingQueue: DispatchQueue { get }
    
    func execute(_ work: @escaping () -> Void)
}

public extension Executing {
    func execute(_ work: @escaping () -> Void) {
        underlyingQueue.async(execute: work)
    }
}


extension DispatchQueue: Executing {
    public var underlyingQueue: DispatchQueue {
        self
    }
}

public final class Queue {
    public enum Operation {
        case async(forced: Bool = false)
        case sync(forced: Bool = false)
        case delay(_ seconds: TimeInterval)
    }
    
    public static let main: Queue = Queue(underlyingQueue: DispatchQueue.main)
    public static let concurrentDefault: Queue = Queue(underlyingQueue: DispatchQueue.global(qos: .default))
    public static let concurrentBackground: Queue = Queue(underlyingQueue: DispatchQueue.global(qos: .background))

    public let underlyingQueue: DispatchQueue
    public let label: String
    public let qos: DispatchQoS
    public let isConcurrent: Bool
    
    public var isCurrent: Bool {
        DispatchQueue.getSpecific(key: specificKey) != nil
    }
        
    private let specificKey: DispatchSpecificKey<()>
    
    public init(underlyingQueue: DispatchQueue) {
        self.underlyingQueue = underlyingQueue
        
        label = underlyingQueue.label
        qos = underlyingQueue.qos
        let className = "\(underlyingQueue.classForCoder)"
        isConcurrent = className == "OS_dispatch_queue_global" || className == "OS_dispatch_queue_concurrent"
        
        specificKey = DispatchSpecificKey<()>()
        underlyingQueue.setSpecific(key: specificKey, value: ())
    }
    
    public convenience init(label: String, isConcurrent: Bool = false, qos: DispatchQoS = .default) {
        let underlyingQueue = DispatchQueue(label: label, qos: qos, attributes: isConcurrent ? [.concurrent] : [])
        self.init(underlyingQueue: underlyingQueue)
    }
    
    deinit {
        underlyingQueue.setSpecific(key: specificKey, value: nil)
    }
    
    public func execute(_ op: Queue.Operation = .async(), work: @escaping () -> Void) {
        switch op {
        case .async(let forced):
            if forced || !isCurrent {
                underlyingQueue.async(execute: work)
            } else {
                work()
            }
        case .sync(let forced):
            if forced || !isCurrent {
                underlyingQueue.sync(execute: work)
            } else {
                work()
            }
        case .delay(let seconds):
            underlyingQueue.asyncAfter(deadline: .now() + seconds, execute: work)
        }
    }
}

extension Queue: Executing {
    public func execute(_ work: @escaping () -> Void) {
        execute(.async(), work: work)
    }
}

extension Queue: CustomStringConvertible {
    public var description: String {
        "queue: \(underlyingQueue), isConcurrent: \(isConcurrent), qos: \(qos), isCurrent: \(isCurrent)"
    }
}

