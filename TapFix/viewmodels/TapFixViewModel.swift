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
    @Published var selectedWordCharacters: [TapFixCharacter]
    @Published var tapFixActive: Bool
    @Published var textInput: String
    @Published var textInputFocused: Bool
    
    private var replaceId: Int
    
    internal init() {
        self.selectedWordCharacters = [TapFixCharacter("t", 0), TapFixCharacter("a", 1), TapFixCharacter("p", 2),
                                       TapFixCharacter("f", 3), TapFixCharacter("i", 4), TapFixCharacter("x", 5)]
        self.tapFixActive = true
        self.textInput = ""
        self.textInputFocused = false
        self.replaceId = -1
    }
    
    func buttonDrag(direction: SwipeHVDirection, id: Int)
    {
        if(direction == .up)
        {
            self.selectedWordCharacters = self.selectedWordCharacters.filter { $0.Id != id }
        }
        if(direction == .down)
        {
            self.textInputFocused = true
            self.replaceId = id
        }
    }
    
    func keyboardInput(textField: BaseUITextField, range: NSRange, replacement: String) -> Bool
    {
        self.textInputFocused = false
        if(replaceId != -1)
        {
            for i in 0..<selectedWordCharacters.count
            {
                if(selectedWordCharacters[i].Id == replaceId && replacement.first != nil)
                {
                    selectedWordCharacters[i].Character = replacement.first!.lowercased()
                }
            }
            replaceId = -1
        }
        return false
    }

}
