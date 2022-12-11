//
//  TypoCorrectionWarmup.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct TypoCorrectionWarmup: View {
    
    @EnvironmentObject var viewController: ViewController;
    @State private var navigationPath = NavigationPath();
    
    @State private var currentSentence: Int = 0;
    private let warmupCount: Int = 3;
    private var sentences: [TypoSentence];
    private let typoGenerator: TypoGenerator;
    private let correctionMethod: Int;
    private let correctionMethodExplanations: [String];
    
    init(correctionMethod: Int = 0)
    {
        typoGenerator = TypoGenerator(sentences: SentenceManager.shared.getSentences(shuffle: true, randomSeed: UInt64(TestManager.shared.testData.ParticipantId)))
        sentences = typoGenerator.generateSentences(num: warmupCount)
        self.correctionMethod = correctionMethod
        correctionMethodExplanations = ["Long press the space bar and move your finger horizontally to position the cursor behind the faulty letter.", "Long press on the text field and use the magnifying glass to position the cursor behind the faulty letter.", "Double tap the faulty word and swipe up to delete a letter, or down to replace it."]
    }
    
    func handleTypoCorrectionComplete()
    {
        currentSentence += 1;
        navigationPath.append(currentSentence)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Text("Typo Correction Warmup")
                    .font(.title)
                    .fontWeight(.bold)
                    .padding()
                List {
                    Text("In the following screens, you'll be shown correction tasks of the following layout:")
                    VStack(alignment: .center) {
                        TypoCorrectionView(typoSentence: TypoSentence(Prefix: "the cat", Typo: "frll", Correction: "fell", Suffix: "in the water", Full: "the cat frll in the water"), completionHandler: {}, preview: true)
                    }
                    Text("Your task is to correct the mistake in the given sentence using ")+Text("only").underline()+Text(" this method:")
                    Text(correctionMethodExplanations[correctionMethod])
                        .italic()
                    Text("Do this as fast and accurately as possible.")
                    Text("Time measurement will start the moment you touch the text field. Press the button below to continue.")
                }
                .padding()
                .listStyle(.plain)
                Button("Start warm-up") {
                    navigationPath.append(currentSentence)
                }
                .buttonStyle(.bordered)
            }
            .navigationDestination(for: Int.self) { i in
                VStack {
                    if(i < warmupCount)
                    {
                        ProgressView(value: Double(i) / Double(warmupCount)) {
                                Text("Sentence \(i+1) out of \(warmupCount)")
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        TypoCorrectionView(typoSentence: sentences[i], completionHandler: handleTypoCorrectionComplete)
                            .navigationBarBackButtonHidden(true)
                    }
                    else
                    {
                        VStack {
                            Spacer()
                            Text("Done!")
                                .font(.title)
                            Text("The typo-correction warm-up is now complete.")
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
        TypoCorrectionWarmup()
    }
}
