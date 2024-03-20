//
//  TypingWarmupView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct TypingWarmupView: View {
    
    enum WarmupViewState: Equatable {
        case introduction
        case warmup(Int)
        case done
    }
    
    @State private var sentences: [String] = ["Loading, please wait.."]
    @State private var sentenceNo: Int = 1
    @State private var testCount: Int = 0
    @State private var text: String = ""
    @State private var ignoredString = ""
    @State private var previousText: String = ""
    @State private var state: WarmupViewState = .introduction
    @FocusState private var textFieldFocused: Bool
    
    @State var onCompletion: () -> Void
    @State var startDate = Date.referenceDate
    
    private let logger = buildWillowLogger(name: "TypingWarmupView")
    
    func onTextFieldChange() {
        // record start time
        startDate.updateIfReferenceDate()
        
        // prevent deletion
        if text.count < previousText.count {
            self.text = previousText
        } else {
            self.previousText = self.text
        }
    }
    
    func onTextFieldSubmit()
    {
        // calculate time
        let timeTaken = startDate.distance(to: Date.now)
        
        // store results
        let result = TypingWarmupResult(Id: sentenceNo, CorrectSentence: sentences[sentenceNo], TypedSentence: text, TaskCompletionTime: timeTaken)
        TestManager.shared.addTypingWarmupResult(result: result)
        
        // log some stats
        logger.infoMessage("Completed sentence \(sentenceNo). Time taken: \(timeTaken)s. Expected: '\(sentences[sentenceNo])'. Typed: '\(text)'.")
        
        // clear text
        previousText = ""
        text = ""
                
        // advance
        if sentenceNo < testCount {
            sentenceNo += 1
            state = .warmup(sentenceNo)
            startDate = Date.referenceDate // reset start date (important!)
            textFieldFocused = true
        } else {
            state = .done
        }
    }
    
    var body: some View {
        ZStack {
            Color.clear
            VStack {
                Spacer()
                switch state {
                case .introduction:
                    warmupIntro()
                case .warmup(let num):
                    warmupTypingTest(sentence: sentences[num])
                case .done:
                    warmupThankYou()
                }
                Spacer()
            }
        }
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .onAppear {
            sentences = SentenceManager.shared.getSentences()
            testCount = TestManager.shared.TypingTestLength
        }
        .overlay {
            if case .warmup(let num) = state {
                VStack {
                    ProgressView(value: Float(num), total: Float(testCount)) {
                        Text("Sentence \(num) out of \(testCount)")
                            .fontWeight(.thin)
                            .font(.footnote)
                    }
                    .padding(.horizontal)
                    Spacer()
                }
            }
        }
        .transition(.slide)
        .animation(.easeInOut, value: state)
    }
    
    
    @ViewBuilder
    private func warmupIntro() -> some View {
        Text("Typing Warmup")
            .font(.title)
            .fontWeight(.bold)
            .padding(.top)
        VStack (alignment: .leading) {
            Text("In the following screens, you will be shown typing tasks of the following layout:")
            Divider()
            VStack {
                Text("Please copy the following sentence:")
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .padding(.bottom, 2.0)
                Text(sentences.randomElement() ?? "the exam was too hard")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                Image(systemName: "arrow.down").padding(.top, 1.0)
                TextField("Type here..", text: $ignoredString)
                    .disabled(true)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .padding()
            }.padding(.vertical)
            Divider()
            Text("Copy the sentences as fast and accurately as possible.")
                .padding(.vertical, 2.0)
            Divider()
            VStack(alignment: .leading) {
                Text("Note: All input is final. You will not be able to correct any mistakes.")
                    .font(.headline)
            }
            Divider()
            VStack(alignment: .leading) {
                Text("Time measurement will start the moment you touch the text field. Press the button below to continue.")
            }
        }.padding()
        VStack(alignment: .center) {
            Button("Start warm-up..") {
                if TestManager.shared.SkipTypingTest {
                    state = .done
                } else {
                    state = .warmup(1)
                }
            }
            .buttonStyle(.bordered)
        }
    }
    
    
    @ViewBuilder
    private func warmupTypingTest(sentence: String) -> some View {
        Text("Please copy the following sentence:")
            .frame(maxWidth: .infinity)
            .clipped()
            .padding(.bottom, 2.0)
        Text(sentence)
            .font(.headline)
            .frame(maxWidth: .infinity)
        Image(systemName: "arrow.down").padding(.top, 1.0)
        TextField("Type here..", text: $text)
            .keyboardType(.alphabet)
            .disableAutocorrection(true)
            .textInputAutocapitalization(.never)
            .textFieldStyle(.roundedBorder)
            .multilineTextAlignment(.center)
            .padding()
            .onChange(of: self.text, onTextFieldChange)
            .onSubmit(onTextFieldSubmit)
            .focused($textFieldFocused)
    }
    
    
    @ViewBuilder
    private func warmupThankYou() -> some View {
        Text("Thank you!")
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding(.bottom, 1.0)
        Text("The typing warm-up \(TestManager.shared.SkipTypingTest ? "was skipped." : "is now complete.")")
            .frame(maxWidth: .infinity)
            .clipped()
            .padding(.bottom, 25.0)
        Button("Proceed", action: onCompletion)
            .buttonStyle(.bordered)
    }
}

struct TypingWarmup_Previews: PreviewProvider {
    static var previews: some View {
        TypingWarmupView(onCompletion: { })
    }
}
