//
//  TypoSentence.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation

struct TypoSentence {
    public let Prefix: String;
    public let Typo: String;
    public let Correction: String;
    public let Suffix: String;
    public let Full: String;
    public let FullCorrect: String;
    
    public static let Empty: TypoSentence = TypoSentence(Prefix: "", Typo: "", Correction: "", Suffix: "", Full: "", FullCorrect: "")
}
