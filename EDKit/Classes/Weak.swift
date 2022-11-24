//
//  Weak.swift
//  EDKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Foundation

public struct Weak<T> {
    private weak var _value: AnyObject?
    
    private let identifier: ObjectIdentifier

    public var value: T? {
        _value as? T
    }

    public init(value: T) {
        self.identifier = ObjectIdentifier(value as AnyObject)
        self._value = value as AnyObject
    }
}

extension Weak: Hashable {
    public static func == (lhs: Weak<T>, rhs: Weak<T>) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}

public struct WeakArray<Element> {
    private var store: [Weak<Element>] = []

    public var elements: [Element] {
        store.compactMap { $0.value }
    }

    public var weakReferenceCount: Int {
        store.count
    }

    public mutating func append(_ element: Element) {
        store.append(Weak(value: element))
    }

    public mutating func removeAll(where shouldDelete: (Element) throws -> Bool) rethrows {
        try store.removeAll { weakBox in
            guard let element = weakBox.value else { return false }
            return try shouldDelete(element)
        }
    }

    public mutating func compact() {
        store.removeAll { weakBox in
            weakBox.value == nil
        }
    }
}

extension WeakArray: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Element
    public init(arrayLiteral elements: Element...) {
        self.init()
        for element in elements {
            self.append(element)
        }
    }
}


public struct WeakSet<Element> {
    private var store = Set<Weak<Element>>()
    
    public var elements: [Element] {
        store.compactMap { $0.value }
    }
    
    public var weakReferenceCount: Int {
        store.count
    }
    
    public mutating func insert(_ element: Element) {
        store.insert(Weak(value: element))
    }
    
    public mutating func remove(_ element: Element)  {
        store.remove(Weak(value: element))
    }

    public mutating func compact() {
        store = store.filter { weakBox in
            weakBox.value != nil
        }
    }
}

extension WeakSet: ExpressibleByArrayLiteral {
    public typealias ArrayLiteralElement = Element
    public init(arrayLiteral elements: Element...) {
        self.init()
        for element in elements {
            self.insert(element)
        }
    }
}
