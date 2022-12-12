//
//  TypoCorrectionWarmup.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct TypoCorrectionTestView: View {
    
    @EnvironmentObject var viewController: ViewController;
    @State private var navigationPath = NavigationPath();
    
    @State private var currentSentence: Int = 0;
    private let isWarmup: Bool;
    private let correctionCount: Int = 3;
    private var sentences: [TypoSentence];
    private let typoGenerator: TypoGenerator;
    private let correctionMethod: TypoCorrectionMethod;
    private let correctionType: TypoCorrectionType;
    private let correctionMethodExplanations: [TypoCorrectionMethod : String];
    
    init(correctionMethod: TypoCorrectionMethod, correctionType: TypoCorrectionType, warmup: Bool = false)
    {
        typoGenerator = TypoGenerator(sentences: SentenceManager.shared.getSentences(shuffle: true, randomSeed: UInt64(TestManager.shared.testData.ParticipantId)))
        sentences = typoGenerator.generateSentences(num: correctionCount, type: correctionType)
        self.correctionMethod = correctionMethod
        self.correctionType = correctionType
        self.isWarmup = warmup
        correctionMethodExplanations = [
            TypoCorrectionMethod.SpacebarSwipe: "Long press the space bar and move your finger horizontally to position the cursor behind the faulty letter.",
            TypoCorrectionMethod.TextFieldLongPress: "Long press on the text field and use the magnifying glass to position the cursor behind the faulty letter.",
            TypoCorrectionMethod.TapFix: "Double tap the faulty word and swipe up to delete a letter, or down to replace it."]
    }
    
    func handleTypoCorrectionComplete(result: TypoCorrectionResult)
    {
        currentSentence += 1;
        TestManager.shared.addTypoCorrectionResult(result: result)
        navigationPath.append(currentSentence)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Text("Typo Correction " + (isWarmup ? "Warmup" : "Test"))
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                List {
                    HStack {
                        Text("Task: ")
                            .fontWeight(.bold)
                        switch(correctionType)
                        {
                        case .Replace:
                            Text("Correct typos in sentence.")
                        case .Delete:
                            Text("Delete extra characters.")
                        }
                    }
                    HStack {
                        Text("Method: ")
                            .fontWeight(.bold)
                        switch(correctionMethod)
                        {
                        case .SpacebarSwipe:
                            Text("Swiping on space bar.")
                        case .TextFieldLongPress:
                            Text("Long press on text field.")
                        case .TapFix:
                            Text("Proposed TapFix method.")
                        }
                    }
                    Text("In the following screens, you'll be shown correction tasks of the following layout:")
                    VStack(alignment: .center) {
                        let example = typoGenerator.generateSentence(type: correctionType)
                        let viewModel = TypoCorrectionViewModel(id: 0, typoSentence: example, correctionMethod: TypoCorrectionMethod.SpacebarSwipe, correctionType: TypoCorrectionType.Replace, completionHandler: {_ in }, preview: true)
                        TypoCorrectionView(vm: viewModel)
                    }
                    Text("Your task is to correct the mistake in the given sentence using ")+Text("only").underline()+Text(" this method:")
                    Text(correctionMethodExplanations[correctionMethod]!)
                        .italic()
                    Text("Do this as fast and accurately as possible.")
                    Text("Time measurement will start the moment you touch the text field. Press the button below to continue.")
                }
                .padding(.horizontal)
                .listStyle(.plain)
                Button("Start " + (isWarmup ? "warm-up" : "testing") + "..") {
                    navigationPath.append(currentSentence)
                }
                .buttonStyle(.bordered)
            }
            .navigationDestination(for: Int.self) { i in
                VStack {
                    if(i < correctionCount)
                    {
                        ProgressView(value: Double(i) / Double(correctionCount)) {
                                Text("Sentence \(i+1) out of \(correctionCount)")
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        let viewModel = TypoCorrectionViewModel(id: i, typoSentence: sentences[i], correctionMethod: correctionMethod, correctionType: correctionType, completionHandler: handleTypoCorrectionComplete)
                        TypoCorrectionView(vm: viewModel)
                            .navigationBarBackButtonHidden(true)
                    }
                    else
                    {
                        VStack {
                            Spacer()
                            Text("Done!")
                                .font(.title)
                                .padding()
                            Text("The typo-correction " + (isWarmup ? "warm-up" : "test") + " is now complete.")
                            Button("Continue") {
                                viewController.next()
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                        .navigationBarBackButtonHidden(true)
                    }
                }
            }
        }
    }
}

struct TypoCorrectionWarmup_Previews: PreviewProvider {
    static var previews: some View {
        TypoCorrectionTestView(correctionMethod: TypoCorrectionMethod.SpacebarSwipe, correctionType: TypoCorrectionType.Delete)
    }
}
