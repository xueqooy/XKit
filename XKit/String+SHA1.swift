//
//  String+SHA1.swift
//  XKit
//
//  Created by xueqooy on 2024/12/11.
//

import CommonCrypto
import Foundation

public extension String {
    func sha1Encoded() -> String {
        let data = self.data(using: String.Encoding.utf8)!
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        CC_SHA1([UInt8](data), CC_LONG(data.count), &digest)

        let output = NSMutableString(capacity: Int(CC_SHA1_DIGEST_LENGTH))
        for byte in digest {
            output.appendFormat("%02x", byte)
        }
        return output as String
    }
}
