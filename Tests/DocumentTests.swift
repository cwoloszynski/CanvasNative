//
//  DocumentTests.swift
//  CanvasNative
//
//  Created by Sam Soffes on 3/8/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import XCTest
import CanvasNative

// From: https://www.raizlabs.com/dev/2017/02/xctest-optional-unwrapping/
struct UnexpectedNilError: Error {}
func AssertNotNilAndUnwrap<T>(_ variable: T?, message: String = "Unexpected nil variable", file: StaticString = #file, line: UInt = #line) throws -> T {
	guard let variable = variable else {
		XCTFail(message, file: file, line: line)
		throw UnexpectedNilError()
	}
	return variable
}


final class DocumentTests: XCTestCase {
	func testTitle() {
		var document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nHello")
		XCTAssertEqual("Title", document.title)

		document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘**Title**\nHello")
		XCTAssertEqual("Title", document.title)

		document = Document.createDocument(backingString: "Hello")
		XCTAssertNil(document.title)
	}

	func testBlockAt() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nHello")
		let titleBlock = document.blockAt(presentationLocation: 5)
		let bodyBlock = document.blockAt(presentationLocation: 10)
		XCTAssert(titleBlock is DocumentTitle)
		XCTAssert(bodyBlock is Paragraph)
	}

	func testBackingRangeToPresentationRange() {
		var document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nOne\n⧙blockquote⧘> Two\n⧙code⧘Three")

		XCTAssertEqual("Title\nOne\nTwo\nThree", document.presentationString)
		XCTAssertEqual(NSRange(location: 0, length: 5), document.presentationRange(backingRange: document.blocks[0].visibleRange))
		XCTAssertEqual(NSRange(location: 6, length: 3), document.presentationRange(backingRange: document.blocks[1].visibleRange))
		XCTAssertEqual(NSRange(location: 10, length: 3), document.presentationRange(backingRange: document.blocks[2].visibleRange))
		XCTAssertEqual(NSRange(location: 14, length: 5), document.presentationRange(backingRange: document.blocks[3].visibleRange))

		document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nO")
		XCTAssertEqual("Title\nO", document.presentationString)
		XCTAssertEqual(NSRange(location: 0, length: 5), document.presentationRange(backingRange: document.blocks[0].visibleRange))
		XCTAssertEqual(NSRange(location: 6, length: 1), document.presentationRange(backingRange: document.blocks[1].visibleRange))

		document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\n⧙blockquote⧘> One")
		XCTAssertEqual("Title\nOne", document.presentationString)
		XCTAssertEqual(NSRange(location: 6, length: 3), document.presentationRange(backingRange: document.blocks[1].visibleRange))

		document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nC")
		XCTAssertEqual("Title\nC", document.presentationString)
		XCTAssertEqual(NSRange(location: 6, length: 1), document.presentationRange(backingRange: document.blocks[1].visibleRange))
	}

	func testPresentationRangeForBlock() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\n⧙blockquote⧘> One")
		XCTAssertEqual(NSRange(location: 6, length: 3), document.presentationRange(block: document.blocks[1]))
		XCTAssertEqual(NSRange(location: 6, length: 3), document.presentationRange(blockIndex: 1))
	}

//	func testHiddenBackingRangeToPresentationRange() {
//		let document = Document(backingString: "⧙doc-heading-fake-uuid⧘Title\n⧙blockquote⧘> Hi")
//
//		let backingRange = NSRange(location: 25, length: 5)
//		let displayRange = NSRange(location: 6, length: 0)
//		XCTAssertEqual(displayRange, document.presentationRange(backingRange: backingRange))
//	}

	func testPresentationRangeToBackingRange() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nOne\n⧙blockquote⧘> Two\n⧙code⧘Three")
		XCTAssertEqual("Title\nOne\nTwo\nThree", document.presentationString)

		XCTAssertEqual([NSRange(location: 48, length: 2)], document.backingRanges(presentationRange: NSRange(location: 11, length: 2)))
		XCTAssertEqual([NSRange(location: 31, length: 21)], document.backingRanges(presentationRange: NSRange(location: 8, length: 7)))
	}

	func testEntirePresentationRange() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\n⧙image⧘http://example.com/image.jpg")
		let ranges = document.backingRanges(presentationRange: NSRange(location: 6, length: 1))
		XCTAssertEqual([NSRange(location: 29, length: 35)], ranges)
	}

	func testBlockAtPresentationLocation() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nOne\n⧙blockquote⧘> Two")
		XCTAssertEqual("Title\nOne\nTwo", document.presentationString)

		XCTAssert(document.blockAt(presentationLocation: 0)! is DocumentTitle)
		XCTAssert(document.blockAt(presentationLocation: 1)! is DocumentTitle)
		XCTAssert(document.blockAt(presentationLocation: 6)! is Paragraph)
		XCTAssert(document.blockAt(presentationLocation: 7)! is Paragraph)
		XCTAssert(document.blockAt(presentationLocation: 10)! is Blockquote)
		XCTAssert(document.blockAt(presentationLocation: 11)! is Blockquote)
		XCTAssertNil(document.blockAt(presentationLocation: 14))
		XCTAssertNil(document.blockAt(presentationLocation: -1))
	}

	func testPresentationStringWithBackingRange() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Demo\nParagraph.\n⧙ordered-list-0⧘1. One")
		XCTAssertEqual("graph.\nOn", document.presentationString(backingRange: NSRange(location: 32, length: 28)))
	}

	func testPresentationStringWithBlock() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Demo\nParagraph.\n⧙ordered-list-0⧘1. One")
		XCTAssertEqual("One", document.presentationString(block: document.blocks.last!))
	}

	func testThingsAfterImages() throws {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Images break things\n⧙image-{\"ci\":\"c2a2e22f-82fc-4658-9fec-d965b3827b04\",\"width\":984,\"height\":794,\"url\":\"https://canvas-files-prod.s3.amazonaws.com/uploads/c2a2e22f-82fc-4658-9fec-d965b3827b04/Screen Shot 2016-06-20 at 10.11.52 AM.png\"}⧘\n## Metrics")

		let title = try AssertNotNilAndUnwrap(document.blocks[0] as? DocumentTitle)
		XCTAssertEqual(NSRange(location: 23, length: 19), title.visibleRange)

		let image = document.blocks[1] as! Image
		XCTAssertEqual(NSRange(location: 43, length: 216), image.range)
		XCTAssertEqual(NSRange(location: 43, length: 215), image.nativePrefixRange)
		XCTAssertEqual(NSRange(location: 258, length: 1), image.visibleRange)

		let heading = document.blocks[2] as! Heading
		XCTAssertEqual(NSRange(location: 260, length: 10), heading.range)
		XCTAssertEqual(NSRange(location: 263, length: 7), heading.textRange)
		XCTAssertEqual(NSRange(location: 260, length: 3), heading.leadingDelimiterRange)
		XCTAssertEqual([heading.leadingDelimiterRange], heading.foldableRanges)

		// The image glyph doesn't render in Xcode
		XCTAssertEqual("Images break things\n￼\n## Metrics", document.presentationString)

		XCTAssertEqual(NSRange(location: 0, length: 19), document.presentationRange(block: title))
		XCTAssertEqual(NSRange(location: 20, length: 1), document.presentationRange(block: image))
		XCTAssertEqual(NSRange(location: 22, length: 10), document.presentationRange(block: heading))
		XCTAssertEqual(NSRange(location: 22, length: 3), document.presentationRange(backingRange: heading.leadingDelimiterRange))
	}
}
