//
//  CorrectableString.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2024-03-19.
//

import Foundation

struct CorrectableCharacter {
    let character: Character
    var needsCorrection: Bool
    var expectedCorrection: Character?
}

struct CorrectableString : CustomStringConvertible {
    private var characters: [CorrectableCharacter] = []

    var string: String {
        return String(characters.map { $0.character })
    }
    
    var description: String {
        return string
    }

    init(_ string: String) {
        self.characters = string.map { CorrectableCharacter(character: $0, needsCorrection: false) }
    }
    
    init(_ characters: [CorrectableCharacter]) {
        self.characters = characters
    }

    mutating func append(_ character: Character, needsCorrection: Bool) {
        characters.append(CorrectableCharacter(character: character, needsCorrection: needsCorrection))
    }
    
    mutating func append(_ character: CorrectableCharacter) {
        characters.append(character)
    }
    
    mutating func insert(_ character: Character, needsCorrection: Bool, at index: Int) {
        let correctableCharacter = CorrectableCharacter(character: character, needsCorrection: needsCorrection)
        characters.insert(correctableCharacter, at: index)
    }
    
    mutating func insert(_ character: CorrectableCharacter, at index: Int) {
        characters.insert(character, at: index)
    }

    mutating func delete(at index: Int) {
        characters.remove(at: index)
    }

    subscript(index: Int) -> CorrectableCharacter {
        get {
            return characters[index]
        }
        set {
            characters[index] = newValue
        }
    }
}
