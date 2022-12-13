//
//  TapFixViewModel.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-12.
//

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
    var storedText: String
    
    internal init(_ word: String = "tapfix",
                  _ onChangeCallback: @escaping (_ oldText: String, _ newText: String) -> Bool = {oldText,newText in return true}) {
        self.tapFixActive = true
        self.textInput = ""
        self.textInputFocused = false
        self.activeReplaceId = -1
        self.storedText = word
        self.onChangeHandler = onChangeCallback
        
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
    
    func buttonDrag(direction: SwipeHVDirection, id: Int)
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
            self.textInputFocused = true
            self.activeReplaceId = id
        }
    }
    
    func keyboardInput(textField: BaseUITextField, range: NSRange, replacement: String) -> Bool
    {
        self.textInputFocused = false
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
        return false
    }

}
