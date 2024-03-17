//
//  TestData.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation

typealias TestOrderInformation = (method: TypoCorrectionMethod, type: TypoCorrectionType, isWarmup: Bool)

enum TypoCorrectionMethod : String, Codable {
    case SpacebarSwipe = "SpacebarSwipe"
    case TextFieldLongPress = "TextLens"
    case TapFix = "TapFix"
    
    var description: String {
        switch self {
        case .SpacebarSwipe: return "SpacebarSwipe"
        case .TextFieldLongPress: return "MagnifyingGlass"
        case .TapFix: return "TapFix"
        }
    }
}

enum TypoCorrectionType : String, Codable {
    case Replace = "Replace"
    case Delete = "Delete"
    case Insert = "Insert"
    case Swap = "Swap"
    
    var description: String {
        switch self {
        case .Replace: return "Replace"
        case .Delete: return "Delete"
        case .Insert: return "Insert"
        case .Swap: return "Swap"
        }
    }
}

struct TypingWarmupResult : Codable {
    var Id: Int;
    var CorrectSentence: String;
    var TypedSentence: String;
    var TaskCompletionTime: Double;
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case Id, CorrectSentence, TypedSentence, TaskCompletionTime
    }
}

struct TypoCorrectionResult : Codable {
    var Id: Int;
    var CorrectionMethod: TypoCorrectionMethod;
    var CorrectionType: TypoCorrectionType;
    
    var FaultySentence: String;
    var UserCorrectedSentence: String;
    
    var TaskCompletionTime: Double;
    var MethodActivationTime: Double;
    var CursorPositioningTime: Double;
    var CharacterDeletionTime: Double;
    var CharacterInsertionTime: Double;
    
    var Flagged: Bool;
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case Id, Flagged, CorrectionMethod, CorrectionType, TaskCompletionTime, MethodActivationTime, CursorPositioningTime,
             CharacterDeletionTime, CharacterInsertionTime, FaultySentence, UserCorrectedSentence
    }
}

struct TestInformation : Codable {
    var AppVersion: String
    var ParticipantId: Int
    var TimeStamp: Date
    
    enum CodingKeys: String, CodingKey, CaseIterable {
        case AppVersion, ParticipantId, TimeStamp
    }
}


struct TestData : Codable {
    var Information: TestInformation = TestInformation (
        AppVersion: Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown",
        ParticipantId: 0,
        TimeStamp: Date.now
    )
    
    var TypingWarmupResults: [TypingWarmupResult] = []
    var CorrectionResults: [TypoCorrectionResult] = []
}
