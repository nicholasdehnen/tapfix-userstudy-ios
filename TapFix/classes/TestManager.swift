//
//  TestManager.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation
import GameplayKit

//@MainActor
class TestManager : ObservableObject {
    
    var documentsDirectory: URL;
    var testDataFile: URL;
    var testIdentifier: String;
    var testData: TestData;
    var testDataFileSet: Bool = false;
    let jsonEncoder: JSONEncoder;
    
    var ParticipantId: Int {
        get {
            testData.ParticipantId
        }
        set(val) {
            objectWillChange.send()
            testData.ParticipantId = val
        }
    }
    
    @Published var TypingTestLength: Int = 20
    @Published var TestLength: Int = 25
    @Published var WarmupLength: Int = 10 // * 4 (replace, delete, insert, swap)
    
    @Published var SkipWarmups: Bool = false
    @Published var SkipTypingTest: Bool = false
    
    @Published var UseForcedWaitTime: Bool = true
    @Published var WaitTimesForCorrectionTypes: [TypoCorrectionType: Int] = [
        .Replace: 3,
        .Delete: 1, // easiest to grasp
        .Insert: 3,
        .Swap: 2
    ]
    
    @Published var TestOrder: [(method: TypoCorrectionMethod, type: TypoCorrectionType, isWarmup: Bool)] = []
    
    
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

    @discardableResult
    func generateTestOrder(regenerate: Bool = false) -> [(method: TypoCorrectionMethod, type: TypoCorrectionType, isWarmup: Bool)]
    {
        if(!regenerate && TestOrder.count != 0)
        {
            return TestOrder
        }
        TestOrder.removeAll(keepingCapacity: true)
        
        let mersenneTwister = GKMersenneTwisterRandomSource(seed: UInt64(testData.ParticipantId))
        let mandatoryTests: [(method: TypoCorrectionMethod, type: TypoCorrectionType, isWarmup: Bool)] = [
            (.SpacebarSwipe,        .Delete, false),
            (.TextFieldLongPress,   .Delete, false),
            (.TapFix,               .Delete, false),
            (.SpacebarSwipe,        .Replace, false),
            (.TextFieldLongPress,   .Replace, false),
            (.TapFix,               .Replace, false),
            (.SpacebarSwipe,        .Insert, false),
            (.TextFieldLongPress,   .Insert, false),
            (.TapFix,               .Insert, false),
            (.SpacebarSwipe,        .Swap, false),
            (.TextFieldLongPress,   .Swap, false),
            (.TapFix,               .Swap, false),
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
                TestOrder.append((test.method, test.type, true))
                methodsSeen[test.method] = true
            }
            TestOrder.append(test)
        }
        
        return TestOrder
    }
}
