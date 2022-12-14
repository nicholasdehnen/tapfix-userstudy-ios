//
//  TypingWarmupView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct TypingWarmupView: View {
    
    @State private var sentences: [String] = ["Loading, please wait.."]
    @State private var sentenceNo: Int = -1
    @State private var text: String = ""
    @State private var ignoredString = ""
    @State private var previousText: String = ""
    @FocusState private var textFieldFocused: Bool
    @EnvironmentObject var viewController: ViewController;
    
    @State var startDate = Date(timeIntervalSinceReferenceDate: 0)
    
    func onTextFieldChange(_: String) {
        // record time
        if(startDate.timeIntervalSinceReferenceDate == 0)
        {
            startDate = Date.now
        }
        
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
        let result = TypingWarmupResult(Id: sentenceNo, CorrectSentence: sentences[sentenceNo], TypedSentence: text, TaskCompletionTime: timeTaken);
        TestManager.shared.addTypingWarmupResult(result: result);
        
        // clear text
        previousText = "";
        text = "";
        
        // advance
        sentenceNo += 1;
        textFieldFocused = true;
    }
    
    func proceed() {
        viewController.next();
    }
    
    
    var body: some View {
        VStack {
            if(sentenceNo < 0)
            {
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
                        Text(sentences.last ?? "the exam was too hard")
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
                        Text("Note: All input is final.\nYou will not be able to correct any mistakes.")
                            .font(.headline)
                    }
                    Divider()
                    VStack(alignment: .leading) {
                        Text("Time measurement will start the moment you touch the text field. Press the button below to continue.")
                    }
                }.padding()
                VStack(alignment: .center) {
                    Button("Start warm-up..") {
                        sentenceNo += 1
                    }
                    .buttonStyle(.bordered)
                }
            }
            else if(sentenceNo < TestManager.TypingTestLength){
                Text("Please copy the following sentence:")
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .padding(.bottom, 2.0)
                Text(sentences[sentenceNo])
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
                    .onChange(of: self.text, perform: onTextFieldChange)
                    .onSubmit(onTextFieldSubmit)
                    .focused($textFieldFocused)
            }
            else {
                Text("Thank you!")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                    .padding(.bottom, 1.0)
                Text("The typing warm-up is now complete.")
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .padding(.bottom, 25.0)
                Button("Proceed", action: proceed)
                    .buttonStyle(.bordered)
            }
        }
        .onAppear(perform: {
            sentences = SentenceManager.shared.getSentences()
        })
        .padding()
    }
}

struct TypingWarmup_Previews: PreviewProvider {
    static var previews: some View {
        TypingWarmupView()
    }
}
