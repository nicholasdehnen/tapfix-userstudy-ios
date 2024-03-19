//
//  TypoVisualizationView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2024-03-18.
//

import SwiftUI

struct TypoVisualizationView: View {
    @ObservedObject var vm: TypoCorrectionViewModel
    @State var detailed: Bool = true
    
    var body: some View {
        VStack {
            if detailed && ![.Insert, .Delete].contains(vm.correctionType) { // only works for same-length sentences
                HStack(alignment: .top) {
                    HStack(spacing: 0) {
                        ForEach(0..<vm.typoSentence.full.count, id: \.self) { i in
                            VStack(alignment: .center ,spacing: 0) {
                                let isMistake = vm.typoSentence.typoSentenceIndex.contains(i)
                                
                                Text(String(vm.typoSentence.full[i]))
                                        .foregroundStyle(isMistake ? .red : .primary)
                                        .frame(height: 20, alignment: .top)
                                
                                Image(systemName: "arrow.down")
                                    .resizable()
                                    .imageScale(.small)
                                    .frame(width: isMistake ? 6 : 0, height: 15, alignment: .center)
                                    .opacity(isMistake ? 1.0 : 0.0)
                                
                                Text(String(vm.typoSentence.fullCorrect[i]))
                                    .foregroundStyle(isMistake ? .green : .primary)
                                    .frame(height: 20, alignment: .bottom)
                            }
                        }
                    }
                }
            }
            else {
                HStack(alignment: .top) {
                    Text(vm.typoSentence.prefix)
                    VStack {
                        Text(vm.typoSentence.typo)
                            .foregroundColor(Color.red)
                            .underline()
                        Image(systemName: "arrow.down")
                    }
                    Text(vm.typoSentence.suffix)
                }
                HStack(alignment: .top) {
                    Text(vm.typoSentence.prefix)
                    Text(vm.typoSentence.correction)
                        .foregroundColor(Color.green)
                    Text(vm.typoSentence.suffix)
                }
            }
        }
    }
}

#Preview {
    let correctionType = TypoCorrectionType.Swap;
    let typoGen = TypoGenerator(sentences: SentenceManager.shared.getSentences(shuffle: true))
    let typoSentence = typoGen.generateSentence(type: correctionType)
    let viewModel = TapFixTools.buildTypoCorrectionViewModel(id: 0, typoSentence: typoSentence, correctionMethod: TypoCorrectionMethod.TapFix, correctionType: correctionType, completionHandler: {_ in })
    return TypoVisualizationView(vm: viewModel, detailed: true)
}
