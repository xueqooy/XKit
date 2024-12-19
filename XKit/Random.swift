//
//  Random.swift
//  llp_x_cloud_assemble_ios
//
//  Created by xueqooy on 2024/10/19.
//

import Foundation

private let randomLetters = "        abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
private let randomNetworkImageHost = "https://picsum.photos"

public extension String {
    static func random(_ length: Int) -> String {
        String((0 ..< length).map { _ in randomLetters.randomElement()! })
    }

    static func random(_ lengthRange: ClosedRange<Int>) -> String {
        random(Int.random(in: lengthRange))
    }

    static func random(_ lengthRange: Range<Int>) -> String {
        random(Int.random(in: lengthRange))
    }

    static func randomNetworkImage(width: Int = .random(in: 100 ... 200), height: Int = .random(in: 100 ... 200)) -> String {
        "\(randomNetworkImageHost)/\(width)/\(height)"
    }
}

public extension URL {
    static func randomNetworkImage(width: Int = .random(in: 100 ... 200), height: Int = .random(in: 100 ... 200)) -> URL {
        URL(string: "\(randomNetworkImageHost)/\(width)/\(height)")!
    }
}

public extension Date {
    static func random(from startDate: Date? = nil, to endDate: Date? = nil) -> Date {
        let start = startDate ?? Calendar.current.date(byAdding: .year, value: -1, to: Date())!
        let end = endDate ?? Date()

        guard start < end else {
            fatalError("startDate must be earlier than endDate")
        }

        let timeInterval = end.timeIntervalSince(start)
        let randomInterval = TimeInterval.random(in: 0 ... timeInterval)

        return start.addingTimeInterval(randomInterval)
    }
}
