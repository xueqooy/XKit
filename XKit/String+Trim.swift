//
//  String+Trim.swift
//  XKit
//
//  Created by xueqooy on 2024/7/24.
//

import Foundation

public extension String {
    func trimmingWhitespacesAndAndNewlines() -> String {
        var whitespace = CharacterSet(charactersIn: "\u{200B}") // Zero-width space
        whitespace.formUnion(CharacterSet.whitespacesAndNewlines)
        return trimmingCharacters(in: whitespace)
    }
}
