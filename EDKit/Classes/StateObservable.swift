//
//  Observable.swift
//  EDKit
//
//  Created by xueqooy on 2023/4/13.
//

import Foundation
import Combine

@available(iOS 13.0, *)
final public class StateObservableObjectPublisher : Publisher {
    
    public typealias Output = Void
    
    public typealias Failure = Never
    
    private let storage: PassthroughSubject<Output, Never>
    
    public init() {
        self.storage = .init()
    }
    
    final public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
        storage.receive(subscriber: subscriber)
    }
    
    final public func send() {
        storage.send()
    }
}


@available(iOS 13.0, *)
public protocol StateObservableObject: AnyObject {
    var stateWillChange: StateObservableObjectPublisher { get }
    var stateDidChange: StateObservableObjectPublisher{ get }
}

@available(iOS 13.0, *)
private let willChangePublisherAssociation = Association<StateObservableObjectPublisher>()
@available(iOS 13.0, *)
private let didChangePublisherAssociation = Association<StateObservableObjectPublisher>()

@available(iOS 13.0, *)
public extension StateObservableObject {
    
    var stateWillChange: StateObservableObjectPublisher {
        var publisher = willChangePublisherAssociation[self]
        if publisher == nil {
            publisher = .init()
            willChangePublisherAssociation[self] = publisher
        }
        return publisher!
    }
    
    var stateDidChange: StateObservableObjectPublisher {
        var publisher = didChangePublisherAssociation[self]
        if publisher == nil {
            publisher = .init()
            didChangePublisherAssociation[self] = publisher
        }
        return publisher!
    }
}


@available(iOS 13.0, *)
@propertyWrapper
public struct StateObject<Value: StateObservableObject> {
    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError() }
        // swiftlint:disable unused_setter_value
        set { fatalError() }
    }
        
    private class Box {
        weak var context: StateObservableObject?
        lazy var cancellables = Set<AnyCancellable>()
        
        func bind(_ object: Value, to context: StateObservableObject) {
            guard self.context !== context else {
                return
            }
            
            self.context = context
            object.stateWillChange
                .sink {
                    guard let context = self.context else {
                        return
                    }
                    
                    context.stateWillChange.send()
                }
                .store(in: &cancellables)
            
            object.stateDidChange
                .sink {
                    guard let context = self.context else {
                        return
                    }
                    
                    context.stateDidChange.send()
                }
                .store(in: &cancellables)
        }
    }
    
    private var storage: Value
    private var box = Box()
    
    public init(wrappedValue: Value) {
        self.storage = wrappedValue
    }
    
    public static subscript<T: StateObservableObject>(_enclosingInstance instance: T, wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>, storage storageKeyPath: ReferenceWritableKeyPath<T, StateObject>) -> Value {
        get {
            let storage = instance[keyPath: storageKeyPath].storage
            instance[keyPath: storageKeyPath].box.bind(storage, to: instance)
            return storage
        }
        set {
            instance[keyPath: storageKeyPath].storage = newValue
        }
    }
}


@available(iOS 13.0, *)
@propertyWrapper
public struct State<Value> {
    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError() }
        // swiftlint:disable unused_setter_value
        set { fatalError() }
    }
    

    private var storage: Value
    
    private let willChangeSubject = PassthroughSubject<Value, Never>()
    private let didChangeSubject = PassthroughSubject<Value, Never>()

    public var projectedValue: (willChange: AnyPublisher<Value, Never>, didChange: AnyPublisher<Value, Never>) {
        (willChangeSubject.eraseToAnyPublisher(), didChangeSubject.eraseToAnyPublisher())
    }
    
    /// Create a property wrapper with initial value.
    /// - Parameter wrappedValue: The initial value.
    public init(wrappedValue: Value) {
        storage = wrappedValue
    }

    public static subscript<T: StateObservableObject>(_enclosingInstance instance: T, wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>, storage storageKeyPath: ReferenceWritableKeyPath<T, State>) -> Value {
        get {
            instance[keyPath: storageKeyPath].storage
        }
        set {
            instance[keyPath: storageKeyPath].willChangeSubject.send(newValue)
            instance.stateWillChange.send()
            instance[keyPath: storageKeyPath].storage = newValue
            instance[keyPath: storageKeyPath].didChangeSubject.send(newValue)
            instance.stateDidChange.send()
        }
    }
}


@available(iOS 13.0, *)
@propertyWrapper
public struct EquatableState<Value: Equatable> {
    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError() }
        // swiftlint:disable unused_setter_value
        set { fatalError() }
    }
    

    private var storage: Value

    private let willChangeSubject = PassthroughSubject<Value, Never>()
    private let didChangeSubject = PassthroughSubject<Value, Never>()

    public var projectedValue: (willChange: AnyPublisher<Value, Never>, didChange: AnyPublisher<Value, Never>) {
        (willChangeSubject.eraseToAnyPublisher(), didChangeSubject.eraseToAnyPublisher())
    }
    
    /// Create a property wrapper with initial value.
    /// - Parameter wrappedValue: The initial value.
    public init(wrappedValue: Value) {
        storage = wrappedValue
    }
    
    public static subscript<T: StateObservableObject>(_enclosingInstance instance: T, wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>, storage storageKeyPath: ReferenceWritableKeyPath<T, EquatableState>) -> Value where Value : Equatable {
        get {
            instance[keyPath: storageKeyPath].storage
        }
        set {
            if  instance[keyPath: storageKeyPath].storage == newValue {
                instance[keyPath: storageKeyPath].storage = newValue
                return
            }
            
            instance[keyPath: storageKeyPath].willChangeSubject.send(newValue)
            instance.stateWillChange.send()
            instance[keyPath: storageKeyPath].storage = newValue
            instance[keyPath: storageKeyPath].didChangeSubject.send(newValue)
            instance.stateDidChange.send()
        }
    }
}
