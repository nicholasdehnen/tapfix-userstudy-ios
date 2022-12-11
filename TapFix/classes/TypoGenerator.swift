//
//  TypoGenerator.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation

enum TypoGeneratorError: Error {
    case sentencesEmpty
}

class TypoGenerator
{
    let sentences: [String];
    var index: Int = 0;
    
    private let chararacterSet = CharacterSet.whitespacesAndNewlines.union(.punctuationCharacters);
    private let characters = "abcdefghijklmnopqrstuvwxyz";
    
    init(sentences: [String])
    {
        self.sentences = sentences
    }
    
    public func generateSentence() throws -> TypoSentence
    {
        if(sentences.isEmpty)
        {
            throw TypoGeneratorError.sentencesEmpty;
        }
        
        let sentence = sentences[index % (sentences.count-1)];
        let components = sentence.components(separatedBy: chararacterSet);
        let words = components.filter { !$0.isEmpty };
        
        let wordIndex = Int.random(in: 0...words.count-1)
        let chosenWord = words[wordIndex];
        let characterIndex = Int.random(in: 0...chosenWord.count-2); //never pick last character
        let newCharacter = String(characters[Int.random(in: 0...characters.count-1)]);
        let typoWordStart = String(characterIndex != 0 ? chosenWord[0...max(0, characterIndex-1)] : "")
        let typoWordEnd = String(characterIndex != chosenWord.count-1 ? chosenWord[characterIndex+1...chosenWord.count-1] : "")
        let typoWord = String(typoWordStart + newCharacter + typoWordEnd)
        
        let prefix = wordIndex != 0 ? words[0...max(wordIndex-1, 0)].joined(separator: " ") : ""
        let suffix = wordIndex != words.count-1 ? words[wordIndex+1...words.count-1].joined(separator: " ") : ""
        
        index += 1;
        return TypoSentence(Prefix: prefix, Typo: String(typoWord), Correction: chosenWord, Suffix: suffix)
    }
    
}
