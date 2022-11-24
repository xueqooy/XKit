//
//  Lock.swift
//  EDKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Foundation

public final class Lock: NSObject {
    private var mutex = pthread_mutex_t()
    
    public override init() {
        pthread_mutex_init(&mutex, nil)
        
        super.init()
    }
    
    deinit {
        pthread_mutex_destroy(&mutex)
    }
    
    @objc
    public func execute(_ work: () -> Void) {
        pthread_mutex_lock(&mutex)
        work()
        pthread_mutex_unlock(&mutex)
    }
    
    @objc
    public func enter() {
        pthread_mutex_lock(&mutex)
    }
    
    @objc
    public func leave() {
        pthread_mutex_unlock(&mutex)
    }
}

