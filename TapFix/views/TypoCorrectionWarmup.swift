//
//  TypoCorrectionWarmup.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct TypoCorrectionWarmup: View {

    @State var text: String = "i love my fiye cats";
    @State var sentenceStart: String = "i love my";
    @State var sentencePieceFaulty: String = "fiye";
    @State var sentencePieceCorrect: String = "five";
    @State var sentenceEnd: String = "cats";
    
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
            Spacer()
        }
        .padding()
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct TypoCorrectionWarmup_Previews: PreviewProvider {
    static var previews: some View {
        TypoCorrectionWarmup()
    }
}
