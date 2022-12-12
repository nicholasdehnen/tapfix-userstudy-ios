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

extension TypoGeneratorError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .sentencesEmpty:
            return NSLocalizedString("The base set of sentences passed to the TypoGenerator is empty.", comment: "TypoGeneratorError")
        }
    }
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
    
    private func _assembleSentence(wordIndex: Int, typoWord: String, words: [String]) -> (String, String, String) {
        let prefix = wordIndex != 0 ? words[0...max(wordIndex-1, 0)].joined(separator: " ") : ""
        let suffix = wordIndex != words.count-1 ? words[wordIndex+1...words.count-1].joined(separator: " ") : ""
        let fullSentence = (prefix.isEmpty ? "" : (prefix + " ")) + typoWord + (suffix.isEmpty ? "" : (" " + suffix))
        
        return (prefix, suffix, fullSentence)
    }
    
    private func _generateReplaceTypeSentence(sentence: String, words: [String]) -> TypoSentence
    {
        let wordIndex = Int.random(in: 0...words.count-1)
        let chosenWord = String(words[wordIndex]);
        let characterIndex = Int.random(in: 0...max(0, chosenWord.count-2)); //never pick last character
        let oldCharacter = String(chosenWord[characterIndex]);
        let charactersMod = characters.replacingOccurrences(of: oldCharacter, with: ""); // make sure we dont pick the same character
        let newCharacter = String(charactersMod[Int.random(in: 0...charactersMod.count-1)]);
        let typoWordStart = String(characterIndex != 0 ? chosenWord[0...max(0, characterIndex-1)] : "")
        let typoWordEnd = String(characterIndex != chosenWord.count-1 ? chosenWord[characterIndex+1...chosenWord.count-1] : "")
        let typoWord = String(typoWordStart + newCharacter + typoWordEnd)
        
        let (prefix, suffix, fullSentence) = _assembleSentence(wordIndex: wordIndex, typoWord: typoWord, words: words)
        
        return TypoSentence(Prefix: prefix, Typo: String(typoWord), Correction: chosenWord, Suffix: suffix, Full: fullSentence, FullCorrect: sentence)
    }
    
    private func _generateDeleteTypeSentence(sentence: String, words: [String]) -> TypoSentence
    {
        let wordIndex = Int.random(in: 0...words.count-1)
        let chosenWord = String(words[wordIndex]);
        let characterIndex = Int.random(in: 0...max(0, chosenWord.count-2)); //never pick last character
        let newCharacter = String(characters[Int.random(in: 0...characters.count-1)]);
        let typoWordStart = String(characterIndex != 0 ? chosenWord[0...max(0, characterIndex-1)] : "")
        let typoWordEnd = String(characterIndex != chosenWord.count-1 ? chosenWord[characterIndex...chosenWord.count-1] : "")
        let typoWord = String(typoWordStart + newCharacter + typoWordEnd)
        
        let (prefix, suffix, fullSentence) = _assembleSentence(wordIndex: wordIndex, typoWord: typoWord, words: words)
        
        return TypoSentence(Prefix: prefix, Typo: String(typoWord), Correction: chosenWord, Suffix: suffix, Full: fullSentence, FullCorrect: sentence)
    }
    
    public func generateSentence(type: TypoCorrectionType = TypoCorrectionType.Replace) -> TypoSentence
    {
        let sentence = sentences[index % (sentences.count-1)].lowercased();
        let components = sentence.components(separatedBy: chararacterSet);
        let words = components.filter { !$0.isEmpty };
        
        index += 1;
        
        switch(type)
        {
        case TypoCorrectionType.Replace:
            return _generateReplaceTypeSentence(sentence: sentence, words: words)
        case TypoCorrectionType.Delete:
            return _generateDeleteTypeSentence(sentence: sentence, words: words)
        }
    }
    
    public func generateSentences(num: Int, type: TypoCorrectionType) -> [TypoSentence]
    {
        var col: [TypoSentence] = [];
        for _ in 0...num {
            col.append(generateSentence(type: type))
        }
        return col
    }
    
}
