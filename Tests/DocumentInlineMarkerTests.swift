//
//  DocumentInlineMarkerTests.swift
//  CanvasNative
//
//  Created by Sam Soffes on 6/20/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import XCTest
import CanvasNative

// -[ ] New line before a comment
// -[ ] New line at end of comment
// -[ ] New line in the middle of a comment

final class DocumentInlineMarkerTests: XCTestCase {
	func testParsingInlineMarkers() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nUn-markered text ☊co|3YA3fBfQystAGJj63asokU☋markered text☊Ωco|3YA3fBfQystAGJj63asokU☋un-markered text")
		XCTAssertEqual("Title\nUn-markered text markered textun-markered text", document.presentationString)

		let paragraph = document.blocks[1] as! Paragraph
		let pairs = [
			InlineMarkerPair(
				openingMarker: InlineMarker(range: NSRange(location: 46, length: 27), position: .opening, id: "3YA3fBfQystAGJj63asokU"),
				closingMarker: InlineMarker(range: NSRange(location: 86, length: 28), position: .closing, id: "3YA3fBfQystAGJj63asokU")
			)
		]
		XCTAssert(pairs.map { $0.dictionary } == paragraph.inlineMarkerPairs.map { $0.dictionary })
	}

	func testPresentationRangeWithInlineMarkers() {
		var document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nUn-markered text ☊co|3YA3fBfQystAGJj63asokU☋markered text☊Ωco|3YA3fBfQystAGJj63asokU☋un-markered text\n⧙blockquote⧘> Hello")
		XCTAssertEqual(NSRange(location: 39, length: 8), document.presentationRange(backingRange: NSRange(location: 117, length: 8)))
		XCTAssertEqual(NSRange(location: 6, length: 46), document.presentationRange(backingRange: NSRange(location: 29, length: 101)))
		XCTAssertEqual(NSRange(location: 6, length: 46), document.presentationRange(blockIndex: 1))
		XCTAssertEqual(NSRange(location: 6, length: 46), document.presentationRange(block: document.blocks[1]))
		XCTAssertEqual(NSRange(location: 55, length: 2), document.presentationRange(backingRange: NSRange(location: 147, length: 2)))

		document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Simple comments\nOne ☊co|6BsgU6S6zujYGINemEJwvi☋two☊Ωco|6BsgU6S6zujYGINemEJwvi☋\n⧙code-⧘Th☊co|0QgIo1DL4xqyTJlv2vuZb0☋r☊Ωco|0QgIo1DL4xqyTJlv2vuZb0☋ee")
		XCTAssertEqual(NSRange(location: 24, length: 5), document.presentationRange(blockIndex: 2))

	}

	func testBackingRangeWithInlineMarkers() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nUn-markered text ☊co|3YA3fBfQystAGJj63asokU☋markered text☊Ωco|3YA3fBfQystAGJj63asokU☋un-markered text\n⧙blockquote⧘> Hello")
		XCTAssertEqual([NSRange(location: 117, length: 8)], document.backingRanges(presentationRange: NSRange(location: 39, length: 8)))
		XCTAssertEqual([NSRange(location: 29, length: 101)], document.backingRanges(presentationRange: NSRange(location: 6, length: 46)))
		XCTAssertEqual([NSRange(location: 147, length: 2)], document.backingRanges(presentationRange: NSRange(location: 55, length: 2)))
	}

	func testDeletingInlineMarkers() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Title\nOne ☊co|3YA3fBfQystAGJj63asokU☋two☊Ωco|3YA3fBfQystAGJj63asokU☋ three")

		// Insert at beginning, inserts outside marker.  The return value selects the attachment when in the front of it and it is up to the caller to decide if they are inserting in front or replacing the entire block
		XCTAssertEqual(NSRange(location: 33, length: 27), document.backingRange(presentationLocation: 10))
		XCTAssertEqual([NSRange(location: 33, length: 27)], document.backingRanges(presentationRange: NSRange(location: 10, length: 0)))

		// Insert at end, inserts inside marker. The return value selects the attachment when in the end of it and it is up to the caller to decide if they are inserting in front or replacing the entire block
		XCTAssertEqual(NSRange(location: 63, length: 28), document.backingRange(presentationLocation: 13))
		XCTAssertEqual([NSRange(location: 63, length: 28)], document.backingRanges(presentationRange: NSRange(location: 13, length: 0)))

		// Delete last character, deletes inside marker
		XCTAssertEqual([NSRange(location: 62, length: 1)], document.backingRanges(presentationRange: NSRange(location: 12, length: 1)))

		// Delete first character, deletes inside marker
		XCTAssertEqual([NSRange(location: 60, length: 1)], document.backingRanges(presentationRange: NSRange(location: 10, length: 1)))

		// Delete before first character, deletes outside marker
		XCTAssertEqual([NSRange(location: 32, length: 1)], document.backingRanges(presentationRange: NSRange(location: 9, length: 1)))

		// Deleting the content of an inline marker deletes the whole marker
		XCTAssertEqual([NSRange(location: 33, length: 58)], document.backingRanges(presentationRange: NSRange(location: 10, length: 3)))

		// Deleting partially inside and partially outside leaves marker intact
		let ranges = [
			NSRange(location: 31, length: 2),
			NSRange(location: 60, length: 2)
		]
		XCTAssertEqual(ranges, document.backingRanges(presentationRange: NSRange(location: 8, length: 4)))
	}

	func testOverlappingInlineMarkers() {
		let document = Document.createDocument(backingString: "⧙doc-heading-fake-uuid⧘Test\nHere is a ☊co|0znjeejIniX7iIEkKGMpPS☋com☊co|2SjhCeld7wLFEAyXsYK8eG☋ment☊Ωco|0znjeejIniX7iIEkKGMpPS☋. What☊Ωco|2SjhCeld7wLFEAyXsYK8eG☋ about after?")

		XCTAssertEqual("Test\nHere is a comment. What about after?", document.presentationString)

		let paragraph = document.blocks[1] as! Paragraph
		XCTAssertEqual(2, paragraph.inlineMarkerPairs.count)
		XCTAssertEqual("0znjeejIniX7iIEkKGMpPS", paragraph.inlineMarkerPairs[0].openingMarker.id)
		XCTAssertEqual("2SjhCeld7wLFEAyXsYK8eG", paragraph.inlineMarkerPairs[1].openingMarker.id)
	}
}
