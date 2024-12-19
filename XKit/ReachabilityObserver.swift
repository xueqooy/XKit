//
//  ReachabilityObserver.swift
//  XKit
//
//  Created by xueqooy on 2024/12/4.
//

import Combine
import Foundation

public class ReachabilityObserver {
    public typealias Connection = Reachability.Connection

    private static var allObservers = WeakArray<ReachabilityObserver>()
    private static var reachability = try? Reachability()

    public var connectionPulisher: AnyPublisher<Connection, Never> {
        connectionSubject
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }

    private lazy var connectionSubject = CurrentValueSubject<Connection, Never>(connection)

    public var connection: Connection {
        Self.reachability?.connection ?? .unavailable
    }

    private var observation: AnyCancellable?

    public init() {
        Self.allObservers.append(self)

        startObserving()
    }

    deinit {
        stopObserving()
    }

    private func startObserving() {
        if Self.reachability == nil {
            Self.reachability = try? Reachability()
        }

        guard let reachability = Self.reachability else { return }

        try? reachability.startNotifier()

        observation = NotificationCenter.default.publisher(for: .reachabilityChanged, object: reachability)
            .sink { [weak self] _ in
                guard let self else { return }

                self.connectionSubject.send(self.connection)
            }
    }

    private func stopObserving() {
        Self.allObservers.removeAll {
            $0 === self
        }

        if let reachability = Self.reachability, Self.allObservers.elements.isEmpty {
            reachability.stopNotifier()
            Self.reachability = nil
        }
    }
}
