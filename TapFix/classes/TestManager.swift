//
//  TestManager.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation
import GameplayKit
import CodableCSV

enum TestManagerState: String {
    case Pending = "Setup pending"
    case Ready = "Ready for testing"
    case Failure = "Initialization failed"
}

//@MainActor
class TestManager : ObservableObject {
    
    var documentsDirectory: URL
    var testDirectory: URL?
    var testData: TestData
    var testDataFileSet: Bool = false
    
    var infoFile: URL? { get {testDirectory?.appendingPathComponent("info.csv")} }
    var warmupResultsFile: URL? { get {testDirectory?.appendingPathComponent("warmup-results.csv")} }
    var testResultsFile: URL? { get {testDirectory?.appendingPathComponent("test-results.csv")} }
    let infoCsvEncoder: CSVEncoder;
    let warmupCsvEncoder: CSVEncoder
    let testCsvEncoder: CSVEncoder
    
    private let logger = buildWillowLogger(name: "TestManager")
    
    var ParticipantId: Int {
        get {
            testData.Information.ParticipantId
        }
        set(val) {
            objectWillChange.send() // notify view(s) of update
            testData.Information.ParticipantId = val
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
    
    @Published var TestOrder: [TestOrderInformation] = []
    @Published var State: TestManagerState = .Pending // always starts in SetupPending state
    @Published var StatusMessage: String = "Setup pending.."
    
    enum TestManagerError: Error {
        case invalidState(String)
        case runtimeError(String)
    }
    
    static let shared = TestManager()
    private init()
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)
        documentsDirectory = paths[0]
        testData = TestData()
        infoCsvEncoder = CSVEncoder { $0.headers = TestInformation.CodingKeys.allCases.map { $0.rawValue }}
        warmupCsvEncoder = CSVEncoder { $0.headers = TypingWarmupResult.CodingKeys.allCases.map { $0.rawValue }}
        testCsvEncoder = CSVEncoder { $0.headers = TypoCorrectionResult.CodingKeys.allCases.map { $0.rawValue }}
        logger.infoMessage("Initialized, documentsDirectory: \(self.documentsDirectory)")
    }
    
    func initFailed(reason: String = "No information provided.")
    {
        self.State = .Failure
        self.StatusMessage = "Failed to initialize TestManager! Reason: \(reason)"
        logger.errorMessage(self.StatusMessage)
    }
    
    func setUpForTesting()
    {
        guard self.State == .Pending else {
            logger.warnMessage("FIXME: setUpForTesting called, but current state is \(self.State.rawValue), doing nothing.")
            return
        }
        
        // Get current, formatted date and time
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyy"
        let formattedDate = dateFormatter.string(from: testData.Information.TimeStamp)
        dateFormatter.dateFormat = "hh-mm"
        let formattedTime = dateFormatter.string(from: testData.Information.TimeStamp)
        
        // Create folder for test data
        let testFolderName = "Test with participant \(testData.Information.ParticipantId) on \(formattedDate) at \(formattedTime)"
        testDirectory = documentsDirectory.appendingPathComponent(testFolderName)
        do {
            try FileManager.default.createDirectory(at: testDirectory!, withIntermediateDirectories: true)
        } catch let error {
            self.initFailed(reason: #"Could not create test results directory at "\#(testDirectory!)". Error: \#(error.localizedDescription)"#)
            return
        }
        logger.infoMessage("Initialized testDirectory as \(self.testDirectory!).")
        
        // Write information file
        do {
            let informationCsv = try infoCsvEncoder.encode([testData.Information])
            try informationCsv.write(to: infoFile!)
        } catch let error {
            self.initFailed(reason: "Could not write test information file. Error: \(error.localizedDescription)")
            return
        }
        logger.infoMessage("Wrote test information file. Ready to test.")
        
        self.State = .Ready
    }
    
    func getResultsJson() -> Data
    {
        return Data("{\"error\": \"JSON support removed!\"}".utf8)
    }
    
    func getTestIdentifier() -> String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "dd-MM-yyyy-hh-mm"
        let formattedDate = dateFormatter.string(from: testData.Information.TimeStamp)
        return "participant-\(self.ParticipantId)_on-\(formattedDate)"
    }
    
    private func writeCsvData(_ data: Codable, to path: URL?, with encoder: CSVEncoder, from source: String = #function) -> Bool
    {
        if self.State != .Ready {
            logger.warnMessage("Unexpected state (\(self.State.rawValue)), writing attempt is likely to fail!")
        }
        
        do {
            guard let path = path else {
                throw TestManagerError.runtimeError("Cannot write to nil path!")
            }
            let csvData = try encoder.encode(data)
            try csvData.write(to: path)
        } catch let error {
            logger.errorMessage("Error writing csv data for \(source): \(error.localizedDescription)")
            return false
        }
        return true
    }
    
    func addTypingWarmupResult(result: TypingWarmupResult)
    {
        // add to testdata
        testData.TypingWarmupResults.append(result)
        
        // write to file
        if writeCsvData(testData.TypingWarmupResults, to: warmupResultsFile, with: warmupCsvEncoder) {
            logger.debugMessage("Added TypingWarmupResult to testData and updated results file.")
        }
    }
    
    func addTypoCorrectionResult(result: TypoCorrectionResult)
    {
        // add to testdata
        testData.CorrectionResults.append(result)
        
        // write to file
        if writeCsvData(testData.CorrectionResults, to: testResultsFile, with: testCsvEncoder) {
            logger.debugMessage("Added TypoCorrectionResult to testData and updated results file.")
        }
    }
    
    
    @discardableResult
    func generateTestOrder(regenerate: Bool = false) -> [TestOrderInformation]
    {
        if(!regenerate && TestOrder.count != 0)
        {
            return TestOrder
        }
        TestOrder.removeAll(keepingCapacity: true)
        
        let mersenneTwister = GKMersenneTwisterRandomSource(seed: UInt64(testData.Information.ParticipantId))
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
