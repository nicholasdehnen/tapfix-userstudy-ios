//
//  TypoCorrectionView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-11.
//

import SwiftUI

struct TypoCorrectionView: View {
    
    @State public var Complete: Bool = false;
    @State var typoSentence: TypoSentence
    @State var userText: String
    
    let completionHandler: () -> Void;
    let preview: Bool;
    
    init(typoSentence: TypoSentence, completionHandler: @escaping () -> Void, preview: Bool = false)
    {
        self.typoSentence = typoSentence
        self.userText = typoSentence.Full
        self.completionHandler = completionHandler
        self.preview = preview
    }
    
    var body: some View {
        VStack {
            Spacer()
            Text("Correct the following sentence:")
                .font(.headline)
                .padding(.bottom, 3.0)
            HStack(alignment: .top) {
                Text(typoSentence.Prefix)
                VStack {
                    Text(typoSentence.Typo)
                        .foregroundColor(Color.red)
                        .underline()
                    Image(systemName: "arrow.down")
                }
                Text(typoSentence.Suffix)
            }
            HStack(alignment: .top) {
                Text(typoSentence.Prefix)
                Text(typoSentence.Correction)
                    .foregroundColor(Color.green)
                Text(typoSentence.Suffix)
            }
            TextField("Please wait..", text: $userText)
                .keyboardType(.alphabet)
                .disableAutocorrection(true)
                .textInputAutocapitalization(.never)
                .textFieldStyle(.roundedBorder)
                .multilineTextAlignment(.center)
                .padding()
                .onSubmit(self.completionHandler)
                .disabled(preview)
            Spacer()
        }
        .padding()
        .ignoresSafeArea(.keyboard, edges: .bottom)
    }
}

struct TypoCorrectionView_Previews: PreviewProvider {
    static var previews: some View {
        TypoCorrectionView(
        typoSentence: TypoSentence(Prefix: "this is", Typo: "iust", Correction: "just", Suffix: "a preview", Full: "this is iust a preview"),
        completionHandler: {}
        )
    }
}
