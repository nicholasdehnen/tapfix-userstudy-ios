//
//  TestData.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation

enum TypoCorrectionMethod : String, Codable {
    case SpacebarSwipe = "SpacebarSwipe"
    case TextFieldLongPress = "TextLens"
    case TapFix = "TapFix"
    
    var description: String {
        switch self {
        case .SpacebarSwipe: return "SpacebarSwipe"
        case .TextFieldLongPress: return "TextLens"
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
    var CharacterInsertionTime: Double;
    
    var Flagged: Bool;
}

struct TestData : Codable {
    var AppVersion: String = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "unknown";
    var ParticipantId: Int = 0;
    var TimeStamp: Date = Date.now;
    
    var TypingWarmupResults: [TypingWarmupResult] = []
    var CorrectionResults: [TypoCorrectionResult] = []
}
