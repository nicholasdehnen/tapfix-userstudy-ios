//
//  TapFixTools.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2024-03-05.
//

import SwiftUI
import Foundation

class TapFixTools
{
    
    static func calculateSpacing(tapFixCharacterCount: Int) -> CGFloat
    {
        return CGFloat(min(max(1, (13+8)-tapFixCharacterCount), 8))
    }
    
    static func calculateTargetIndex(for id: Int, with gesture: DragGesture.Value, dir: SwipeHVDirection, characters: [TapFixCharacter], characterWidth: CGFloat, stackSpacing: CGFloat) -> Int {
        var currentIndex = 0
        for index in 0..<characters.count {
            if characters[index].Id == id {
                currentIndex = index
                break
            }
        }
        
        // Calculate the target index based on the translation
        let actualCharWidth = characterWidth + stackSpacing
        let distance = Int(gesture.translation.width / actualCharWidth)
        var targetIndex = currentIndex + distance

        // Adjust the target index based on the current index
        targetIndex = min(max(0, targetIndex), characters.count)

        return targetIndex
    }
    
    /*
     SwipeHVDirection / detectDirection from: https://stackoverflow.com/a/61806129
     Modified to allow disabling guard distance
     */
    static func detectDirection(value: DragGesture.Value, guardOn: Bool = true, guardDistance: CGFloat = 24) -> SwipeHVDirection {
        var guardDistance = guardDistance
        if !guardOn {
            guardDistance = 0
        }
        
        if value.startLocation.y < value.location.y - guardDistance {
            return .down
        }
        if value.startLocation.y > value.location.y + guardDistance {
            return .up
        }
        if value.startLocation.x < value.location.x - guardDistance {
            return .right
        }
        if value.startLocation.x > value.location.x + guardDistance {
            return .left
        }
        
        return .none
    }
    
}
