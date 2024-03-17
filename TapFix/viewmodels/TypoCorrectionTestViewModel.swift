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
    @Published var correctionCount: Int
    @Published var sentences: [TypoSentenceProtocol] = []
    @Published var currentSentence: Int = 0
    
    @Published var additionalCorrections: Int = 0 //increased by each flagged test
    
    private let typoGenerator: TypoGenerator
    let completionHandler: () -> Void
    
    init(correctionMethod: TypoCorrectionMethod, correctionType: TypoCorrectionType, isWarmup: Bool = false,
         onCompletion: @escaping () -> Void = {})
    {
        self.correctionMethod = correctionMethod
        self.correctionType = correctionType
        self.isWarmup = isWarmup
        self.correctionCount = isWarmup ? TestManager.shared.WarmupLength : TestManager.shared.TestLength
        self.completionHandler = onCompletion
        typoGenerator = TypoGenerator(sentences: SentenceManager.shared.getSentences(
            shuffle: true,
            randomSeed: isWarmup ? UInt64.random(in: UInt64(pow(10.0, 5))..<UInt64.max) : UInt64(TestManager.shared.testData.Information.ParticipantId)))
        self.sentences = typoGenerator.generateSentences(num: self.correctionCount, type: self.correctionType)
    }
}
