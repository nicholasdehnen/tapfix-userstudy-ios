//
//  TypoSentence.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation

protocol TypoSentenceProtocol {
    var prefix: String { get }
    var typo: String { get }
    var correction: String { get }
    var suffix: String { get }
    var full: String { get }
    var fullCorrect: String { get }
    
    var typoWordIndex: [Int] { get }
    var typoSentenceIndex: [Int] { get }
}

struct TypoSentence : TypoSentenceProtocol {
    let prefix: String;
    let typo: String;
    let correction: String;
    let suffix: String;
    let full: String;
    let fullCorrect: String;
    
    let typoWordIndex: [Int];
    let typoSentenceIndex: [Int];
    
    static let Empty: TypoSentence = TypoSentence(prefix: "", typo: "", correction: "", suffix: "", full: "", fullCorrect: "", typoWordIndex: [], typoSentenceIndex: [])
}

struct InsertTypoSentence : TypoSentenceProtocol {
    let prefix: String;
    let typo: String;
    let correction: String;
    let suffix: String;
    let full: String;
    let fullCorrect: String;
    
    let typoWordIndex: [Int];
    let typoSentenceIndex: [Int];
    
    // specific to InsertTypoSentence
    let characterToInsert: Character;
    
    
    static let Empty: InsertTypoSentence = InsertTypoSentence(prefix: "", typo: "", correction: "", suffix: "", full: "", fullCorrect: "", typoWordIndex: [], typoSentenceIndex: [], characterToInsert: "?")
}
