//
//  TriState.swift
//  XKit
//
//  Created by xueqooy on 2024/4/18.
//

import Foundation

public enum TriState<T> {
    case indeterminate
    case absent
    case present(T)

    public var isPresent: Bool {
        if case .present = self {
            return true
        }
        return false
    }

    public var isAbsent: Bool {
        if case .absent = self {
            return true
        }
        return false
    }

    public var isIndeterminate: Bool {
        if case .indeterminate = self {
            return true
        }
        return false
    }

    public var value: T? {
        if case let .present(val) = self {
            return val
        } else {
            return nil
        }
    }

    public init(_ value: T?) {
        if let value = value {
            self = .present(value)
        } else {
            self = .absent
        }
    }
}

extension TriState: Equatable where T: Equatable {}

extension TriState: Hashable where T: Hashable {}
