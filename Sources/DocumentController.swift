//
//  DocumentController.swift
//  CanvasNative
//
//  Created by Sam Soffes on 2/18/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import Foundation

/// DocumentController delegate for notifications about changes to the owned document.  You can not rely upon these
/// messages to keep a parallel array in sync with the backing model. They are intended to be used for keeping
/// associated information in sync. After `documentControllerWillUpdateDocument` is called, all of the models will
/// reflect the new state.
public protocol DocumentControllerDelegate: class {
	// After this message, `document` will be the new value
	func documentControllerWillUpdateDocument(_ controller: DocumentController)

	// This will be called before all other messages.
	func documentController(_ controller: DocumentController, didReplaceCharactersInPresentationStringInRange range: NSRange, withString string: String)

	func documentController(_ controller: DocumentController, didInsertBlock block: BlockNode, atIndex index: Int)

	func documentController(_ controller: DocumentController, didRemoveBlock block: BlockNode, atIndex index: Int)

	// Changes to `document` are complete
	func documentControllerDidUpdateDocument(_ controller: DocumentController)
}


public final class DocumentController {

	// MARK: - Properties

	public weak var delegate: DocumentControllerDelegate?

	public fileprivate(set) var document = Document.createDocument(backingString: "")


	// MARK: - Initializers

	public init(backingString: String, delegate: DocumentControllerDelegate? = nil) {
		self.document = Document.createDocument(backingString: backingString)
		self.delegate = delegate

		let blankDocument = Document.createDocument(backingString:"")
		let (change, _) = replaceCharacters(inBackingRange: NSRange(location: 0, length: 0), withString: document.backingString, inDocument: blankDocument)
		processChange(change)
	}

	public init(document: Document? = nil, delegate: DocumentControllerDelegate? = nil) {
		self.document = document ?? Document.createDocument(backingString: "")
		self.delegate = delegate

		if let document = document {
			let blankDocument = Document.createDocument(backingString:"")
			let (change, _) = replaceCharacters(inBackingRange:NSRange(location: 0, length: 0), withString: document.backingString, inDocument: blankDocument)
			processChange(change)
		}
	}


	// MARK: - Changing Text

	public func replaceCharactersInBackingRange(_ range: NSRange, withString string: String) {
		let (change, _) = replaceCharacters(inBackingRange:range, withString: string, inDocument: document)
		processChange(change)
	}


	// MARK: - Private

	fileprivate func processChange(_ change: DocumentChange) {
		// Notifiy the delegate we have a change
		delegate?.documentControllerWillUpdateDocument(self)

		// Set the new document
		document = change.after

		// Notify about presentation string change
		if let presentationChange = change.presentationStringChange {
			delegate?.documentController(self, didReplaceCharactersInPresentationStringInRange: presentationChange.range, withString: presentationChange.replacement as String)
		}

		// Notify about AST changes (AST == Annotations, Styles, and Title)?  
		if let blockChange = change.blockChange {
			// Remove
			for i in blockChange.range.reversed() {
				delegate?.documentController(self, didRemoveBlock: change.before.blocks[i], atIndex: i)
			}

			// Insert
			for (i, block) in blockChange.replacement.enumerated() {
				delegate?.documentController(self, didInsertBlock: block, atIndex: blockChange.range.lowerBound + i)
			}
		}

		// Notifiy the delegate that we're done.
		delegate?.documentControllerDidUpdateDocument(self)
	}
}
