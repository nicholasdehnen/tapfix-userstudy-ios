//
//  TestData.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation

struct TypingWarmupResult : Codable {
    var Id: Int;
    var CorrectSentence: String;
    var TypedSentence: String;
    var TaskCompletionTime: Duration;
}

struct TypoCorrectionResult : Codable {
    var Id: Int;
    var CorrectionMethod: String;
    var CorrectionType: String;
    
    var FaultySentence: String;
    var UserCorrectedSentence: String;
    
    var TaskCompletionTime: Duration;
    var CursorPositioningTime: Duration;
}

struct TestData : Codable {
    var ParticipantId: Int = 0;
    var TimeStamp: Date = Date.now;
    
    var TypingWarmupResults: [TypingWarmupResult] = []
    var CorrectionResults: [TypoCorrectionResult] = []
}
