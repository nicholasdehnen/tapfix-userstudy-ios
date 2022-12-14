//
//  TestManager.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation
import GameplayKit

class TestManager {
    
    var documentsDirectory: URL;
    var testDataFile: URL;
    var testIdentifier: String;
    var testData: TestData;
    var testDataFileSet: Bool = false;
    let jsonEncoder: JSONEncoder;
    
    var skipWarmups: Bool = false
    var skipTypingTest: Bool = false
    
    var finalTestOrder: [(method: TypoCorrectionMethod, type: TypoCorrectionType, isWarmup: Bool)] = []
    
    static let ParticipantIdLength: Int = 5
    static let TypingTestLength: Int = 20
    static let TestLength: Int = 30
    static let WarmupLength: Int = 15 // * 2 (replace, delete)
    
    static let shared = TestManager()
    private init()
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask);
        documentsDirectory = paths[0];
        testDataFile = documentsDirectory.appendingPathComponent("not-set.txt");
        testData = TestData();
        jsonEncoder = JSONEncoder();
        jsonEncoder.outputFormatting = .prettyPrinted
        testIdentifier = "not-set"
    }
    
    private func _updateResultsFile()
    {
        if(!testDataFileSet)
        {
            // get formatted date
            let dateFormatter = DateFormatter()
            dateFormatter.dateFormat = "yyyy-MM-dd_hh-mm"
            let formattedDate = dateFormatter.string(from: testData.TimeStamp)
            
            // create file name from participant id + date
            testIdentifier = "p\(testData.ParticipantId)_d\(formattedDate)"
            testDataFile = documentsDirectory.appendingPathComponent("\(testIdentifier).json");
            
            testDataFileSet = true;
        }
        
        do {
            let testDataJson = try jsonEncoder.encode(testData)
            try testDataJson.write(to: testDataFile)
        } catch let error {
            debugPrint(error.localizedDescription);
        }
    }
    
    func getResultsJson() -> Data
    {
        do {
            let testDataJson = try jsonEncoder.encode(testData)
            return testDataJson
        } catch let error {
            debugPrint(error.localizedDescription);
            return Data("{\"error\": \"\(error.localizedDescription)\"}".utf8)
        }
    }
    
    func getTestIdentifier() -> String
    {
        return testIdentifier
    }
    
    func setParticipantId(id: Int)
    {
        testData.ParticipantId = id;
        let idstr = String(id)
        if(idstr.starts(with: "9"))
        {
            skipWarmups = true
        }
        if(idstr[1...].starts(with: "9"))
        {
            skipTypingTest = true
        }
    }
    
    func addTypingWarmupResult(result: TypingWarmupResult)
    {
        testData.TypingWarmupResults.append(result);
        _updateResultsFile();
    }
    
    func addTypoCorrectionResult(result: TypoCorrectionResult)
    {
        testData.CorrectionResults.append(result);
        _updateResultsFile();
    }

    func generateTestOrder() -> [(method: TypoCorrectionMethod, type: TypoCorrectionType, isWarmup: Bool)]
    {
        if(finalTestOrder.count != 0)
        {
            return finalTestOrder
        }
        
        let mersenneTwister = GKMersenneTwisterRandomSource(seed: UInt64(testData.ParticipantId))
        let mandatoryTests: [(method: TypoCorrectionMethod, type: TypoCorrectionType, isWarmup: Bool)] = [
            (.SpacebarSwipe,        .Delete, false),
            (.TextFieldLongPress,   .Delete, false),
            (.TapFix,               .Delete, false),
            (.SpacebarSwipe,        .Replace, false),
            (.TextFieldLongPress,   .Replace, false),
            (.TapFix,               .Replace, false),
        ]
        var methodsSeen: [TypoCorrectionMethod : Bool] = [
            .SpacebarSwipe: false,
            .TextFieldLongPress: false,
            .TapFix: false
        ]
        
        let shuffledTests = mersenneTwister.arrayByShufflingObjects(in: mandatoryTests)
                                as! [(TypoCorrectionMethod, TypoCorrectionType, Bool)]
        
        for i in 0..<shuffledTests.count {
            let test = shuffledTests[i] as (method: TypoCorrectionMethod, type: TypoCorrectionType, isWarmup: Bool)
            if methodsSeen[test.method]! == false {
                // prepend warmup
                finalTestOrder.append((test.method, test.type, true))
                methodsSeen[test.method] = true
            }
            finalTestOrder.append(test)
        }
        
        return finalTestOrder
    }
}
