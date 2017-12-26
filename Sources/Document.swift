//
//  Document.swift
//  CanvasNative
//
//  Created by Sam Soffes on 4/11/16.
//  Copyright © 2016 Canvas Labs, Inc. All rights reserved.
//

#if os(OSX)
	import AppKit
#else
	import UIKit
// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func < <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l < r
  case (nil, _?):
    return true
  default:
    return false
  }
}

// FIXME: comparison operators with optionals were removed from the Swift Standard Libary.
// Consider refactoring the code to use the non-optional operators.
fileprivate func > <T : Comparable>(lhs: T?, rhs: T?) -> Bool {
  switch (lhs, rhs) {
  case let (l?, r?):
    return l > r
  default:
    return rhs < lhs
  }
}

#endif

/// Model that contains Canvas Native backing string, BlockNodes, and presentation string. Several methods for doing
/// calculations on the strings or nodes are provided.
public struct Document {

	// MARK: - Types

	public enum Direction: String {
		case leading, trailing
	}


	// MARK: - Properties

	/// Backing Canvas Native string
	public let backingString: String

	/// Presentation string for use in a text view
	public let presentationString: String

	/// Models for each line
	public let blocks: [BlockNode]

	/// The title of the document
	public var title: String? {
		guard let title = blocks.first as? DocumentTitle else { return nil }

		let titleDocument = Document(backingString: backingString, presentationString: "", blocks: [title], hiddenRanges: [], blockRanges: [])
		let renderer = PlainRenderer(document: titleDocument)
		return renderer.render()
	}
	
	/// The summary of the document, skip blank lines and find the second non-blank line
	// (the first non-blank line is the title)
	public var summary: String? {
		
		var summaryLine:String?
		presentationString.enumerateLines { (line, stop) in
			if !line.isEmpty {
				if summaryLine != nil {
					stop = true
				}
				summaryLine = line
			}
		}
		return summaryLine
	}

	fileprivate let hiddenRanges: [NSRange]
	fileprivate let blockRanges: [NSRange]


	// MARK: - Initializers
	
	/* public init(backingString: String, presentationString: String, blocks: [BlockNode], hiddenRanges: [NSRange], blockRanges: [NSRange]) {
		self.backingString = backingString
		self.presentationString = presentationString
		self.blocks = blocks
		self.hiddenRanges = hiddenRanges
		self.blockRanges = blockRanges
	} */

	public static func createDocument(backingString: String, blocks: [BlockNode]? = nil)  -> Document {
		let blocks = blocks ?? Parser.parse(backingString)
		
		let text = backingString as NSString
		
		var presentationString = ""
		var hiddenRanges = [NSRange]()
		var blockRanges = [NSRange]()
		var location: Int = 0
		
		for (i, block) in blocks.enumerated() {
			let isLast = (i == blocks.count - 1)
			var blockRange = NSRange(location: location, length: 0)
			hiddenRanges += block.hiddenRanges
			
			if let attachmentBlock = block as? Attachable {
				let marker = attachmentBlock.attachmentMarker
				presentationString += marker
				location += marker.utf16.count
			} else {
				// Get the raw text of the line
				let line = NSMutableString(string: text.substring(with: block.range))
				
				// Remove hidden ranges
				var offset = block.range.location
				for range in block.hiddenRanges {
					line.replaceCharacters(in: NSRange(location: range.location - offset, length: range.length), with: "")
					offset += range.length
				}
				
				presentationString += line as String
				location += block.range.length - offset + block.range.location
			}
			
			// Add block range.
			blockRange.length = location - blockRange.location
			blockRanges.append(blockRange)
			
			// New line if we're not at the end. This isn't included in the block's range.
			if !isLast {
				presentationString += "\n"
				location += 1
			}
		}

		return Document(backingString: backingString, presentationString: presentationString, blocks: blocks, hiddenRanges: hiddenRanges, blockRanges: blockRanges)
	}

	// MARK: - Converting Backing Ranges to Presentation Ranges

	public func presentationRange(backingRange: NSRange) -> NSRange {
		var presentationRange = backingRange

		for hiddenRange in hiddenRanges {
			// After the desired range
			if hiddenRange.location > backingRange.max {
				break
			}

			if hiddenRange.max <= backingRange.location {
				presentationRange.location -= hiddenRange.length
			} else if let intersection = backingRange.intersectionLength(hiddenRange) {
				presentationRange.length -= intersection
			}
		}

		return presentationRange
	}

	public func presentationRange(block: BlockNode) -> NSRange {
		guard let index = indexOf(block: block) else { return block.visibleRange }
		return presentationRange(blockIndex: index)
	}

