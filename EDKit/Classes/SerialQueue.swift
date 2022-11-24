//
//  SerialQueue.swift
//  EDKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Foundation
import Dispatch

private var sharedQueues = [String : SerialQueue]()
public class SerialQueue: NSObject, WorkQueueType {
    
    public static let main: SerialQueue = SerialQueue(queue: .main)
    
    @objc
    public class func sharedQuene(forName name: String) -> SerialQueue {
        if let queue = sharedQueues[name] {
            return queue
        }
        
        let queue = SerialQueue(name: name)
        sharedQueues[name] = queue
        return queue
    }
    
    @objc
    public class func releaseQueue(forName name: String) {
        sharedQueues[name] = nil
    }
    
    @objc
    public var underlyingQueue: DispatchQueue {
        queue.underlyingQueue
    }
     
    private var queue: Queue
    
    @objc
    public convenience init(name: String) {
        let queue = Queue(label: "com.SerialQueue.\(name)", isConcurrent: false, qos: .default)
        self.init(queue: queue)
    }
    
    private init(queue: Queue) {
        precondition(!queue.isConcurrent)
        self.queue = queue
    }
    
    @objc
    public func execute(_ work: @escaping () -> Void) {
        queue.execute(work: work)
    }
}
