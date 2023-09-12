//
//  ValueValidation.swift
//  EDKit
//
//  Created by xueqooy on 2023/9/12.
//

import Foundation
import Combine

public protocol ValueValidationProviding {
    associatedtype FormatError
    associatedtype Value: Equatable
    associatedtype CustomState
    
    var valueSubject: CurrentValueSubject<Value, Never> { get }
        
    func checkFormat(_ value: Value) -> FormatError?
    
    func invalidFormatPrompt(for error: FormatError) -> String?
    
    func validateValue(_ value: Value) -> AnyPublisher<CustomState, Error>
}

/// Validation for any value, there are several steps:
///
/// 1. Check format (Optional, If not needed, just return nil)
/// 2. Debounce (Optional, default is`immediate`)
/// 3. Validate Value
///
///  Provide basic validation state (`none`、`formatError` and `unknownError`), and also provide customized validation state through the provider
///
public final class ValueValidation<Provider: ValueValidationProviding>: InputOutputProviding {
    
    public typealias Value = Provider.Value
    public typealias CustomState = Provider.CustomState
    
    public enum State {
        case none
        case formatError(prompt: String)
        case unknownError(error: Error)
        case custom(state: CustomState)
    }
    
    public enum Timing {
        case immediate
        case debounce(seconds: TimeInterval)
    }
    
    public struct Input {
        public let value: CurrentValueSubject<Value, Never>
    }
    
    public struct Output {
        public let validationState: AnyPublisher<State, Never>
    }
    
    public let input: Input
    public let output: Output
    
    public var state: State {
        validationStateSubject.value
    }
    
    private let validationStateSubject = CurrentValueSubject<State, Never>(.none)
    
    private var bindingCancellable: AnyCancellable?
    private var validationCancellable: AnyCancellable?
    
    public let provider: Provider
    
    public init(provider: Provider, ignoreInitialValue: Bool = false, timing: Timing = .immediate) {
        self.provider = provider
        
        input = Input(value: provider.valueSubject)
        output = Output(validationState: validationStateSubject.eraseToAnyPublisher())
              
        var publisher = input.value
            .removeDuplicates()
            .dropFirst(ignoreInitialValue ? 1 : 0)
            .handleEvents(receiveOutput: { [weak self] _ in
                guard let self = self else { return }
                
                self.cancelCurrentValidation()
            })
            .filter { [weak self] in
                guard let self = self else { return false }
                
                return self.checkFormat(for: $0)
            }
            .eraseToAnyPublisher()
        
        if case let .debounce(seconds) = timing {
            publisher = publisher
                .debounce(for: RunLoop.SchedulerTimeType.Stride(seconds), scheduler: RunLoop.main)
                .eraseToAnyPublisher()
        }
        
        bindingCancellable =
        publisher.filter { [weak self] in
                guard let self = self else { return false }
                
                // Isn't current value, ignore
                return self.isCurrent(for: $0)
            }
            .sink { [weak self] in
                guard let self = self else { return }
                                
                self.validateValue($0)
            }
    }
    
    public func isCurrent(for value: Value) -> Bool {
        input.value.value == value
    }

    public func update() {
        let value = input.value.value
        
        cancelCurrentValidation()
        
        guard checkFormat(for: value) else {
            return
        }
        
        validateValue(value)
    }
    
    // Manually set state
    public func sendState(_ state: State) {
        cancelCurrentValidation()
        
        validationStateSubject.send(state)
    }
    
    private func cancelCurrentValidation() {
        validationCancellable = nil
        validationStateSubject.send(.none)
    }
        
    private func checkFormat(for value: Value) -> Bool {
        if let formatError = provider.checkFormat(value) {
            // Format is error
            if let prompt = provider.invalidFormatPrompt(for: formatError) {
                validationStateSubject.send(.formatError(prompt: prompt))
            } else {
                validationStateSubject.send(.none)
            }
            return false
        }
        return true
    }
    
    private func validateValue(_ value: Value) {
        validationCancellable =
        provider.validateValue(value)
            .sink { [weak self] completion in
                if case let .failure(error) = completion {
                    self?.validationStateSubject.send(.unknownError(error: error))
                }
            } receiveValue: { [weak self] customState in
                self?.validationStateSubject.send(.custom(state: customState))
            }
    }
}


public extension ValueValidation {
    var unknownErrorPublisher: AnyPublisher<Error, Never> {
        output.validationState
            .filter { state in
                if case .unknownError(_) = state {
                    return true
                }
                return false
            }
            .map { state -> Error in
                if case let .unknownError(error) = state {
                    return error
                }
                // Never come here, just avoid compiler errors
                return NSError()
            }
            .eraseToAnyPublisher()
    }
}
