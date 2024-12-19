//
//  RetryIf.swift
//  XKit
//
//  Created by xueqooy on 2023/9/12.
//

import Combine
import Foundation

public extension Publisher {
    func retry(_ maxRetries: Int, if shouldRetry: @escaping (_ error: Failure, _ triesAlready: Int) -> Bool) -> Publishers.RetryIf<Self, RunLoop> {
        .init(upstream: self, triesLeft: maxRetries, triesAlready: 0, shouldRetry: shouldRetry)
    }

    func retry<S>(_ maxRetries: Int, delayOptions: RetryDelayOptions<S>, if shouldRetry: @escaping (_ error: Failure, _ triesAlready: Int) -> Bool) -> Publishers.RetryIf<Self, S> {
        .init(upstream: self, triesLeft: maxRetries, triesAlready: 0, delayOptions: delayOptions, shouldRetry: shouldRetry)
    }
}

public enum RetryDelayBehavior {
    case fixed(_ delay: TimeInterval)
    case exponential(initial: TimeInterval, multiplier: Double)
    case custom(_ calculator: (_ triesAlready: Int) -> TimeInterval)
}

public struct RetryDelayOptions<Context: Scheduler> {
    typealias Stride = Context.SchedulerTimeType.Stride
    typealias Provider = (_ triesAlready: Int) -> Stride

    public let scheduler: Context

    fileprivate let provider: Provider

    public init(scheduler: Context, behavior: RetryDelayBehavior) {
        self.scheduler = scheduler

        switch behavior {
        case let .fixed(delay):
            provider = { _ in
                .seconds(delay)
            }

        case let .exponential(initial, multiplier):
            provider = {
                .seconds($0 == 0 ? initial : initial * pow(1 + multiplier, Double($0)))
            }

        case let .custom(calculator):
            provider = {
                .seconds(calculator($0))
            }
        }
    }
}

public extension Publishers {
    struct RetryIf<Upstream: Publisher, DelayContext: Scheduler>: Publisher {
        public typealias Output = Upstream.Output
        public typealias Failure = Upstream.Failure

        public typealias ShouldRetry = (_ error: Failure, _ triesAlready: Int) -> Bool

        private let upstream: Upstream
        private let triesLeft: Int
        private let triesAlready: Int
        private let shouldRetry: ShouldRetry
        private let delayOptions: RetryDelayOptions<DelayContext>?

        public init(upstream: Upstream, triesLeft: Int, triesAlready: Int, delayOptions: RetryDelayOptions<DelayContext>? = nil, shouldRetry: @escaping ShouldRetry) {
            self.upstream = upstream
            self.triesLeft = triesLeft
            self.triesAlready = triesAlready
            self.shouldRetry = shouldRetry
            self.delayOptions = delayOptions
        }

        public func receive<Downstream: Subscriber>(subscriber: Downstream) where Failure == Downstream.Failure, Output == Downstream.Input {
            upstream
                .catch {
                    let willRetry = triesLeft > 0 && shouldRetry($0, triesAlready)

                    if willRetry {
                        if let delayOptions {
                            // Retry with delay
                            let scheduler = delayOptions.scheduler
                            let delay = delayOptions.provider(triesAlready)

                            return Future { promise in
                                scheduler.schedule(after: scheduler.now.advanced(by: delay)) {
                                    promise(.success(()))
                                }
                            }.flatMap {
                                Self(upstream: upstream, triesLeft: triesLeft - 1, triesAlready: triesAlready + 1, delayOptions: delayOptions, shouldRetry: shouldRetry)
                            }.eraseToAnyPublisher()

                        } else {
                            // Retry immediately
                            return Self(upstream: upstream, triesLeft: triesLeft - 1, triesAlready: triesAlready + 1, shouldRetry: shouldRetry).eraseToAnyPublisher()
                        }

                    } else {
                        // Do not retry
                        return Fail(error: $0).eraseToAnyPublisher()
                    }
                }
                .receive(subscriber: subscriber)
        }
    }
}
