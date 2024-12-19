//
//  Cancellable.swift
//  XKit
//
//  Created by xueqooy on 2024/10/22.
//

import Combine
import Foundation

extension Task: @retroactive Cancellable {}
