//
//  TextComponentParser.swift
//  pangaea
//
//  Created by xueqooy on 2024/7/17.
//  Copyright © 2024 Edmodo. All rights reserved.
//

import Foundation

public struct TextComponent {
    public let pattern: String?
    public let value: String
}

public enum TextComponentParser {
    
    public static func parse(_ text: String, with patterns: [String]) -> [TextComponent] {
        var components: [TextComponent] = []
        var combinedPattern = ""
        
        // Combine the patterns into a single regex
        for pattern in patterns {
            if !combinedPattern.isEmpty {
                combinedPattern += "|"
            }
            combinedPattern += "(\(pattern))"
        }
        
        // If no patterns are provided, return the whole text as a single plain component
        if combinedPattern.isEmpty {
            return [TextComponent(pattern: nil, value: text)]
        }
        
        // Create the regex object
        guard let regex = try? NSRegularExpression(pattern: combinedPattern, options: []) else {
            return [TextComponent(pattern: nil, value: text)]
        }
        
        // Find matches
        let matches = regex.matches(in: text, options: [], range: NSRange(text.startIndex..., in: text))
        
        // Initialize a variable to keep track of the last processed index
        var lastIndex = text.startIndex
        
        for match in matches {
            // Get the range of the current match
            let matchRange = Range(match.range, in: text)!
            
            // Add any plain text before the current match
            if matchRange.lowerBound > lastIndex {
                let plainText = String(text[lastIndex..<matchRange.lowerBound])
                components.append(TextComponent(pattern: nil, value: plainText))
            }
            
            // Determine which pattern was matched
            for (index, pattern) in patterns.enumerated() {
                if match.range(at: index + 1).location != NSNotFound {
                    let matchText = String(text[matchRange])
                    components.append(TextComponent(pattern: pattern, value: matchText))
                    break
                }
            }
            
            // Update the last processed index
            lastIndex = matchRange.upperBound
        }
        
        // Add any remaining plain text after the last match
        if lastIndex < text.endIndex {
            let plainText = String(text[lastIndex..<text.endIndex])
            components.append(TextComponent(pattern: nil, value: plainText))
        }
        
        return components
    }
}
