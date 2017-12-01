//
//  HorizontalRule.swift
//  CanvasNative
//
//  Created by Sam Soffes on 4/19/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

import Foundation
#if os(OSX)
	import AppKit
#else
	import UIKit
#endif

private let regularExpression = try! NSRegularExpression(pattern: "^(?:\\s{0,2}(?:(\\s?\\*\\s*?){3,})|(?:(\\s?-\\s*?){3,})|(?:(\\s?_\\s*?){3,})[ \\t]*)$", options: [])

public struct HorizontalRule: Attachable, Equatable {

	// MARK: - Properties

	public var range: NSRange
	public var nativePrefixRange: NSRange

	public var dictionary: [String: Any] {
		return [
			"type": "horizontal-rule",
			"range": range.dictionary,
			"nativePrefixRange": nativePrefixRange.dictionary,
		]
	}

	public var hiddenRanges: [NSRange] {
		// Need to include not just the prefix but the entire element, so add one to the nativePrefixRange
		// but then we need to recognize that there is ONE visible (well, sort of visible) character
		// that supports the drawing of the attachment/image.
		// So, we end up returning just the nativePrefixRange...
		return [nativePrefixRange]
	}
	
	public var attachmentMarker: String {
		get {
			return HorizontalRule.attachmentCharacter
		}
	}
	
	static private var attachmentCharacter: String {
		get {
		// Special case for attachments
		#if os(watchOS)
			return "🖼"
		#else
			return String(Character(UnicodeScalar(NSAttachmentCharacter)!))
		#endif
		}
	}



	// MARK: - Initializers

	public init?(string: String, range: NSRange) {
		if string != HorizontalRule.nativeRepresentation() {
			return nil
		}

		self.range = range
		nativePrefixRange = NSRange(location: range.location, length: range.length - 1) // Not including the trailing demark character?
	}


	// MARK: - Node

	public mutating func offset(_ delta: Int) {
		range.location += delta
		nativePrefixRange.location += delta
	}


	// MARK: - Native

	public static func nativeRepresentation() -> String {
		return "\(leadingNativePrefix)horizontal-rule\(trailingNativePrefix)\(HorizontalRule.attachmentCharacter)"
	}
}


public func == (lhs: HorizontalRule, rhs: HorizontalRule) -> Bool {
	return NSEqualRanges(lhs.range, rhs.range) &&
		NSEqualRanges(lhs.nativePrefixRange, rhs.nativePrefixRange)
}
