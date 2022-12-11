//
//  TypoCorrectionWarmup.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct TypoCorrectionWarmup: View {

    @EnvironmentObject var viewController: ViewController;
    
    @State var text: String = "i love my fiye cats";
    @State var sentenceStart: String = "i love my";
    @State var sentencePieceFaulty: String = "fiye";
    @State var sentencePieceCorrect: String = "five";
    @State var sentenceEnd: String = "cats";
    
    @State private var sentence: TypoSentence;
    private let typoGenerator: TypoGenerator;
    
    init()
    {
        typoGenerator = TypoGenerator(sentences: SentenceManager.shared.getSentences(shuffle: true, randomSeed: UInt64(TestManager.shared.testData.ParticipantId)))
        
        sentence = TypoSentence(Prefix: "please wait ", Typo: "loading", Correction: "loading", Suffix: "sentences..")
    }
    
    func nextSentence()
    {
        do {
            sentence = try typoGenerator.generateSentence()
        }
        catch let error {
            viewController.error(errorMessage: error.localizedDescription)
            return
        }
        
        self.sentenceStart = sentence.Prefix
        self.sentencePieceFaulty = sentence.Typo
        self.sentencePieceCorrect = sentence.Correction
        self.sentenceEnd = sentence.Suffix
        self.text = [sentenceStart, sentencePieceFaulty, sentenceEnd].joined(separator: " ").trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    func submit()
    {
        // get new sentence
        nextSentence()
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Correct the following sentence:")
                .font(.headline)
                .padding(.bottom, 3.0)
            HStack(alignment: .top) {
                Text(sentenceStart)
                VStack {
                    Text(sentencePieceFaulty)
                        .foregroundColor(Color.red)
                        .underline()
                    Image(systemName: "arrow.down")
                }
                Text(sentenceEnd)
            }
            HStack(alignment: .top) {
                Text(sentenceStart)
                Text(sentencePieceCorrect)
                    .foregroundColor(Color.green)
                Text(sentenceEnd)
            }
            TextField("Please wait..", text: $text)
                .keyboardType(.alphabet)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .padding()
                .onSubmit(submit)
            Spacer()
        }
        .padding()
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear(perform: nextSentence)
    }
}

struct TypoCorrectionWarmup_Previews: PreviewProvider {
    static var previews: some View {
        TypoCorrectionWarmup()
    }
}
