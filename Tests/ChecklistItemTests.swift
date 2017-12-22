//
//  ChecklistItemTests.swift
//  CanvasNative
//
//  Created by Sam Soffes on 4/26/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import XCTest
import CanvasNative

final class ChecklistItemTests: XCTestCase {
	func testUncompleted() {
		let node = ChecklistItem(
			string: "⧙checklist-0⧘-[ ] Hello",
			range: NSRange(location: 0, length: 23)
		)!

		XCTAssertEqual(NSRange(location: 0, length: 23), node.range)
		XCTAssertEqual(NSRange(location: 0, length: 18), node.nativePrefixRange)
		XCTAssertEqual(NSRange(location: 18, length: 5), node.visibleRange)
		XCTAssertEqual(NSRange(location: 11, length: 1), node.indentationRange)
		XCTAssertEqual(Indentation.zero, node.indentation)
		XCTAssertEqual(NSRange(location: 15, length: 1), node.stateRange)
		XCTAssertEqual(ChecklistItem.State.unchecked, node.state)
	}

	func testCompleted() {
		let node = ChecklistItem(
			string: "⧙checklist-1⧘-[x] Done",
			range: NSRange(location: 10, length: 22)
		)!

		XCTAssertEqual(NSRange(location: 10, length: 18), node.nativePrefixRange)
		XCTAssertEqual(NSRange(location: 28, length: 4), node.visibleRange)
		XCTAssertEqual(Indentation.one, node.indentation)
		XCTAssertEqual(ChecklistItem.State.checked, node.state)
	}
}
