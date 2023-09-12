//
//  PasswordStrengthMeter.swift
//  EDKit
//
//  Created by xueqooy on 2023/9/12.
//

import Foundation

public enum PasswordStrengthMeter {
    
    private struct Constants {
        static let caseChangeValue = 3
        static let firstCharacterDigitValue = 2
        static let firstCharacterSymbolValue = 4
        static let otherCharacterSymbolValue = 2
        static let maxInsertSequenceValue = 4
        
        static let scoreToStrong = 60
        static let scoreToModerate = 40
        
        static let letterClass = ["e", "aot", "hinrs", "dl", "cfgmpuwy", "bkv", "jqxz"]
        static let firstLetterClass = ["ps","acu","bdefhimort","glnvw","jkqxyz"]
        static let digitClass = ["12","3450","67","89"]
        static let symbols = ["!@$", "&#%* ", "^()-_=+"]
    }
    
    public enum Level: Int {
        case weak, moderate, strong
    }
    
    public static func checkPasswordStrength(_ password: String) -> Level {
        let score = calculateScore(password)
        
        if score >= Constants.scoreToStrong {
            return .strong
        } else if score >= Constants.scoreToModerate {
            return .moderate
        } else {
            return .weak
        }
    }

    private static func calculateScore(_ password: String) -> Int {
        var score = 0
        var classChange = 0
        var lowCase = false
        var upCase = false
        var insert = false
        var check = password
        
        if check.count <= 1 {
            return 0
        }
        
        let test = removeInsert(check)
        if test != check {
            insert = true
            check = test
        }
        
        // Handle the first character
        let checkArray = Array(check)
        var cur = checkArray[0]
        if cur.isLetter {
            score += getClass(classes: Constants.firstLetterClass, letter: Character(cur.lowercased()))
        } else if cur.isNumber {
            // This is an unlikely case
            score += getClass(classes: Constants.digitClass, letter: cur) + Constants.firstCharacterDigitValue
        } else {
            var temp = getClass(classes: Constants.symbols, letter: cur)
            if temp < 0 {
                temp = Constants.symbols.count
            }
            // This is a very unlikely case
            score += temp + Constants.firstCharacterSymbolValue
        }
        
        var last = cur
        for i in 1..<check.count {
            cur = checkArray[i]
            // Check for case changes after the first character.  Also ignore ones after a space
            if cur.isLetter && last != " " {
                if cur.isUppercase {
                    upCase = true
                } else if cur.isLowercase {
                    lowCase = true
                }
            }
            
            // Change of class?
            if (cur.isLetter && !last.isLetter)
                || (cur.isNumber && !last.isNumber)
                || (!(cur.isLetter || cur.isNumber) && (last.isLetter || last.isNumber)) {
                // Woot
                classChange += 1
            }
            
            if cur == last { // Does it repeat the previous value?
                score += 0  // This is left as a placeholder
            } else {
                // Okay, lets award some entropy for it
                if cur.isLetter {
                    score += getClass(classes: Constants.letterClass, letter: Character(cur.lowercased()))
                } else if cur.isNumber {
                    score += getClass(classes: Constants.digitClass, letter: cur)
                } else {
                    var temp = getClass(classes: Constants.symbols, letter: cur)
                    if temp < 0 {
                        temp = Constants.symbols.count
                    }
                    score += temp + Constants.otherCharacterSymbolValue
                }
            }
            
            last = cur
        }
        
        if upCase && lowCase {
            // An interesting case change took place
            score += Constants.caseChangeValue
        }
        
        if insert {
            score += min(Constants.maxInsertSequenceValue, check.count)
        }
        
        if classChange > 1 {
            score += classChange
        }
        
        // Normalize it
        score = min(100, score * 2)
        score = max(score, 0)
        
        return score
    }

    /**
     * This function reduces the score for patterns like:  p1a1s1s1w1o1r1d1
     */
    private static func removeInsert(_ password: String) -> String {
        if password.count < 6 {
            return password
        }
        
        let passwordArray = Array(password)
        var insert = passwordArray[0]
        var result = ""
        var found = true
        
        // Even test like: 1a1b1c1d1e1f return abcdef
        for i in stride(from: 2, to: password.count, by: 2) {
            result += String(passwordArray[i - 1])
            if passwordArray[i] != insert {
                found = false
                break
            }
        }
        if found {
            return result
        }
        
        // Odd test like: a1b1c1d1e1f1 return abcdef
        found = true
        insert = passwordArray[1]
        result = String(passwordArray[0])
        for i in stride(from: 3, to: password.count, by: 2) {
            result += String(passwordArray[i - 1])
            if passwordArray[i] != insert {
                found = false
                break
            }
        }
        if found {
            return result
        }
        
        return password
    }

    private static func getClass(classes: [String], letter: Character) -> Int {
        for i in 0..<classes.count {
            if classes[i].contains(letter) {
                return i
            }
        }
        return -1
    }
}
