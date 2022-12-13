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
    
    internal init(word: String = "tapfix") {
        self.tapFixActive = true
        self.textInput = ""
        self.textInputFocused = false
        self.activeReplaceId = -1
        
        self.tapFixCharacters = generateTapFixCharacters(word: word)
    }
    
    func generateTapFixCharacters(word: String) -> [TapFixCharacter]
    {
        var chars: [TapFixCharacter] = []
        for i in 0..<word.count
        {
            chars.append(TapFixCharacter(word[i].lowercased(), i))
        }
        return chars
    }
    
    func buttonDrag(direction: SwipeHVDirection, id: Int)
    {
        if(direction == .up)
        {
            self.tapFixCharacters = self.tapFixCharacters.filter { $0.Id != id }
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
                    tapFixCharacters[i].Character = replacement.first!.lowercased()
                }
            }
            activeReplaceId = -1
        }
        return false
    }

}
