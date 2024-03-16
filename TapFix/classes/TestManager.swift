//
//  TestManager.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation
import GameplayKit
import CodableCSV


//@MainActor
class TestManager : ObservableObject {
    
    var documentsDirectory: URL;
    var testDataFile: URL;
    var testDataWarmupCsvFile: URL;
    var testDataTestsCsvFile: URL;
    var testIdentifier: String;
    var testData: TestData;
    var testDataFileSet: Bool = false;
    let jsonEncoder: JSONEncoder;
    //let csvEncoder: CSVEncoder;
    let warmupCsvEncoder: CSVEncoder;
    let testCsvEncoder: CSVEncoder;
    
    private let logger = buildWillowLogger(name: "TestManager")
    
    var ParticipantId: Int {
        get {
            testData.ParticipantId
        }
        set(val) {
            objectWillChange.send()
            testData.ParticipantId = val
            logger.infoMessage("Participant ID set to \(val)")
        }
    }
    
    @Published var TypingTestLength: Int = 20
    @Published var TestLength: Int = 25
    @Published var WarmupLength: Int = 10 // * 4 (replace, delete, insert, swap)
    
    @Published var SkipWarmups: Bool = false
    @Published var SkipTypingTest: Bool = false
    
    @Published var UseForcedWaitTime: Bool = true
    @Published var WaitTimesForCorrectionTypes: [TypoCorrectionType: Int] = [
        .Replace: 1,
        .Delete: 1,
        .Insert: 1,
        .Swap: 2
    ]
    
    @Published var TestOrder: [(method: TypoCorrectionMethod, type: TypoCorrectionType, isWarmup: Bool)] = []
    
    
    static let shared = TestManager()
    private init()
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        documentsDirectory = paths[0]
        testDataFile = documentsDirectory.appendingPathComponent("not-set.txt")
        testDataWarmupCsvFile = documentsDirectory.appendingPathComponent("not-set-warmup.csv")
        testDataTestsCsvFile = documentsDirectory.appendingPathComponent("not-set-tests.csv")
        testData = TestData()
        jsonEncoder = JSONEncoder()
        jsonEncoder.outputFormatting = .prettyPrinted
        warmupCsvEncoder = CSVEncoder { $0.headers = TypingWarmupResult.CodingKeys.allCases.map { $0.rawValue }}
        testCsvEncoder = CSVEncoder { $0.headers = TypoCorrectionResult.CodingKeys.allCases.map { $0.rawValue }}
        testIdentifier = "not-set"
        logger.debugMessage("Initialized, documentsDirectory: \(self.documentsDirectory)")
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
            testDataWarmupCsvFile = documentsDirectory.appendingPathComponent("\(testIdentifier)-warmup.csv");
            testDataTestsCsvFile = documentsDirectory.appendingPathComponent("\(testIdentifier)-tests.csv");
            
            testDataFileSet = true;
            logger.debugMessage("Test data file was not yet set, set to: \(self.testDataFile)")
        }
        
        // json
        do {
            let testDataJson = try jsonEncoder.encode(testData)
            try testDataJson.write(to: testDataFile)
        } catch let error {
            logger.errorMessage("Error writing test data json file: \(error.localizedDescription)")
        }
        
        // csv
        do {
            if testData.TypingWarmupResults.count != WarmupLength && !SkipWarmups { // warmup not done yet
                let warmupDataCsv = try warmupCsvEncoder.encode(testData.TypingWarmupResults)
                try warmupDataCsv.write(to: testDataWarmupCsvFile)
            }
            else {
                let testDataCsv = try testCsvEncoder.encode(testData.CorrectionResults)
                try testDataCsv.write(to: testDataTestsCsvFile)
            }
        } catch let error {
            logger.errorMessage("Error writing test data csv file: \(error.localizedDescription)")
        }
    }
    
    func getResultsJson() -> Data
    {
        do {
            let testDataJson = try jsonEncoder.encode(testData)
            return testDataJson
        } catch let error {
            debugPrint(error.localizedDescription);
            logger.errorMessage("Error encoding test data to json: \(error.localizedDescription)")
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
        logger.debugMessage("Added TypingWarmupResult to testData and updated results file.")
    }
    
    func addTypoCorrectionResult(result: TypoCorrectionResult)
    {
        testData.CorrectionResults.append(result);
        _updateResultsFile();
        logger.debugMessage("Added TypoCorrectionResult to testData and updated results file.")
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
            if methodsSeen[test.method]! == false || (test.method == .TapFix) {
                // prepend warmup, once for baseline methods, always for tapfix
                // editing for baseline is the same (cursor positioning), however changes depending on correction type for tapfix
                TestOrder.append((test.method, test.type, true))
                methodsSeen[test.method] = true
            }
            TestOrder.append(test)
        }
        
        return TestOrder
    }
}
