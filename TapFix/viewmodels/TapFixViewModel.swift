//
//  TapFixViewModel.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-12.
//

import SwiftUI
import Foundation
import UIKitTextField

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
    @Published var tapFixCharacters: [TapFixCharacter] = [TapFixCharacter("t", 0), TapFixCharacter("a", 1), TapFixCharacter("p", 2),
                                                          TapFixCharacter("f", 3), TapFixCharacter("i", 4), TapFixCharacter("x", 5)]
    @Published var tapFixActive: Bool
    @Published var textInput: String
    @Published var textInputFocused: Bool
    
    @Published var activeReplaceId: Int
    
    var onChangeHandler: (_ oldText: String, _ newText: String) -> Bool;
    var onTouchedHandler: (_ character: String, _ position: Int) -> Void
    var storedText: String
    var characterSize: CGSize
    
    internal init(_ word: String = "tapfix",
                  _ onChangeCallback: @escaping (_ oldText: String, _ newText: String) -> Bool = {oldText,newText in return true},
                  _ onTouchedCallback: @escaping (_ character: String, _ position: Int) -> Void = {character,position in /*..*/}) {
        self.tapFixActive = true
        self.textInput = ""
        self.textInputFocused = true // used to be: false, now always focussed.
        self.activeReplaceId = -1
        self.storedText = word
        self.onChangeHandler = onChangeCallback
        self.onTouchedHandler = onTouchedCallback
        self.characterSize = CGSize()
        self.tapFixCharacters = generateTapFixCharacters(word: word)
    }
    
    private func generateTapFixCharacters(word: String) -> [TapFixCharacter]
    {
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
    
    private func swapTapFixCharacters(id0: Int, id1: Int) -> Bool
    {
        var i0 = -1
        var i1 = -1
        
        for i in 0..<self.tapFixCharacters.count {
            if self.tapFixCharacters[i].Id == id0 {
                i0 = i
            }
            else if self.tapFixCharacters[i].Id == id1 {
                i1 = i
            }
        }
        
        if i0 == -1 || i1 == -1 {
            return false
        }
        
        var tmp_id = self.tapFixCharacters[i0].Id
        self.tapFixCharacters[i0].Id = self.tapFixCharacters[i1].Id
        self.tapFixCharacters[i1].Id = tmp_id
        
        self.tapFixCharacters.swapAt(i0, i1)
        return true
    }
    
    func onCharacterTouched(id: Int)
    {
        var offset = -1
        var character = "?"
        for i in 0..<tapFixCharacters.count
        {
            if tapFixCharacters[i].Id == id
            {
                offset = i
                character = tapFixCharacters[i].Character
                break
            }
        }
        
        self.onTouchedHandler(character, offset)
    }
    
    func updateCharacterSize(id: Int, size: CGSize) {
        self.characterSize = size
    }
    
    func buttonDrag(direction: SwipeHVDirection, id: Int, dragTarget: Int = -1)
    {
        if(direction == .up)
        {
            self.storedText = getTapFixCharactersAsString(self.tapFixCharacters)
            let newCharacters = self.tapFixCharacters.filter { $0.Id != id }
            let newText = getTapFixCharactersAsString(newCharacters)
            if newText != self.storedText && onChangeHandler(self.storedText, newText)
            {
                self.tapFixCharacters = newCharacters
            }
        }
        
        if(direction == .down)
        {
            //self.textInputFocused = true
            self.activeReplaceId = id
        }
        
        if(dragTarget != -1) {
            
            let charIndex = Int(self.tapFixCharacters.firstIndex(where: { $0.Id == id }) ?? 0)
            
            let el = self.tapFixCharacters.remove(at: charIndex)
            self.tapFixCharacters.insert(el, at: dragTarget)
        
            
            self.storedText = getTapFixCharactersAsString(self.tapFixCharacters)
        }
    }
    
    func keyboardInput(textField: BaseUITextField, range: NSRange, replacement: String) -> Bool
    {
        //textInput is now always focussed to allow for input. TODO: See if constant textInput focus has bad consequences.
        //self.textInputFocused = false
        if(activeReplaceId != -1)
        {
            for i in 0..<tapFixCharacters.count
            {
                if(tapFixCharacters[i].Id == activeReplaceId && replacement.first != nil)
                {
                    var changedCharacters = self.tapFixCharacters
                    changedCharacters[i].Character = replacement.first!.lowercased()
                
                    let newText = getTapFixCharactersAsString(changedCharacters)
                    let oldText = getTapFixCharactersAsString(self.tapFixCharacters)
                    if oldText != newText && onChangeHandler(oldText, newText)
                    {
                        self.tapFixCharacters = changedCharacters
                    }
                }
            }
            activeReplaceId = -1
        }
        else
        {
            // TODO: Smarter insert, use ML model here?
            let chars = getTapFixCharactersAsString(self.tapFixCharacters) + replacement
            if onChangeHandler(self.storedText, chars)
            {
                self.tapFixCharacters = generateTapFixCharacters(word: chars)
            }
        }
        return false
    }

}
