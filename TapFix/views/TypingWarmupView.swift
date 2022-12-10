//
//  TypingWarmupView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct TypingWarmupView: View {
    
    private let SENTENCE_COUNT: Int = 2
    @State private var sentences: [String] = ["Loading, please wait.."]
    @State private var sentenceNo: Int = 0
    @State private var text: String = ""
    @State private var previousText: String = ""
    @FocusState private var textFieldFocused: Bool
    
    func onTextFieldChange_preventDeletion(_: String) {
        if text.count < previousText.count {
            self.text = previousText
        } else {
            self.previousText = self.text
        }
    }
    
    func onTextFieldSubmit()
    {
        // store results
        let result = TypingWarmupResult(Id: sentenceNo, CorrectSentence: sentences[sentenceNo], TypedSentence: text, TaskCompletionTime: Duration(secondsComponent: 0, attosecondsComponent: 0));
        TestManager.shared.addTypingWarmupResult(result: result);
        
        // clear text
        previousText = "";
        text = "";
        
        // advance
        sentenceNo += 1;
        textFieldFocused = true;
    }
    
    func proceed() {}
    
    var body: some View {
        VStack {
            if(sentenceNo < SENTENCE_COUNT){
                Text("Please copy the following sentence:")
                    .frame(maxWidth: .infinity)
                    .clipped()
                    .padding(.bottom, 2.0)
                Text(sentences[sentenceNo])
                    .font(.headline)
                    .frame(maxWidth: .infinity)
                TextField("Type here..", text: $text)
                    .disableAutocorrection(true)
                    .textInputAutocapitalization(.never)
                    .textFieldStyle(.roundedBorder)
                    .multilineTextAlignment(.center)
                    .padding()
                    .onChange(of: self.text, perform: onTextFieldChange_preventDeletion)
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
