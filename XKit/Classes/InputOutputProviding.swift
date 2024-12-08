//
//  InputOutputProviding.swift
//  XKit
//
//  Created by xueqooy on 2023/9/12.
//

import Foundation

public protocol InputProviding {
    associatedtype Input
    
    var input: Input { get }
}

public protocol OutputProviding {
    associatedtype Output

    var output: Output { get }
}

public typealias InputOutputProviding = InputProviding & OutputProviding
