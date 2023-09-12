//
//  RetryIf.swift
//  EDKit
//
//  Created by xueqooy on 2023/9/12.
//

import Combine

public extension Publisher {
    func retry(_ retries: Int, if shouldRetry: @escaping (Failure) -> Bool) -> Publishers.RetryIf<Self> {
        .init(upstream: self, triesLeft: retries, shouldRetry: shouldRetry)
    }
}

public extension Publishers {
    public struct RetryIf<Upstream: Publisher>: Publisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure

        var upstream: Upstream
        var triesLeft: Int
        var shouldRetry: (Failure) -> Bool
        
        public init(upstream: Upstream, triesLeft: Int, shouldRetry: @escaping (Failure) -> Bool) {
            self.upstream = upstream
            self.triesLeft = triesLeft
            self.shouldRetry = shouldRetry
        }

        public func receive<Downstream: Subscriber>(subscriber: Downstream) where Failure == Downstream.Failure, Output == Downstream.Input {
            upstream
                .catch {
                    triesLeft > 0 && shouldRetry($0)
                        ? Self(upstream: upstream, triesLeft: triesLeft - 1, shouldRetry: shouldRetry).eraseToAnyPublisher()
                        : Fail(error: $0).eraseToAnyPublisher()
                }
                .receive(subscriber: subscriber)
        }
    }
}
