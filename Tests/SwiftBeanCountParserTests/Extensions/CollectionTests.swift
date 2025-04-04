//
//  CollectionTests.swift
//  SwiftBeanCountParserTests
//
//  Created by Steffen Kötte on 2017-06-10.
//  Copyright © 2017 Steffen Kötte. All rights reserved.
//

@testable import SwiftBeanCountParser
import XCTest

final class CollectionTests: XCTestCase {

    func testSafeArray() {
        var array = [String]()
        XCTAssertNil(array[safe: 0])
        array.append("value")
        XCTAssertEqual(array[safe: 0], "value")
        XCTAssertNil(array[safe: 1])
    }

}
