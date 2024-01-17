//
//  Error+isCancelled.swift
//  EDKit
//
//  Created by xueqooy on 2023/9/12.
//

import Foundation

public extension Error {
    var isCancelled: Bool {
        do {
            throw self
        } catch URLError.cancelled {
            return true
        } catch CocoaError.userCancelled {
            return true
        } catch is CancellationError {
            return true
        } catch {
            return false
        }
    }
}

/**
 Example:
 
 ```
 enum ONBError: Error, UnderlyingErrorProviding {
     case notLoggedIn
     case unrecognizedStep
     case notDisplayOnboarding
     case unknown(underlying: Error)
     
     var underlyingError: Error? {
         if case .unknown(let underlying) = self {
             return underlying
         }
         return nil
     }
 }
 ```
 */
public protocol UnderlyingErrorProviding {
    var underlyingError: Error? { get }
}

extension NSError: UnderlyingErrorProviding {
    public var underlyingError: Error? {
        userInfo[NSUnderlyingErrorKey] as? Error
    }
}
