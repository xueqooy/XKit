//
//  Pipe.swift
//  EDKit
//
//  Created by 🌊 薛 on 2022/9/27.
//

import Foundation

private let pipeValueUserInfoKey = "Pipe.Value"

private class PipeContext {
    var isInvalidated: Bool = false

    var hasSunk: Bool = false
    var latestValue: Any?
    
    fileprivate let notificationCenter = NotificationCenter()
}


public class PipeChannel {
    public var isInvalidated: Bool {
        context.isInvalidated
    }
    
    fileprivate let name: NSNotification.Name
    fileprivate let context: PipeContext
    
    fileprivate init(name: NSNotification.Name, context: PipeContext) {
        self.name = name
        self.context = context
    }
}


public class PipeSinkChannel<T>: PipeChannel {
    @discardableResult
    public func write(_ value: T?) -> Bool {
        if self.isInvalidated {
            return false
        }
        
        context.hasSunk = true
        context.latestValue = value
        
        var userInfo: [AnyHashable : Any]?
        if let value = value {
            userInfo = [pipeValueUserInfoKey : value]
        }
        
        context.notificationCenter.post(name: name, object: nil, userInfo: userInfo)
        
        return true
    }
}


public class PipeSourceToken {
    
    public var onInvalidation: (() -> Void)?
    
    private weak var observer: AnyObject?
    private var notificationCenter: NotificationCenter
    
    fileprivate init(observer: AnyObject, notificationCenter: NotificationCenter) {
        self.observer = observer
        self.notificationCenter = notificationCenter
    }
    
    deinit {
        invalidate()
    }
    
    public func invalidate() {
        if let observer = observer {
            notificationCenter.removeObserver(observer)
            self.observer = nil
            
            onInvalidation?()
        }
    }
}


public class PipeSourceChannel<T>: PipeChannel {
    private var tokens = NSHashTable<PipeSourceToken>.weakObjects()
    
    deinit {
        invalidateTokens()
    }
    
    fileprivate func invalidateTokens() {
        let enumerator = tokens.objectEnumerator()
        while let token = enumerator.nextObject() as? PipeSourceToken {
            token.invalidate()
        }
    }
    
    public func read(onQueue queue: Executing? = nil, replay: Bool = false, block: @escaping (T?) -> Void) -> PipeSourceToken? {
        if self.isInvalidated {
            return nil
        }
        
        let observer = context.notificationCenter.addObserver(forName: name, object: nil, queue: nil, using: { note in
            let work = {
                let value = note.userInfo?[pipeValueUserInfoKey]
                block(value as? T)
            }
            
            if let queue = queue {
                queue.execute(work)
            } else {
                work()
            }
        })
        
        let token = PipeSourceToken(observer: observer, notificationCenter: context.notificationCenter)
        
        tokens.add(token)
                
        if replay && context.hasSunk {
            block(context.latestValue as? T)
        }
        
        return token
    }
}

public class Pipe<T> {
    
    private let context = PipeContext()
    
    public let sinkChannel: PipeSinkChannel<T>
    public let sourceChannel: PipeSourceChannel<T>
    
    public init() {
        let name = Notification.Name(rawValue: "Pipe-" + UUID().uuidString)
        
        sinkChannel = PipeSinkChannel<T>(name: name, context: context)
        sourceChannel = PipeSourceChannel<T>(name: name, context: context)
    }
    
    deinit {
        context.isInvalidated = true
        sourceChannel.invalidateTokens()
    }
}
