//
//  DocumentTitle.swift
//  CanvasNative
//
//  Created by Sam Soffes on 11/19/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

import Foundation

public struct DocumentTitle: NativePrefixable, NodeContainer, InlineMarkerContainer, Equatable {

	// MARK: - Properties

	public var range: NSRange
	public var nativePrefixRange: NSRange
	public var visibleRange: NSRange
	public var uuid: String
	public var uuidRange: NSRange

	public var textRange: NSRange {
		return visibleRange
	}

	public var subnodes = [SpanNode]()
	public var inlineMarkerPairs = [InlineMarkerPair]()

	public var dictionary: [String: Any] {
		return [
			"type": "title",
			"uuid": uuid,
			"range": range.dictionary,
			"nativePrefixRange": nativePrefixRange.dictionary,
			"visibleRange": visibleRange.dictionary,
			"subnodes": subnodes.map { $0.dictionary },
			"inlineMarkerPairs": inlineMarkerPairs.map { $0.dictionary }
		]
	}


	// MARK: - Initializers

	public init?(string: String, range: NSRange) {
		
		guard let (nativePrefixRange, uuidRange, uuid, visibleRange) = DocumentTitle.parseUUID(
			string: string,
			range: range,
			delimiter: "doc-heading") else { return nil }

		self.range = range
		self.nativePrefixRange = nativePrefixRange
		self.visibleRange = visibleRange
		self.uuid = uuid
		self.uuidRange = uuidRange
	}

	static func parseUUID(string: String, range: NSRange, delimiter: String) -> (nativePrefixRange: NSRange, uuidRange: NSRange, uuid: String, visibleRange: NSRange)? {
		let scanner = Scanner(string: string)
		scanner.charactersToBeSkipped = nil
		
		// Delimiter
		if !scanner.scanString(leadingNativePrefix, into: nil) {
			return nil
		}
		
		if !scanner.scanString("\(delimiter)-", into: nil) {
			return nil
		}
		
		let leadingLocation = scanner.scanLocation
		
		// let uuidRange = NSRange(location:  range.location + leadingLocation, length: range.length - leadingLocation)
		var parsedUuid:NSString? = ""
		if !scanner.scanUpTo(trailingNativePrefix, into: &parsedUuid) {
			return nil
		}
		let uuidRange = NSRange(location: range.location + leadingLocation, length: parsedUuid!.length)
		let uuid = parsedUuid! as String
		
		if !scanner.scanString(trailingNativePrefix, into: nil) {
			return nil
		}
		let nativePrefixRange = NSRange(location: range.location, length: scanner.scanLocation)
		
		//let prefixRange = NSRange(location: range.location + startPrefix, length: scanner.scanLocation - startPrefix)
		
		// Content
		let visibleRange = NSRange(
			location: range.location + scanner.scanLocation,
			length: range.length - scanner.scanLocation
		)
		
		return (nativePrefixRange, uuidRange, uuid, visibleRange)
	}


	// MARK: - Node

	public mutating func offset(_ delta: Int) {
		range.location += delta
		nativePrefixRange.location += delta
		visibleRange.location += delta

		subnodes = subnodes.map {
			var node = $0
			node.offset(delta)
			return node
		}

		inlineMarkerPairs = inlineMarkerPairs.map {
			var pair = $0
			pair.offset(delta)
			return pair
		}
	}


	// MARK: - Native

	public static func nativeRepresentation(_ string: String? = nil, uuid: String) -> String {
		return "\(leadingNativePrefix)doc-heading-\(uuid)\(trailingNativePrefix)" + (string ?? "")
	}
}


public func ==(lhs: DocumentTitle, rhs: DocumentTitle) -> Bool {
	return NSEqualRanges(lhs.range, rhs.range) &&
		NSEqualRanges(lhs.nativePrefixRange, rhs.nativePrefixRange) &&
		NSEqualRanges(lhs.visibleRange, rhs.visibleRange)
}