	public func presentationRange(blockIndex index: Int) -> NSRange {
		return blockRanges[index]
	}


	// MARK: - Converting Presentation Ranges to Backing Ranges

	
	// Convert a single point (location, not a range) into a selection.
	public func backingRange(presentationLocation: UInt) -> NSRange {
		
		var backingRange = preBackingRange(NSRange(location: Int(presentationLocation), length: 0))
		let inlineMarkerPairs = blocks.flatMap { ($0 as? InlineMarkerContainer)?.inlineMarkerPairs }.reduce([], +)

		// Adjust for inline markers
		for pair in inlineMarkerPairs {
			// If inserting at the beginning of the pair, do it outside
			if backingRange.location == pair.visibleRange.location {
				backingRange.location = pair.openingMarker.range.location
			}

				// If inserting at the end of the pair, do it outside
			else if backingRange.location == pair.closingMarker.range.max {
				backingRange.location = pair.closingMarker.range.location
			}
		}

		return backingRange
	}

	public func backingRanges(presentationRange: NSRange) -> [NSRange] {
		if presentationRange.length == 0 {
			return [backingRange(presentationLocation: UInt(presentationRange.location))]
		}

		let pre = preBackingRange(presentationRange)

		var output = NoncontiguousRange(ranges: [pre])
		let inlineMarkerPairs = blocks.flatMap { ($0 as? InlineMarkerContainer)?.inlineMarkerPairs }.reduce([], +)

		// Adjust for inline markers
		for pair in inlineMarkerPairs {

			// Delete the entire pair if all of it is in the selection
			if output.intersectionLength(pair.visibleRange) == pair.visibleRange.length {
				output.insert(range: pair.range)
			} else {
				// Remove any markers from the range
				output.remove(range: pair.openingMarker.range)
				output.remove(range: pair.closingMarker.range)
			}
		}

		return output.ranges
	}
	
	/*
     * This function computes the backing range of a presentation range.
	 * This backingRange should include the preamble (non-visible) part of the backingString.
	 *
	 * The location of the backingRange will be the backed up to the start of the enclosing hidden text if we
	 * butt up against it.  The range will cover any backup.
	 *
	 * I believe that the caller of this function should modify their use of this depending if they are selecting something or just inserting something or just deleting something.
	 */

	fileprivate func preBackingRange(_ presentationRange: NSRange) -> NSRange {
		var backingRange = presentationRange
		
		// Account for all hidden ranges preceeding this presentation range
		// Compute the effective backing range by incrementing the backingRange forward
		for hiddenRange in hiddenRanges {
			
			// Hidden range starts before backing range so we need to adjust the backingRange to skip over it
			if hiddenRange.location < backingRange.location {
				// Skip forward over the entire hidden range
				backingRange.location += hiddenRange.length
				continue
			}
			
			// Shadow of hidden text intersects. Expand length (not location).
			// Note: we simpply care of the hidden range is within the backingRange
			// If it is, all of it applies to the expanded backingRange.
			//
			if hiddenRange.location <= backingRange.max {
				backingRange.length += hiddenRange.length
			}
			
			// NOPE, the rest of this comment is not true:  At this point, all other hidden ranges are after this presentation range so we can skip them
			// DONT TRY TO EXIT THIS LOOP EARLY:  We might have more than one hidden range that need to be accumulated, so we need to walk through all of them
			// -- NOPE: break
		}

		// Adjust for Image blocks
		for block in blocksIn(backingRange: backingRange) {
			// Images should be included when the corresponding 'root' section of the document is connected.
			// Note: we exclude attachments like HorizontalRule elements and other attachments in the future
			if let image = block as? Image {
				backingRange = backingRange.union(image.range)
			}
		}

		return backingRange
	}


	// MARK: - Querying Blocks

	public func blockAt(backingLocation: Int) -> BlockNode? {
		guard backingLocation >= 0  else { return nil }
		return blockAt(backingLocation: UInt(backingLocation))
	}

	public func blockAt(backingLocation: UInt) -> BlockNode? {
		// guard backingLocation >= 0  else { return nil }
		for (i, block) in blocks.enumerated() {
			if Int(backingLocation) < block.range.location {
				return blocks[i - 1]
			}
		}

		guard let block = blocks.last else { return nil }

		return block.range.contains(backingLocation) || block.range.max == Int(backingLocation) ? block : nil
	}

	public func blockAt(presentationLocation: Int, direction: Direction = .leading) -> BlockNode? {
		guard presentationLocation >= 0  else { return nil }
		return blockAt(presentationLocation: UInt(presentationLocation), direction: direction)
	}

