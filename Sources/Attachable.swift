//
//  Attachable.swift
//  CanvasNative
//
//  Created by Sam Soffes on 11/25/15.
//  Copyright © 2015 Canvas Labs, Inc. All rights reserved.
//

public protocol Attachable: NativePrefixable {
	var attachmentMarker: String { get }
}

extension Attachable {
	public var visibleRange: NSRange {
		return NSRange(location: nativePrefixRange.max, length: 1)
	}

	public var hiddenRanges: [NSRange] {
		return [NSRange(location: nativePrefixRange.location, length: nativePrefixRange.length - 1)]
	}
}
