//
//  MarkdownRendererTests.swift
//  CanvasNative
//
//  Created by Sam Soffes on 7/25/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import XCTest
import CanvasNative

final class MarkdownRendererTests: XCTestCase {
	func testRenderer() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Output\nHello\nThere\n⧙unordered-list-0⧘- This\n⧙unordered-list-0⧘- is\n⧙unordered-list-0⧘- a\n⧙unordered-list-0⧘- list\nMore after that.")
		let renderer = MarkdownRenderer(document: document)
		XCTAssertEqual("Output\nHello\nThere\n- This\n- is\n- a\n- list\nMore after that.", renderer.render())
	}

	func testOrderedLists() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Ordered\n⧙ordered-list-0⧘1. One\n⧙ordered-list-1⧘1. Two\n⧙ordered-list-0⧘1. Three")
		let renderer = MarkdownRenderer(document: document)
		XCTAssertEqual("Ordered\n1. One\n    1. Two\n2. Three", renderer.render())
	}
}
