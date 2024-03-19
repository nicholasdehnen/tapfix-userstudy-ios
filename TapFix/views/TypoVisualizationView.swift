//
//  TypoVisualizationView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2024-03-18.
//

import SwiftUI

struct TypoVisualizationView: View {
    @State var sentence: TypoSentenceProtocol
    @State var type: TypoCorrectionType
    @State var detailed: Bool
    
    @State var maxLength: Int
    @State var topSentence: String
    @State var bottomSentence: String
    
    
    init(sentence: TypoSentenceProtocol, correctionType: TypoCorrectionType, detailed: Bool) {
        self.sentence = sentence
        self.type = correctionType
        self.detailed = detailed
        
        self.maxLength = max(sentence.full.count, sentence.fullCorrect.count)
        
        // add placeholder for characters to be deleted/inserted
        var topSentence = sentence.full
        var bottomSentence = sentence.fullCorrect
        if [.Insert, .Delete].contains(correctionType) {
            sentence.typoSentenceIndex.sorted().forEach({ i in
                if correctionType == .Insert {
                    topSentence.insert(" ", at: topSentence.index(topSentence.startIndex, offsetBy: i))
                }
                else if correctionType == .Delete {
                    bottomSentence.insert(" ", at: bottomSentence.index(bottomSentence.startIndex, offsetBy: i))
                }
            })
        }
        
        self.topSentence = topSentence
        self.bottomSentence = bottomSentence
    }
    
    var body: some View {
        VStack {
            if detailed && ![.Insert, .Delete].contains(type) {
                HStack(alignment: .top) {
                    HStack(spacing: 0) {
                        //ForEach(Array(sentence.full.enumerated()), id: \.offset) { i, c in
                        //    let isMistake = sentence.typoSentenceIndex.contains(i)
                        //    VStack(alignment: .center ,spacing: 0) {
                        //        Text(String(sentence.full[i]))
                        //            .foregroundStyle(isMistake ? .red : .primary)
                        //            .frame(height: 20)
                        //        Image(systemName: "arrow.down")
                        //            .resizable()
                        //            .imageScale(.small)
                        //            .frame(width: isMistake ? 6 : 0, height: 10)
                        //            .opacity(isMistake ? 1.0 : 0.0)
                        //        Text(String(sentence.fullCorrect[i]))
                        //            .foregroundStyle(isMistake ? .green : .primary)
                        //            .frame(height: 20)
                        //    }
                        //}
                        
                        ForEach(0..<maxLength, id: \.self) { i in
                            VStack(alignment: .center ,spacing: 0) {
                                let isMistake = sentence.typoSentenceIndex.contains(i)
                                
                                Text(String(topSentence[i]))
                                        .foregroundStyle(isMistake ? .red : .primary)
                                        .frame(height: 20, alignment: .top)
                                
                                Image(systemName: "arrow.down")
                                    .resizable()
                                    .imageScale(.small)
                                    .frame(width: isMistake ? 6 : 0, height: 15, alignment: .center)
                                    .opacity(isMistake ? 1.0 : 0.0)
                                
                                Text(String(bottomSentence[i]))
                                    .foregroundStyle(isMistake ? .green : .primary)
                                    .frame(height: 20, alignment: .bottom)
                            }
                        }
                    }
                }
            }
            else {
                HStack(alignment: .top) {
                    Text(sentence.prefix)
                    VStack {
                        Text(sentence.typo)
                            .foregroundColor(Color.red)
                            .underline()
                        Image(systemName: "arrow.down")
                    }
                    Text(sentence.suffix)
                }
                HStack(alignment: .top) {
                    Text(sentence.prefix)
                    Text(sentence.correction)
                        .foregroundColor(Color.green)
                    Text(sentence.suffix)
                }
            }
        }
    }
}

#Preview {
    let correctionType = TypoCorrectionType.Swap
    let typoGen = TypoGenerator(sentences: SentenceManager.shared.getSentences(shuffle: true))
    let typoSentence = typoGen.generateSentence(type: correctionType)
    return TypoVisualizationView(sentence: typoSentence, correctionType: correctionType, detailed: true)
}
