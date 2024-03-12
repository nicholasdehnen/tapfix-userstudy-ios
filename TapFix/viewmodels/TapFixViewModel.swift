//
//  TapFixViewModel.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-12.
//

import SwiftUI
import Foundation
import UIKitTextField
import Willow

/*
 SwipeHVDirection / detectDirection from: https://stackoverflow.com/a/61806129
 */
enum SwipeHVDirection: String {
    case left, right, up, down, none
}

struct TapFixCharacter
{
    var Character: String
    var Id: Int
    
    init(_ character: String, _ id: Int)
    {
        Character = character
        Id = id
    }
}

class TapFixViewModel : ObservableObject
{
    @Published private(set) var tapFixCharacters: [TapFixCharacter] = [TapFixCharacter("t", 0), TapFixCharacter("a", 1), TapFixCharacter("p", 2),
                                                                       TapFixCharacter("f", 3), TapFixCharacter("i", 4), TapFixCharacter("x", 5)]
    @Published var tapFixActive: Bool
    @Published var textInput: String
    @Published var textInputFocused: Bool
    @Published var activeReplaceId: Int
    
    // allowed methods
    @Published var methodDeleteAllowed: Bool = false
    @Published var methodReplaceAllowed: Bool = false
    @Published var methodSwapAllowed: Bool = false
    @Published var methodInsertAllowed: Bool = false
    
    var onChangeHandler: (_ oldText: String, _ newText: String) -> Bool
    var onTouchedHandler: (_ character: String, _ position: Int) -> Void
    var onUserFlagHandler: () -> Void
    var storedText: String
    
    private let logger = buildWillowLogger(name: "TapFixVM")
    
    internal init(_ word: String = "tapfix",
                  _ onChangeCallback: @escaping (_ oldText: String, _ newText: String) -> Bool = {oldText,newText in return true},
                  _ onTouchedCallback: @escaping (_ character: String, _ position: Int) -> Void = {character,position in /*..*/},
                  _ onUserFlagCallback: @escaping () -> Void = {},
                  _ methodsAllowed : [TypoCorrectionType] = [.Delete, .Replace, .Swap, .Insert]) {
        self.tapFixActive = true
        self.textInput = ""
        self.textInputFocused = true // used to be: false, now always focussed.
        self.activeReplaceId = -1
        self.storedText = word
        self.onChangeHandler = onChangeCallback
        self.onTouchedHandler = onTouchedCallback
        self.onUserFlagHandler = onUserFlagCallback
        self.tapFixCharacters = generateTapFixCharacters(word: word)
        for method in methodsAllowed
        {
            switch method
            {
            case .Delete:
                self.methodDeleteAllowed = true
            case .Replace:
                self.methodReplaceAllowed = true
            case .Swap:
                self.methodSwapAllowed = true
            case .Insert:
                self.methodInsertAllowed = true
                self.methodSwapAllowed = true
            }
        }
    }
    
    // Convenience function to update characters from String, wraps self.updateCharacters([TapFixCharacter])
    public func updateCharacters(_ newWord: String)
    {
        let tapFixChars = generateTapFixCharacters(word: newWord)
        self.updateCharacters(tapFixChars)
    }
    
    // Convenience function to swap TapFixCharacters, wraps self.updateCharacters([TapFixCharacter])
    public func swapCharacters(_ indexFrom: Int, _ indexTo: Int)
    {
        let tapFixChars = tapFixCharacters.swapping(indexFrom, with: indexTo)
        self.updateCharacters(tapFixChars)
    }
    
    // Convenience function to move TapFixCharacter, wraps self.updateCharacters([TapFixCharacter])
    public func moveCharacter(_ indexFrom: Int, _ indexTo: Int) {
        // Ensure indexFrom and indexTo are within the array bounds
        guard indexFrom < tapFixCharacters.count && indexTo <= tapFixCharacters.count else
        {
            logger.warnMessage("\(#function): Rejecting out of bounds move, indexFrom=\(indexFrom), indexTo=\(indexTo), count=\(self.tapFixCharacters.count)")
            return
        }
        
        var tapFixChars = tapFixCharacters
        let char = tapFixChars.remove(at: indexFrom)
        // no adjustment to indexTo needed when indexFrom < indexTo since we want to shift the remaining characters to the left
        tapFixChars.insert(char, at: indexTo)
        
        self.updateCharacters(tapFixChars)
    }
    
    // Updates TapFix character array and publishes changes
    // Only method that should be used to update TapFix characters
    public func updateCharacters(_ newCharacters: [TapFixCharacter])
    {
        self.storedText = getTapFixCharactersAsString(self.tapFixCharacters)
        let newText = getTapFixCharactersAsString(newCharacters)
        
        logger.debugMessage("\(#function): oldText: \(self.storedText) -> newText: \(newText)")
        if(self.storedText == newText)
        {
            logger.debugMessage("\(#function): No change, ignoring.")
        }
        else if(self.onChangeHandler(self.storedText, newText))
        {
            logger.debugMessage("\(#function): Accepted by change handler, updating.")
            self.storedText = newText
            self.tapFixCharacters = newCharacters
        }
        else
        {
            logger.debugMessage("\(#function): Rejected by change handler!")
        }
    }
    
