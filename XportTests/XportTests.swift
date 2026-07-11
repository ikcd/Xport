//
//  XportTests.swift
//  XportTests
//
//  Created by kcd on 04/07/26.
//

import XCTest
@testable import Xport

// MARK: - DateFormatterHelper Tests

final class DateFormatterHelperTests: XCTestCase {

    func testHumanReadableWithValidDate() {
        let date = Date(timeIntervalSince1970: 0) // 1970-01-01 00:00:00 UTC
        let result = DateFormatterHelper.humanReadable(date)
        XCTAssertFalse(result.isEmpty)
        XCTAssertNotEqual(result, "N/A")
    }

    func testHumanReadableWithNilDate() {
        let result = DateFormatterHelper.humanReadable(nil)
        XCTAssertEqual(result, "N/A")
    }

    func testDateFromUnixTimestamp() {
        let timestamp: Double = 1783756146
        let date: Date = DateFormatterHelper.date(
            fromUnixTimestamp: timestamp
        ) ?? Date.now
        XCTAssertNotNil(date)
        XCTAssertEqual(date.timeIntervalSince1970, timestamp, accuracy: 0.001)
    }

    func testDateFromNilTimestamp() {
        let date = DateFormatterHelper.date(fromUnixTimestamp: nil)
        XCTAssertNil(date)
    }

    func testDateFromZeroTimestamp() {
        let timestamp: Double = 0
        let date = DateFormatterHelper.date(fromUnixTimestamp: 0) ?? Date.now
        XCTAssertNotNil(date)
        XCTAssertEqual(date.timeIntervalSince1970, timestamp, accuracy: 0.001)
    }
}
