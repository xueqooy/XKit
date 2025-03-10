//
//  Timer.swift
//  XKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Foundation

public final class Timer {
    public var isRunning: Bool {
        timer.value != nil
    }

    public let interval: Double
    public let isRepeated: Bool
    public let work: () -> Void
    public let queue: Executing

    private let timer = Atomic<DispatchSourceTimer?>(value: nil)

    public init(interval: Double, isRepeated: Bool = false, queue: Executing = Queue.main, work: @escaping () -> Void) {
        self.interval = interval
        self.isRepeated = isRepeated
        self.queue = queue
        self.work = work
    }

    deinit {
        stop()
    }

    public func start() {
        stop()

        let timer = DispatchSource.makeTimerSource(queue: queue.underlyingQueue)
        timer.setEventHandler(handler: { [weak self] in
            guard let self = self else {
                return
            }

            self.work()
            if !self.isRepeated {
                self.stop()
            }
        })
        self.timer.modify { _ in timer }

        let deadline = DispatchTime.now() + interval
        if isRepeated {
            timer.schedule(deadline: deadline, repeating: interval)
        } else {
            timer.schedule(deadline: deadline)
        }

        timer.resume()
    }

    public func fire() {
        if isRunning {
            work()

            if !isRepeated {
                stop()
            }
        }
    }

    public func stop() {
        timer.modify { timer in
            timer?.cancel()
            return nil
        }
    }
}
