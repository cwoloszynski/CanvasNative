//
//  XCTestCase+CanvasNativeTests.swift
//  CanvasNative
//
//  Created by Sam Soffes on 3/10/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import XCTest
import CanvasNative

extension XCTest {
	func parse(_ string: String) -> [[String: Any]] {
		return Parser.parse(string).map { $0.dictionary }
	}

	func blockTypes(_ string: String) -> [String] {
		return Parser.parse(string).map { String(describing: type(of: $0)) }
	}
}

public func ==(lhs: [[String: Any]], rhs: [[String: Any]] ) -> Bool {
	if lhs.count != rhs.count { return false }
	
	for index in 0..<lhs.count {
		let left = lhs[index]
		let right = rhs[index]
		if !NSDictionary(dictionary: left).isEqual(to: right) { return false
		}
	}
	return true 
}
