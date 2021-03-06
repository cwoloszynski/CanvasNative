//
//  DocumentControllerChangeTests.swift
//  CanvasNative
//
//  Created by Sam Soffes on 2/23/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import XCTest
import CanvasNative

final class DocumentControllerChangeTests: XCTestCase {

	// MARK: - Properties

	let delegate = TestDocumentControllerDelegate()


	// MARK: - Tests

	func testChange() {
		let controller = DocumentController(backingString: "⧙doc-heading-fake-uuid⧘Title\nOne\nTwo", delegate: delegate)

		let will = expectation(description: "willUpdate")
		delegate.willUpdate = { will.fulfill() }

		let insert = expectation(description: "didInsert")
		delegate.didInsert = { block, index in
			insert.fulfill()
		}

		let remove = expectation(description: "didRemove")
		delegate.didRemove = { block, index in
			remove.fulfill()
		}

		let did = expectation(description: "didUpdate")
		delegate.didUpdate = { did.fulfill() }

		controller.replaceCharactersInBackingRange(NSRange(location: 22, length: 0), withString: "!")
		waitForExpectations(timeout: 0.1, handler: nil)

		XCTAssertEqual(delegate.presentationString as String, controller.document.presentationString)
		XCTAssertEqual(blockTypes(controller.document.backingString), delegate.blockTypes)
	}

	func testMultipleInsertRemove() {
		let controller = DocumentController(backingString: "⧙doc-heading-fake-uuid⧘Title\nOne\nTwo\nThree\nFour", delegate: delegate)
		controller.replaceCharactersInBackingRange(NSRange(location: 19, length: 18), withString: "Hello\nWorld")

		XCTAssertEqual(delegate.presentationString as String, controller.document.presentationString)
		XCTAssertEqual(blockTypes(controller.document.backingString), delegate.blockTypes)
	}

	func testConvertToChecklist() {
		let controller = DocumentController(backingString: "⧙doc-heading-fake-uuid⧘Title\n⧙unordered-list-0⧘-[ ]Hi", delegate: delegate)
		controller.replaceCharactersInBackingRange(NSRange(location: 20, length: 0), withString: "checklist-0⧘-[ ] ")
		controller.replaceCharactersInBackingRange(NSRange(location: 38, length: 22), withString: "")

		XCTAssertEqual(delegate.presentationString as String, controller.document.presentationString)
		XCTAssertEqual(blockTypes(controller.document.backingString), delegate.blockTypes)
	}

	func testCheckChecklist() {
		let controller = DocumentController(backingString: "⧙doc-heading-fake-uuid⧘Title\n⧙checklist-0⧘-[ ] Hi", delegate: delegate)
		controller.replaceCharactersInBackingRange(NSRange(location: 35, length: 0), withString: "x")
		controller.replaceCharactersInBackingRange(NSRange(location: 36, length: 1), withString: "")

		XCTAssertEqual(delegate.presentationString as String, controller.document.presentationString)
		XCTAssertEqual(blockTypes(controller.document.backingString), delegate.blockTypes)
	}

	func testIndent() {
		let controller = DocumentController(backingString: "⧙doc-heading-fake-uuid⧘Title\n⧙checklist-0⧘-[ ] Hi", delegate: delegate)

		let will = expectation(description: "willUpdate")
		delegate.willUpdate = { will.fulfill() }

		let insert = expectation(description: "didInsert")
		delegate.didInsert = { block, index in
			insert.fulfill()
		}

		let remove = expectation(description: "didRemove")
		delegate.didRemove = { block, index in
			remove.fulfill()
		}

		let did = expectation(description: "didUpdate")
		delegate.didUpdate = { did.fulfill() }

		controller.replaceCharactersInBackingRange(NSRange(location: 30, length: 1), withString: "1")
		waitForExpectations(timeout: 0.1, handler: nil)

		XCTAssertEqual(delegate.presentationString as String, controller.document.presentationString)
		XCTAssertEqual(blockTypes(controller.document.backingString), delegate.blockTypes)
	}
}
