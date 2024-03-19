//
//  StringExtension.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-11.
//
import Foundation

// Taken partially from https://stackoverflow.com/a/38215613
extension StringProtocol {
    subscript(_ offset: Int)                     -> Element     { self[index(startIndex, offsetBy: offset)] }
    subscript(_ offsets: [Int])                  -> [Element]   { offsets.map { self[$0] } }
    subscript(_ range: Range<Int>)               -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }
    subscript(_ range: ClosedRange<Int>)         -> SubSequence { prefix(range.lowerBound+range.count).suffix(range.count) }
    subscript(_ range: PartialRangeThrough<Int>) -> SubSequence { prefix(range.upperBound.advanced(by: 1)) }
    subscript(_ range: PartialRangeUpTo<Int>)    -> SubSequence { prefix(range.upperBound) }
    subscript(_ range: PartialRangeFrom<Int>)    -> SubSequence { suffix(Swift.max(0, count-range.lowerBound)) }
    
    func neighbours(of characterIndex: Int) -> [Element] {
        var characterNeighbours: [Character] = []
        if characterIndex > 0 {
            characterNeighbours.append(self[characterIndex-1])
        }
        if characterIndex < self.count {
            characterNeighbours.append(self[characterIndex])
        }
        return characterNeighbours
    }
    
    func indices(of character: Character) -> [Int] {
        var indices = [Int]()
        for (index, eachCharacter) in self.enumerated() {
            if eachCharacter == character {
                indices.append(index)
            }
        }
        return indices
    }
}

