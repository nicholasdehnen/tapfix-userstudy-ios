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
    
    private func assembleSentence(wordIndex: Int, typoWord: String, typoWordIndex: [Int], words: [String]) -> (String, String, String, [Int]) {
        let prefix = (wordIndex != 0) ? words[0...max(wordIndex-1, 0)].joined(separator: " ") : ""
        let suffix = (wordIndex != words.count-1) ? words[wordIndex+1...words.count-1].joined(separator: " ") : ""
        
        let sentencePrefix = (prefix.isEmpty ? "" : (prefix + " "))
        let sentenceSuffix = (suffix.isEmpty ? "" : (" " + suffix))
        let fullSentence = sentencePrefix + typoWord + sentenceSuffix
        let typoSentenceIndex = typoWordIndex.map { sentencePrefix.count + $0 }
        
        return (prefix, suffix, fullSentence, typoSentenceIndex)
    }
    
    private func replaceCharacter(in string: String, at index: Int, with replacementCharacter: Character) -> String {
        guard index >= 0 && index < string.count else {
            return string // Index is out of bounds, or character string is empty.
        }
        
        var characters = Array(string)
        characters[index] = replacementCharacter
        return String(characters)
    }
    
    private func getRandomCharacter(unlike originalCharacters: [Character]) -> Character
    {
        var replacementCharacter = characters.randomElement()!
        while originalCharacters.contains(replacementCharacter) {
            replacementCharacter = characters.randomElement()!
        }
        return replacementCharacter
    }
    
    private func getRandomCharacter(unlike originalCharacter: Character) -> Character
    {
        return getRandomCharacter(unlike: [originalCharacter])
    }
    
    private func insertOrAppend(character: Character, in string: String, at index: Int) -> String
    {
        var string = string
        if index == string.count {
            string.append(character) // Append the character if index is at the end
        } else {
            let position = string.index(string.startIndex, offsetBy: index)
            string.insert(character, at: position) // Insert the character at the specified index
        }
        return string
    }
    
    private func generateReplaceTypeSentence(sentence: String, words: [String], wordIndex: Int) -> TypoSentence
    {
        let chosenWord = String(words[wordIndex]);
        let characterIndex = Int.random(in: 0...max(0, chosenWord.count-1));
        let replacementCharacter = getRandomCharacter(unlike: chosenWord[characterIndex])
        let typoWord = replaceCharacter(in: chosenWord, at: characterIndex, with: replacementCharacter)
        let (prefix, suffix, fullSentence, typoSentenceIndices) = assembleSentence(wordIndex: wordIndex, typoWord: typoWord, typoWordIndex: [characterIndex], words: words)
        return TypoSentence(prefix: prefix, typo: typoWord, correction: chosenWord, suffix: suffix,
                            full: fullSentence, fullCorrect: sentence,
                            typoWordIndex: [characterIndex], typoSentenceIndex: typoSentenceIndices)
    }
    
    private func generateDeleteTypeSentence(sentence: String, words: [String], wordIndex: Int) -> TypoSentence
    {
        let chosenWord = String(words[wordIndex]);
        let typoIndex = Int.random(in: 0...chosenWord.count)
        
        // get characters around the place where typo would be inserted
        var charactersAroundTypo: [Character] = []
        if typoIndex > 0 {
            charactersAroundTypo.append(chosenWord[typoIndex-1])
        }
        if typoIndex < chosenWord.count {
            charactersAroundTypo.append(chosenWord[typoIndex])
        }
        
        let typoCharacter = getRandomCharacter(unlike: charactersAroundTypo)
        let typoWord = insertOrAppend(character: typoCharacter, in: chosenWord, at: typoIndex)
        let (prefix, suffix, fullSentence, typoSentenceIndices) = assembleSentence(wordIndex: wordIndex, typoWord: typoWord, typoWordIndex: [typoIndex], words: words)
        return TypoSentence(prefix: prefix, typo: typoWord, correction: chosenWord, suffix: suffix,
                            full: fullSentence, fullCorrect: sentence,
                            typoWordIndex: [typoIndex], typoSentenceIndex: typoSentenceIndices)
    }
    
    private func generateInsertTypeSentence(sentence: String, words: [String], wordIndex: Int) -> InsertTypoSentence
    {
        let chosenWord = String(words[wordIndex])
        var characters = Array(chosenWord)
        let randomIndex = Int.random(in: 0..<characters.count)
        let removedCharacter = characters[randomIndex]
        characters.remove(at: randomIndex)
        let typoWord = String(characters)
        
        let (prefix, suffix, fullSentence, typoSentenceIndices) = assembleSentence(wordIndex: wordIndex, typoWord: typoWord, typoWordIndex: [randomIndex], words: words)
        return InsertTypoSentence(prefix: prefix, typo: typoWord, correction: chosenWord, suffix: suffix, full: fullSentence, fullCorrect: sentence,
                                  typoWordIndex: [randomIndex], typoSentenceIndex: typoSentenceIndices, characterToInsert: removedCharacter)
    }
    
    private func generateSwapTypeSentence(sentence: String, words: [String], wordIndex: Int, longDistance: Bool = false) -> TypoSentence
    {
        let chosenWord = String(words[wordIndex])
        var wordCharacters = Array(chosenWord)
        var swapIndex = 0
        var swapTarget = 0
        if longDistance {
            repeat { // keep re-rolling until we find indices which are atleast 2 characters apart and not the same character (!)
                swapIndex = Int.random(in: 0..<wordCharacters.count - 1)
                swapTarget = Int.random(in: 0..<wordCharacters.count - 1)
            } while (abs(swapTarget - swapIndex) < 2 && chosenWord[swapIndex] == chosenWord[swapTarget])
            wordCharacters.swapAt(swapIndex, swapTarget) // swap the characters at swapIndex and longDistanceIndex
        }
        else {
            repeat { // keep re-rolling until we find indices which are not the same character
                swapIndex = Int.random(in: 0..<wordCharacters.count - 1)
                let dir = Int.random(in: 0...1) == 0 ? -1 : 1 // random direction
                swapTarget = abs((swapIndex + dir) % wordCharacters.count)
            } while(chosenWord[swapIndex] == chosenWord[swapTarget])
            wordCharacters.swapAt(swapIndex, swapTarget)
        }
        let typoWord = String(wordCharacters)
        
        let (prefix, suffix, fullSentence, typoSentenceIndices) = assembleSentence(wordIndex: wordIndex, typoWord: typoWord, typoWordIndex: [swapIndex, swapTarget], words: words)
        return TypoSentence(prefix: prefix, typo: typoWord, correction: chosenWord, suffix: suffix,
                            full: fullSentence, fullCorrect: sentence,
                            typoWordIndex: [swapIndex, swapTarget], typoSentenceIndex: typoSentenceIndices)
    }
    
    public func generateSentence(type: TypoCorrectionType = TypoCorrectionType.Replace) -> TypoSentenceProtocol
    {
        let sentence = sentences[index % (sentences.count-1)].lowercased()
        let components = sentence.components(separatedBy: chararacterSet)
        let words = components.filter { !$0.isEmpty }
        var wordIndex = Int.random(in: 0...words.count-1)
        while(words[wordIndex].count <= 2) // do not select words of length 1 or 2
        {
            wordIndex = Int.random(in: 0...words.count-1)
        }
        
        index += 1
        
        switch(type)
        {
        case TypoCorrectionType.Replace:
            return generateReplaceTypeSentence(sentence: sentence, words: words, wordIndex: wordIndex)
        case TypoCorrectionType.Delete:
            return generateDeleteTypeSentence(sentence: sentence, words: words, wordIndex: wordIndex)
        case TypoCorrectionType.Insert:
            return generateInsertTypeSentence(sentence: sentence, words: words, wordIndex: wordIndex)
        case TypoCorrectionType.Swap:
            return generateSwapTypeSentence(sentence: sentence, words: words, wordIndex: wordIndex)
        }
    }
    
    public func generateSentences(num: Int, type: TypoCorrectionType) -> [TypoSentenceProtocol]
    {
        var col: [TypoSentenceProtocol] = [];
        for _ in 0...num {
            col.append(generateSentence(type: type))
        }
        return col
    }
    
}