    private func generateTapFixCharacters(word: String) -> [TapFixCharacter]
    {
        logger.debugMessage("\(#function): word = \(word)")
        var chars: [TapFixCharacter] = []
        for i in 0..<word.count
        {
            chars.append(TapFixCharacter(word[i].lowercased(), i))
        }
        return chars
    }
    
    private func getTapFixCharactersAsString(_ tapFixCharacters: [TapFixCharacter]) -> String
    {
        var stringRep = ""
        for c in tapFixCharacters
        {
            stringRep += c.Character
        }
        return stringRep
    }
    
    func getCharacterInfoForId(id: Int) -> (String, Int)
    {
        var index = -1
        var character = "?"
        for i in 0..<tapFixCharacters.count
        {
            if tapFixCharacters[i].Id == id
            {
                index = i
                character = tapFixCharacters[i].Character
                break
            }
        }
        return (character, index)
    }
    
    func onCharacterTouchStart(id: Int)
    {
        let (character, index) = getCharacterInfoForId(id: id)
        logger.debugMessage("\(#function): Character \(character) with id \(id) at index \(index)")
        self.onTouchedHandler(character, index)
    }
    
    func onCharacterTouchEnd(id: Int)
    {
        let (character, index) = getCharacterInfoForId(id: id)
        logger.debugMessage("\(#function): Character \(character) with id \(id) at index \(index)")
    }
    
    func buttonDrag(direction: SwipeHVDirection, id: Int, dragTarget: Int = -1)
    {
        logger.debugMessage("\(#function): direction = \(direction), id = \(id), dragTarget = \(dragTarget)")
        if(self.methodDeleteAllowed && direction == .up)
        {
            self.storedText = getTapFixCharactersAsString(self.tapFixCharacters)
            let newCharacters = self.tapFixCharacters.filter { $0.Id != id }
            self.updateCharacters(newCharacters)
        }
        
        if(self.methodReplaceAllowed && direction == .down)
        {
            //self.textInputFocused = true
            self.activeReplaceId = id
        }
        
        if(self.methodSwapAllowed && dragTarget != -1) {
            
            let charIndex = Int(self.tapFixCharacters.firstIndex(where: { $0.Id == id }) ?? 0)
            
            // make sure dragTarget is legal (within self.tapFixCharacters length)
            var finalDragTarget = dragTarget
            let dragTargetVal = min(max(dragTarget, 0), self.tapFixCharacters.count - 1)
            if(dragTarget != dragTargetVal)
            {
                logger.warnMessage("\(#function): illegal dragTarget \(dragTarget) (out of bounds), setting to \(dragTargetVal)!")
                finalDragTarget = dragTargetVal
            }
            
            // move from charIndex to dragTarget
            self.moveCharacter(charIndex, finalDragTarget)
            self.storedText = getTapFixCharactersAsString(self.tapFixCharacters)
        }
    }
    
    func keyboardInput(textField: BaseUITextField, range: NSRange, replacement: String) -> Bool
    {
        //textInput is now always focussed to allow for input. TODO: See if constant textInput focus has bad consequences.
        //self.textInputFocused = false
        logger.debugMessage("\(#function): range = \(range), replacement = \(replacement))")
        
        // check if method allowed
        if(!(self.methodInsertAllowed || (self.methodReplaceAllowed && activeReplaceId != -1)))
        {
            logger.debugMessage("\(#function): not allowed to replace or insert, rejecting.")
            return false
        }
        
        if(activeReplaceId != -1)
        {
            for i in 0..<tapFixCharacters.count
            {
                if(tapFixCharacters[i].Id == activeReplaceId && replacement.first != nil)
                {
                    var changedCharacters = self.tapFixCharacters
                    changedCharacters[i].Character = replacement.first!.lowercased()
                    logger.debugMessage("\(#function): replacing character at index \(i) (= \(changedCharacters[i].Character)) with \(replacement)")
                    self.updateCharacters(changedCharacters)
                }
            }
            activeReplaceId = -1
        }
        else
        {
            let chars = getTapFixCharactersAsString(self.tapFixCharacters)
            // insert replacement in the middle
            let midpoint = Int(round(Double(chars.count) / 2))
            let newChars = String(chars.prefix(midpoint)) + replacement + String(chars.suffix(chars.count - midpoint))
            logger.debugMessage("\(#function): inserting \(replacement) at midpoint \(midpoint), \(chars) -> \(newChars)")
            self.updateCharacters(newChars)
        }
        
        return false // always return false, we never actually want anything in the textfield, changes happen in tapfix characters
    }
    
    func userFlag()
    {
        logger.debugMessage("\(#function): User flagged this test.")
        self.onUserFlagHandler()
    }
}
