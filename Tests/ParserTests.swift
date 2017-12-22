//
//  ParserTests.swift
//  CanvasNative
//
//  Created by Sam Soffes on 4/26/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import XCTest
import CanvasNative

// Most of the parser is tested in the node tests.
final class ParserTests: XCTestCase {
	func testTrailingNewLine() {
		let blocks = Parser.parse("⧙doc-heading-fake-uuid⧘Hello\n")

		XCTAssert(blocks[0] is DocumentTitle)
		XCTAssertEqual(NSRange(location: 0, length: 28), blocks[0].range)

		XCTAssertEqual(2, blocks.count)
		XCTAssert(blocks[1] is Paragraph)
		XCTAssertEqual(NSRange(location: 29, length: 0), blocks[1].range)
	}
}
