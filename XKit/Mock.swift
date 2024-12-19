//
//  Mock.swift
//  llp_x_cloud_assemble_ios
//
//  Created by xueqooy on 2024/10/22.
//

import Foundation

// MARK: - Definitions

public protocol Mockable {
    static func mock() -> Self
}

public struct DefaultMockError: Error {
    public init() {}
}

public struct MockOption<T: Mockable> {
    fileprivate let delay: TimeInterval

    fileprivate var shouldMock: Bool {
        mockBody != nil
    }

    fileprivate let mockBody: (() -> Result<T, Error>)?

    public init(delay: TimeInterval = 2, mockBody: (() -> Result<T, Error>)? = nil) {
        self.delay = delay
        self.mockBody = mockBody
    }

    public static func nonMock() -> MockOption<T> {
        .init()
    }

    public static func failure(delay: TimeInterval = 2, error: Error = DefaultMockError()) -> MockOption {
        .init(delay: delay) {
            Result.failure(error)
        }
    }

    /// Default mock
    public static func success(delay: TimeInterval = 2) -> MockOption {
        .init(delay: delay) {
            Result.success(T.mock())
        }
    }

    /// Mock for Optional
    public static func success<V: Mockable>(delay: TimeInterval = 2, allowsNil: Bool = true) -> MockOption where T == V? {
        .init(delay: delay) {
            Result.success(allowsNil ? T.mock() : V.mock())
        }
    }

    /// Mock for Array
    public static func success<V: Mockable>(delay: TimeInterval = 2, elementCountRange: ClosedRange<Int>) -> MockOption where T == [V] {
        .init(delay: delay) {
            Result.success(T.mock(elementCountIn: elementCountRange))
        }
    }

    /// Mock for Array
    public static func success<V: Mockable>(delay: TimeInterval = 2, elementCount: Int) -> MockOption where T == [V] {
        .init(delay: delay) {
            Result.success(T.mock(elementCount: elementCount))
        }
    }

    /// Mock for Dictionary
    public static func success<K: Mockable, V: Mockable>(delay: TimeInterval = 2, keys: [K], allowsNilValue: Bool = false) -> MockOption where T == [K: V] {
        .init(delay: delay) {
            Result.success(T.mock(keys: keys, allowsNilValue: allowsNilValue))
        }
    }
}

// MARK: - Mock Extensions

public extension Mockable {
    static func optionalMock() -> Self? {
        Bool.random() ? mock() : nil
    }

    static func mocks(count: Int) -> [Self] {
        (0 ..< count).map { _ in
            mock()
        }
    }

    static func mocks(countIn range: ClosedRange<Int>) -> [Self] {
        let count = Int.random(in: range)

        return (0 ..< count).map { _ in
            mock()
        }
    }
}

extension Bool: Mockable {
    public static func mock() -> Bool {
        .random()
    }
}

extension String: Mockable {
    public static func mock() -> String {
        .random(0 ... 50)
    }
}

extension Int: Mockable {
    public static func mock() -> Int {
        .random(in: 0 ... 50)
    }
}

extension Date: Mockable {
    public static func mock() -> Date {
        .random()
    }
}

extension Optional: Mockable where Wrapped: Mockable {
    public static func mock() -> Wrapped? {
        Bool.random() ? Wrapped.mock() : nil
    }
}

extension Array: Mockable where Element: Mockable {
    public static func mock() -> [Element] {
        (0 ..< Int.mock()).map { _ in
            Element.mock()
        }
    }

    public static func mock(elementCount: Int) -> [Element] {
        (0 ..< elementCount).map { _ in
            Element.mock()
        }
    }

    public static func mock(elementCountIn range: ClosedRange<Int>) -> [Element] {
        let count = Int.random(in: range)

        return (0 ..< count).map { _ in
            Element.mock()
        }
    }
}

extension Dictionary: Mockable where Key: Mockable, Value: Mockable {
    public static func mock() -> [Key: Value] {
        var dict = Self()

        for _ in 0 ..< Int.mock() {
            let key = Key.mock()
            let value = Value.mock()
            dict[key] = value
        }

        return dict
    }

    public static func mock(keys: [Key], allowsNilValue: Bool = false) -> [Key: Value] {
        var dict = Self()

        for key in keys {
            dict[key] = allowsNilValue ? Value.mock() : Value.optionalMock()
        }

        return dict
    }
}

// MARK: - Methods

public func withMockableCheckedThrowingContinuation<T: Mockable>(function: String = #function, mockOption: MockOption<T> = .nonMock(), _ nonMockBody: (CheckedContinuation<T, Error>) -> Void) async throws -> T {
//    #if !DEBUG
//    // Do not use mock data in production environments
//    let mockOption: MockOpiton<T> = .nonMock()
//    #endif

    if let mockBody = mockOption.mockBody {
        Logs.warn("Use mock data for \(function)")
        return try await withCheckedThrowingContinuation { continuation in

            Queue.main.execute(mockOption.delay > 0 ? .delay(mockOption.delay) : .async) {
                let mockResult = mockBody()

                continuation.resume(with: mockResult)
            }
        }
    } else {
        return try await withCheckedThrowingContinuation(nonMockBody)
    }
}
