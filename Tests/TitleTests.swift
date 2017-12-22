//
//  TitleTests.swift
//  CanvasNative
//
//  Created by Sam Soffes on 4/13/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import XCTest
import CanvasNative

final class TitleTest: XCTestCase {
	func testTitle() throws {
		let nativeText = "⧙doc-heading-fake-uuid⧘Hello"
		let node = try AssertNotNilAndUnwrap(DocumentTitle(string: nativeText, range: NSRange(location: 0, length: nativeText.count)))
		XCTAssertEqual(NSRange(location: 0, length: 23), node.nativePrefixRange)
		XCTAssertEqual(NSRange(location: 23, length: 5), node.visibleRange)
	}

	func testInline() throws {
		let node = try AssertNotNilAndUnwrap(Parser.parse("⧙doc-heading-fake-uuid⧘Hello **world**").first! as? DocumentTitle)
		XCTAssertEqual(NSRange(location: 23, length: 15), node.textRange)
		XCTAssert(node.subnodes[0] is Text)
		XCTAssert(node.subnodes[1] is DoubleEmphasis)
	}
}