	/// Find a block at a given location in the presentation string.
	///
	/// - parameter presentationLocation: Location in the presentation string
	/// - parameter direction: Specify which block should be returned if the character is a new line.
	/// - returns: A block if one is found.
	public func blockAt(presentationLocation: UInt, direction: Direction = .leading) -> BlockNode? {
		let location = Int(presentationLocation)

		for (i, range) in blockRanges.enumerated() {
			// If it's the new line between two blocks, use the second block
			if direction == .trailing && location + 1 == range.location {
				return blocks[i]
			}

			if location < range.location {
				return blocks[i - 1]
			}
		}

		guard let block = blocks.last else { return nil }

		let presentationRange = self.presentationRange(block: block)
		return presentationRange.contains(presentationLocation) || presentationRange.max == location ? block : nil
	}

	public func blocksIn(presentationRange: NSRange) -> [BlockNode] {
		return blocks.filter { block in
			var range = self.presentationRange(block: block)
			range.length += 1
			return range.intersection(presentationRange) != nil
		}
	}

	public func blocksIn(backingRange: NSRange) -> [BlockNode] {
		return blocks.filter { block in
			var range = block.range
			range.length += 1
			return range.intersection(backingRange) != nil
		}
	}

	public func nodesIn(backingRange: NSRange) -> [Node] {
		return nodesIn(backingRange: backingRange, nodes: blocks.map({ $0 as Node }))
	}

	public func nodesIn(backingRanges: [NSRange]) -> [Node] {
		guard let first = backingRanges.first else { return [] }
		let range = backingRanges.reduce(first) { $0.union($1) }
		return nodesIn(backingRange: range, nodes: blocks.map({ $0 as Node }))
	}

	fileprivate func nodesIn(backingRange: NSRange, nodes: [Node]) -> [Node] {
		var results = [Node]()

		for node in nodes {
			let contained: Bool
			// Include the node that the selection includes, even if it is just the cursor (length == 0)
			if backingRange.length == 0 {
				contained = node.range.contains(backingRange.location) || (node.range.location + node.range.length == backingRange.location + backingRange.length)
			} else {
				contained = node.range.intersection(backingRange) != nil
			}
			if  contained {
				results.append(node)

				if let node = node as? NodeContainer {
					results += nodesIn(backingRange: backingRange, nodes: node.subnodes.map { $0 as Node })
				}
			}
		}

		return results
	}

	public func indexOf(block: BlockNode) -> Int? {
		return blocks.index(where: { NSEqualRanges($0.range, block.range) })
	}


	// MARK: - Presentation String

	public func presentationString(block: BlockNode) -> String {
		return presentationString(backingRange: block.range)
	}

	public func presentationString(backingRange: NSRange) -> String {
		let text = NSMutableString(string: (backingString as NSString).substring(with: backingRange))

		var offset = backingRange.location
		for hiddenRange in hiddenRanges {
			// Before the desired ranage
			if hiddenRange.location < backingRange.location {
				continue
			}

			// After the desired range
			if hiddenRange.location > backingRange.max {
				break
			}

			// Adjust hidden range
			var range = hiddenRange
			range.location -= offset
			range.length = min(text.length - range.location, range.length)

			// Remove hidden range from presentation string
			text.replaceCharacters(in: range, with: "")
			offset += range.length
		}

		return text as String
	}


	// MARK: - Private

	fileprivate func present(backingString: String, blocks: [BlockNode]) -> (String, [NSRange], [NSRange]) {
		let text = backingString as NSString

		var presentationString = ""
		var hiddenRanges = [NSRange]()
		var blockRanges = [NSRange]()
		var location: Int = 0

		for (i, block) in blocks.enumerated() {
			let isLast = i == blocks.count - 1
			var blockRange = NSRange(location: location, length: 0)
			hiddenRanges += block.hiddenRanges
			
			if block is Attachable {
				// Special case for attachments
				#if os(watchOS)
					presentationString += "🖼"
				#else
					presentationString += String(Character(UnicodeScalar(NSAttachmentCharacter)!))
				#endif
				
				location += 1
			} else {
				// Get the raw text of the line
				let line = NSMutableString(string: text.substring(with: block.range))

				// Remove hidden ranges
				var offset = block.range.location
				for range in block.hiddenRanges {
					line.replaceCharacters(in: NSRange(location: range.location - offset, length: range.length), with: "")
					offset += range.length
				}

				presentationString += line as String
				location += block.range.length - offset + block.range.location
			}

			// Add block range.
			blockRange.length = location - blockRange.location
			blockRanges.append(blockRange)

			// New line if we're not at the end. This isn't included in the block's range.
			if !isLast {
				presentationString += "\n"
				location += 1
			}
		}

		return (presentationString, hiddenRanges, blockRanges)
	}
}
