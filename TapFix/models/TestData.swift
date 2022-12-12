//
//  TestData.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation

enum TypoCorrectionMethod : Codable {
    case SpacebarSwipe
    case TextFieldLongPress
    case TapFix
}

enum TypoCorrectionType : Codable {
    case Replace
    case Delete
}

struct TypingWarmupResult : Codable {
    var Id: Int;
    var CorrectSentence: String;
    var TypedSentence: String;
    var TaskCompletionTime: Double;
}

struct TypoCorrectionResult : Codable {
    var Id: Int;
    var CorrectionMethod: TypoCorrectionMethod;
    var CorrectionType: TypoCorrectionType;
    
    var FaultySentence: String;
    var UserCorrectedSentence: String;
    
    var TaskCompletionTime: Double;
    var CursorPositioningTime: Double;
    var CharacterDeletionTime: Double;
}

struct TestData : Codable {
    var ParticipantId: Int = 0;
    var TimeStamp: Date = Date.now;
    
    var TypingWarmupResults: [TypingWarmupResult] = []
    var CorrectionResults: [TypoCorrectionResult] = []
}
