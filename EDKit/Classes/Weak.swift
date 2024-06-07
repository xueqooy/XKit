//
//  Weak.swift
//  EDKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Foundation

private let identifierAssociation = Association<UUID>(wrap: .retain)

public class Weak<T: AnyObject>: Hashable {
 
    private let identifier: UUID
    
    public private(set) weak var value: T?

    public init(value: T) {
        self.value = value
        
        if let identifier = identifierAssociation[value] {
            self.identifier = identifier
        } else {
            self.identifier = UUID()
            identifierAssociation[value] = self.identifier
        }
    }
    
    public init(_ value: T) {
        self.value = value
        
        if let identifier = identifierAssociation[value] {
            self.identifier = identifier
        } else {
            self.identifier = UUID()
            identifierAssociation[value] = self.identifier
        }
    }
    
    public static func == (lhs: Weak<T>, rhs: Weak<T>) -> Bool {
        lhs.identifier == rhs.identifier
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(identifier)
    }
}


/// Simlilar to Weak, but do not check for generics
public class UncheckedWeak<T> {
        
    private weak var _value: AnyObject?
    
    public var value: T? {
        _value as? T
    }

    public init(value: T) {
        self._value = value as AnyObject
    }
    
    public init(_ value: T) {
        self._value = value as AnyObject
    }
}


public struct WeakArray<Element: AnyObject>: Sequence, ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible  {
    
    public var elements: [Element] {
        store.compactMap { $0.value }
    }

    private var store: [Weak<Element>] = []
        
    public init(_ elements: [Element] = []) {
        for element in elements {
            self.append(element)
        }
    }
    
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
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
    
    public func makeIterator() -> IndexingIterator<[Element]>  {
        elements.makeIterator()
    }
    
    public var description: String {
        elements.description
    }
    
    public var debugDescription: String {
        elements.debugDescription
    }
}


public struct WeakSet<Element: AnyObject>: Sequence, ExpressibleByArrayLiteral, CustomStringConvertible, CustomDebugStringConvertible {
        
    public var elements: [Element] {
        store.flatMap { $0.value }
    }
    
    private var store = Set<Weak<Element>>()
    
    public init(_ elements: [Element] = []) {
        for element in elements {
            self.insert(element)
        }
    }
    
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
    
    public mutating func insert(_ element: Element) {
        store.insert(Weak(element))
    }
    
    public mutating func remove(_ element: Element)  {
        store.remove(Weak(element))
    }
    
    public mutating func compact() {
        store = store.filter { weakBox in
            weakBox.value != nil
        }
    }
    
    public func makeIterator() -> IndexingIterator<[Element]> {
        elements.makeIterator()
    }

    public var description: String {
        elements.description
    }
    
    public var debugDescription: String {
        elements.debugDescription
    }
}
