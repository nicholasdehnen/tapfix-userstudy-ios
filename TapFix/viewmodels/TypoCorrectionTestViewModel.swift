//
//  TypoCorrectionTestViewModel.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-13.
//

import Foundation

class TypoCorrectionTestViewModel: ObservableObject {
    
    @Published var correctionMethod: TypoCorrectionMethod
    @Published var correctionType: TypoCorrectionType
    @Published var isWarmup: Bool
    @Published var trialNumber: Int = 0
    @Published var totalTrials: Int = 0
    @Published var correctionCount: Int
    @Published var additionalCorrections: Int = 0 // increased by each flagged test
    @Published var currentSentence: Int = 0
    
    var totalCorrectionCount: Int { correctionCount + additionalCorrections }
    
    private let typoGenerator: TypoGenerator
    let completionHandler: () -> Void
    
    init(correctionMethod: TypoCorrectionMethod, correctionType: TypoCorrectionType, isWarmup: Bool = false,
         trialNumber: Int = 0, totalTrials: Int = 0,
         onCompletion: @escaping () -> Void = {})
    {
        self.correctionMethod = correctionMethod
        self.correctionType = correctionType
        self.isWarmup = isWarmup
        self.correctionCount = isWarmup ? TestManager.shared.WarmupLength : TestManager.shared.TestLength
        self.completionHandler = onCompletion
        self.trialNumber = trialNumber
        self.totalTrials = totalTrials
        typoGenerator = TypoGenerator(sentences: SentenceManager.shared.getSentences(
            shuffle: true,
            randomSeed: isWarmup ? UInt64.random(in: UInt64(pow(10.0, 5))..<UInt64.max) : UInt64(TestManager.shared.testData.Information.ParticipantId)))
    }
    
    func getSentence(_ i: Int) -> TypoSentenceProtocol
    {
        return typoGenerator.generateSentence(type: self.correctionType)
    }
}
