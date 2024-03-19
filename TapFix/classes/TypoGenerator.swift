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
    
    private func replaceCharacters(in string: String, at indices: [Int], with replacementCharacters: [Character]) -> String
    {
        var s = string
        (0..<indices.count).forEach { s = replaceCharacter(in: s, at: indices[$0], with: replacementCharacters[$0])}
        return s
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
    
    private func getRandomCharacters(unlike originalCharacters: [Character]) -> [Character]
    {
        return originalCharacters.map { getRandomCharacter(unlike: $0) }
    }
    
    private func getRandomIndices(for word: String, choose numberOfCharacters: Int) -> [Int]
    {
        var numberOfCharacters = numberOfCharacters
        if numberOfCharacters >= word.count {
            debugPrint("\(#function): Cannot generate \(numberOfCharacters) unique random indices for word \(word), more indices than letters requested!")
            numberOfCharacters = 1
        }
        var uniqueIndices = Set<Int>()
        while uniqueIndices.count < numberOfCharacters {
            let randomIndex = Int.random(in: 0..<word.count)
            uniqueIndices.insert(randomIndex)
        }
        return Array(uniqueIndices.sorted().reversed())
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
    
    private func generateReplaceTypeSentence(sentence: String, words: [String], wordIndex: Int, typoCount: Int = 1) -> TypoSentenceProtocol
    {
        let chosenWord = String(words[wordIndex]);
        let characterIndices = getRandomIndices(for: chosenWord, choose: typoCount)
        let replacementCharacters = getRandomCharacters(unlike: chosenWord[characterIndices])
        let typoWord = replaceCharacters(in: chosenWord, at: characterIndices, with: replacementCharacters)
        let (prefix, suffix, fullSentence, typoSentenceIndices) = assembleSentence(wordIndex: wordIndex, typoWord: typoWord, typoWordIndex: characterIndices, words: words)
        return MultipleTypoSentence(prefix: prefix, typo: typoWord, correction: chosenWord, suffix: suffix,
                            full: fullSentence, fullCorrect: sentence, typoCount: typoCount,
                            typoWordIndex: characterIndices, typoSentenceIndex: typoSentenceIndices)
    }
    
    private func generateDeleteTypeSentence(sentence: String, words: [String], wordIndex: Int, typoCount: Int = 1) -> TypoSentenceProtocol
    {
        let chosenWord = String(words[wordIndex]);
        var typoIndices = getRandomIndices(for: chosenWord, choose: typoCount)
        
        // get characters around the place where typo would be inserted
        var typoWord = chosenWord
        
        for i in 0..<typoIndices.count { // typoIndices is sorted in descending order
            let typoIndex = typoIndices[i]
            let charactersAroundTypo: [Character] = chosenWord.neighbours(of: typoIndex)
            let typoCharacter = getRandomCharacter(unlike: charactersAroundTypo)
            typoWord = insertOrAppend(character: typoCharacter, in: typoWord, at: typoIndex)
            
            // add offset to typoIndices to correct for characters going to be inserted in front of it
            typoIndices[i] += (typoIndices.count - 1) - i
        }
        
        let (prefix, suffix, fullSentence, typoSentenceIndices) = assembleSentence(wordIndex: wordIndex, typoWord: typoWord, typoWordIndex: typoIndices, words: words)
        return TypoSentence(prefix: prefix, typo: typoWord, correction: chosenWord, suffix: suffix,
                            full: fullSentence, fullCorrect: sentence,
                            typoWordIndex: typoIndices, typoSentenceIndex: typoSentenceIndices)
    }
    
    private func generateInsertTypeSentence(sentence: String, words: [String], wordIndex: Int , typoCount: Int = 1) -> TypoSentenceProtocol
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
    
    private func generateSwapTypeSentence(sentence: String, words: [String], wordIndex: Int, longDistance: Bool = false) -> TypoSentenceProtocol
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
        while(words[wordIndex].count <= 3) // do not select words of length 1 - 3
        {
            wordIndex = Int.random(in: 0...words.count-1)
        }
        
        //let randDbl = Double.random(in: 0.0...1.0)
        //let typoCount = randDbl < 0.25 ? 2 : 1 // 25% chance of generating 2, 75% of generating 1
        let typoCount = 1 // more would need massive logic changes in VMs
        
        index += 1
        
        switch(type)
        {
        case TypoCorrectionType.Replace:
            return generateReplaceTypeSentence(sentence: sentence, words: words, wordIndex: wordIndex, typoCount: typoCount)
        case TypoCorrectionType.Delete:
            return generateDeleteTypeSentence(sentence: sentence, words: words, wordIndex: wordIndex, typoCount: typoCount)
        case TypoCorrectionType.Insert:
            return generateInsertTypeSentence(sentence: sentence, words: words, wordIndex: wordIndex, typoCount: typoCount)
        case TypoCorrectionType.Swap:
            return generateSwapTypeSentence(sentence: sentence, words: words, wordIndex: wordIndex) // typoCount ignored for Swap: Always returns 2 typos
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
