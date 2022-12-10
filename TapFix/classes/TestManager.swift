//
//  TestManager.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation

class TestManager {
    
    var documentsDirectory: URL;
    var testDataFile: URL;
    var testData: TestData;
    var testDataFileSet: Bool = false;
    let jsonEncoder: JSONEncoder;
    
    static let shared = TestManager()
    private init()
    {
        let paths = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask);
        documentsDirectory = paths[0];
        testDataFile = documentsDirectory.appendingPathComponent("not-set.txt");
        testData = TestData();
        jsonEncoder = JSONEncoder();
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
            testDataFile = documentsDirectory.appendingPathComponent("p\(testData.ParticipantId)_d\(formattedDate).json");
            
            testDataFileSet = true;
        }
        
        do {
            let testDataJson = try jsonEncoder.encode(testData)
            try testDataJson.write(to: testDataFile)
        } catch let error {
            print(error.localizedDescription);
        }
    }
    
    func setParticipantId(id: Int)
    {
        testData.ParticipantId = id;
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
}
