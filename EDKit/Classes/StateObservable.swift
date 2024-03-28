//
//  Observable.swift
//  EDKit
//
//  Created by xueqooy on 2023/4/13.
//

import Foundation
import Combine

/**
 ```
/// Objects can follow the StateObservableObject protocol (which is optional)
/// As long as the attributes marked with @State or @Equtable change,
/// it will trigger stateWillChange and stateDidChange
 
class MyObject: StateObservableObject {
    
    /// As long as the value is assigned, a notification will be sent
 
    @State
    var age: Int = 0
    
 
    /// The value marked as @EqutableState must follow the Equtable protocol，
    /// Unlike @State, notifications are only sent when the current value is determined to be unequal to the old value
 
    @EquatableState
    var name: String = ""

}

func example() {
    var cancellables = Set<AnyCancellable>()
    
    let object = MyObject()

    object.$name.willChange
        .sink { newValue in
            print("value will change to \(newValue)")
        }
        .store(in: &cancellables)

    object.$name.didChange
        .sink { newValue in
            print("value did change to \(newValue)")
        }
        .store(in: &cancellables)

    object.stateDidChange
        .sink {
            print("name or age did change")
        }
        .store(in: &cancellables)
}
 ```
*/


final public class StateObservableObjectPublisher : Publisher {
    
    public typealias Output = Void
    
    public typealias Failure = Never
    
    private let storage: PassthroughSubject<Output, Never>
    
    fileprivate var isEnabled: Bool = true
    
    public init() {
        self.storage = .init()
    }
    
    final public func receive<S>(subscriber: S) where S : Subscriber, Never == S.Failure, Void == S.Input {
        storage.receive(subscriber: subscriber)
    }
    
    final public func send() {
        guard isEnabled else { return }
        
        storage.send()
    }
    
    
}


public protocol StateObservableObject: AnyObject {
    var stateWillChange: StateObservableObjectPublisher { get }
    var stateDidChange: StateObservableObjectPublisher{ get }
}

private let willChangePublisherAssociation = Association<StateObservableObjectPublisher>()
private let didChangePublisherAssociation = Association<StateObservableObjectPublisher>()
private let isPerformingBatchStateUpdatesAssociation = Association<Bool>()

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
    
    private var isPerformingBatchStateUpdates: Bool {
        set { isPerformingBatchStateUpdatesAssociation[self] = newValue }
        get { isPerformingBatchStateUpdatesAssociation[self] ?? false }
    }
    
    func performBatchStateUpdates(_ updates: (Self) -> Void) {
        Asserts.failure("Nested calls `performBatchStateUpdates` are not allowed", condition: !isPerformingBatchStateUpdates)
         
        stateWillChange.send()
        
        stateWillChange.isEnabled = false
        stateDidChange.isEnabled = false
        
        isPerformingBatchStateUpdates = true

        updates(self)
        
        isPerformingBatchStateUpdates = false
        
        stateWillChange.isEnabled = true
        stateDidChange.isEnabled = true
                
        stateDidChange.send()
    }
}


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
    
    public static subscript<T>(_enclosingInstance instance: T, wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>, storage storageKeyPath: ReferenceWritableKeyPath<T, StateObject>) -> Value {
        get {
            let storage = instance[keyPath: storageKeyPath].storage
            if let stateObservableObject = instance as? StateObservableObject {
                instance[keyPath: storageKeyPath].box.bind(storage, to: stateObservableObject)
            }
            return storage
        }
        set {
            instance[keyPath: storageKeyPath].storage = newValue
        }
    }
}

@propertyWrapper
public struct State<Value> {
    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError() }
        // swiftlint:disable unused_setter_value
        set { fatalError() }
    }
    

    private var storage: Value
    
    private let willChangeSubject: PassthroughSubject<Value, Never>
    private let didChangeSubject: CurrentValueSubject<Value, Never>

    public var projectedValue: (willChange: AnyPublisher<Value, Never>, didChange: AnyPublisher<Value, Never>) {
        (willChangeSubject.eraseToAnyPublisher(), didChangeSubject.eraseToAnyPublisher())
    }
    
    /// Create a property wrapper with initial value.
    /// - Parameter wrappedValue: The initial value.
    public init(wrappedValue: Value) {
        storage = wrappedValue
        
        willChangeSubject = .init()
        didChangeSubject = .init(wrappedValue)
    }

    public static subscript<T>(_enclosingInstance instance: T, wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>, storage storageKeyPath: ReferenceWritableKeyPath<T, State>) -> Value {
        get {
            instance[keyPath: storageKeyPath].storage
        }
        set {
            let stateObservableObject = instance as? StateObservableObject
            
            instance[keyPath: storageKeyPath].willChangeSubject.send(newValue)
            stateObservableObject?.stateWillChange.send()
            instance[keyPath: storageKeyPath].storage = newValue
            instance[keyPath: storageKeyPath].didChangeSubject.send(newValue)
            stateObservableObject?.stateDidChange.send()
        }
    }
}


@propertyWrapper
public struct EquatableState<Value: Equatable> {
    @available(*, unavailable)
    public var wrappedValue: Value {
        get { fatalError() }
        // swiftlint:disable unused_setter_value
        set { fatalError() }
    }
    

    private var storage: Value

    private let willChangeSubject: PassthroughSubject<Value, Never>
    /// Use `currentValueSubject` to get the current value when subscribing
    private let didChangeSubject: CurrentValueSubject<Value, Never>

    public var projectedValue: (willChange: AnyPublisher<Value, Never>, didChange: AnyPublisher<Value, Never>) {
        (willChangeSubject.eraseToAnyPublisher(), didChangeSubject.eraseToAnyPublisher())
    }
    
    /// Create a property wrapper with initial value.
    /// - Parameter wrappedValue: The initial value.
    public init(wrappedValue: Value) {
        storage = wrappedValue
        
        willChangeSubject = .init()
        didChangeSubject = .init(wrappedValue)
    }
    
    public static subscript<T>(_enclosingInstance instance: T, wrapped wrappedKeyPath: ReferenceWritableKeyPath<T, Value>, storage storageKeyPath: ReferenceWritableKeyPath<T, EquatableState>) -> Value where Value : Equatable {
        get {
            instance[keyPath: storageKeyPath].storage
        }
        set {
            if  instance[keyPath: storageKeyPath].storage == newValue {
                instance[keyPath: storageKeyPath].storage = newValue
                return
            }
            
            let stateObservableObject = instance as? StateObservableObject
            
            instance[keyPath: storageKeyPath].willChangeSubject.send(newValue)
            stateObservableObject?.stateWillChange.send()
            instance[keyPath: storageKeyPath].storage = newValue
            instance[keyPath: storageKeyPath].didChangeSubject.send(newValue)
            stateObservableObject?.stateDidChange.send()
        }
    }
}
