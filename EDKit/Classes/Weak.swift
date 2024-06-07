//
//  Weak.swift
//  EDKit
//
//  Created by 🌊 薛 on 2022/9/21.
//

import Foundation

public class Weak<T: AnyObject> {
    
    public private(set) weak var value: T?

    public init(value: T) {
        self.value = value
    }
    
    public init(_ value: T) {
        self.value = value
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
        store.allObjects
    }
    
    private var store = NSHashTable<Element>.weakObjects()
    
    public init(_ elements: [Element] = []) {
        for element in elements {
            self.insert(element)
        }
    }
    
    public init(arrayLiteral elements: Element...) {
        self.init(elements)
    }
    
    public mutating func insert(_ element: Element) {
        store.add(element)
    }
    
    public mutating func remove(_ element: Element)  {
        store.remove(element)
    }
    
    public func makeIterator() -> AnyIterator<Element> {
        let iterator = store.objectEnumerator()
        return AnyIterator {
            return iterator.nextObject() as? Element
        }
    }

    public var description: String {
        elements.description
    }
    
    public var debugDescription: String {
        elements.debugDescription
    }
}
