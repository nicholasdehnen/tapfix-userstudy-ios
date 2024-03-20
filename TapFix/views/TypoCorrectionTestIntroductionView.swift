//
//  TypoCorrectionTestIntroductionView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2024-03-18.
//

import SwiftUI

struct TypoCorrectionTestIntroductionView: View {
    
    private let correctionTypeDescriptions: [TypoCorrectionType : String] = [
        .Replace: "Correct typos in sentence.",
        .Delete: "Delete extra characters.",
        .Insert: "Insert missing characters.",
        .Swap: "Correct swapped characters."
    ]
    
    private let correctionMethodDescriptions: [TypoCorrectionMethod : String] = [
        .SpacebarSwipe: "Hold & swipe on space bar.",
        .TextFieldLongPress: "Use text lens (magnifier).",
        .TapFix: "Proposed TapFix method."
    ]
        
    private let correctionMethodExplanations: [TypoCorrectionMethod : String] = [
        .SpacebarSwipe: "Long press the space bar and move your finger horizontally to position the cursor.",
        .TextFieldLongPress: "Long press on the text field and use the magnifying glass to position the cursor.",
        .TapFix: "Triple-tap a word to activate TapFix."
    ]
    
    private let tapFixMethodExplanations: [TypoCorrectionType : String] = [
        .Delete: "Then, swipe up on a letter to delete it.",
        .Insert: "Then, type a new letter to insert it and drag it to the correct position.",
        .Replace: "Then, swipe down on a letter and enter a new one to replace it.",
        .Swap: "Then, swap letters using drag-and-drop."
    ]
    
    @State var warmup: Bool
    @State var correctionType : TypoCorrectionType
    @State var correctionMethod : TypoCorrectionMethod
    @State var exampleTypoCorrectionVm: TypoCorrectionViewModel
    
    init(warmup: Bool, correctionType: TypoCorrectionType, correctionMethod: TypoCorrectionMethod, exampleSentence: TypoSentenceProtocol? = nil)
    {
        self.warmup = warmup
        self.correctionType = correctionType
        self.correctionMethod = correctionMethod
        
        var s = exampleSentence
        if s == nil {
            let sentences = SentenceManager.shared.getSentences(shuffle: true, randomSeed: Date.now.timeIntervalSinceReferenceDate.bitPattern)
            s = TypoGenerator(sentences: sentences).generateSentence(type: correctionType)
        }
        
        let exampleTypoCorrectionVm = TapFixTools.buildTypoCorrectionViewModel(id: 999, typoSentence: s!, correctionMethod: correctionMethod, correctionType: correctionType, completionHandler: {_ in }, preview: true)
        
        self.exampleTypoCorrectionVm = exampleTypoCorrectionVm
    }
    
    var body: some View {
        VStack {
            Text("Typo Correction " + (warmup ? "Warmup" : "Test"))
                .font(.title)
                .fontWeight(.bold)
                .padding(.top)
            List {
                HStack {
                    Text("Task: ")
                        .fontWeight(.bold)
                    Text(correctionTypeDescriptions[correctionType]!)
                }
                HStack {
                    Text("Method: ")
                        .fontWeight(.bold)
                    Text(correctionMethodDescriptions[correctionMethod]!)
                }
                Text("In the following screens, you'll be shown correction tasks of the following layout:")
                VStack(alignment: .center) {
                    TypoCorrectionView(vm: exampleTypoCorrectionVm)
                }
                Text("Your task is to correct the mistake in the given sentence using ")+Text("only").underline()+Text(" this method:")
                Text(correctionMethodExplanations[correctionMethod]! +
                     (correctionMethod == .TapFix ? " " + tapFixMethodExplanations[correctionType]! : ""))
                    .italic()
                Text("Do this as fast and accurately as possible.")
                Text("Time measurement will start the moment you touch the text field. Press the button below to continue.")
            }
            .padding(.horizontal)
            .listStyle(.plain)
        }
    }
}

#Preview {
    TypoCorrectionTestIntroductionView(warmup: false, correctionType: .Replace, correctionMethod: .TextFieldLongPress)
}
