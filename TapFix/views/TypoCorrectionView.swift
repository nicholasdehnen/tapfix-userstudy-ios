//
//  TypoCorrectionView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-11.
//

import SwiftUI
import UIKitTextField

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

            UIKitTextField(
                config: .init {PaddedTextField()}
                    .configure { uiTextField in
                        uiTextField.padding = .init(top: 8, left: 8, bottom: 8, right: 8)
                    }
                    .value(text: $userText)
                    .keyboardType(.alphabet)
                    .returnKeyType(.next)
                    .autocapitalizationType(UITextAutocapitalizationType.none)
                    .autocorrectionType(.no)
                    .textAlignment(.center)
                    .shouldReturn(handler: { uiTextField in
                        if(uiTextField.returnKeyType == UIReturnKeyType.next) {
                            self.completionHandler()
                            return true
                        }
                        return false
                    })
                    .onChangedSelection(handler: { uiTextField in
                        print(uiTextField.selectedTextRange as Any) // do measurements here!!
                    })
                    .shouldChangeCharacters(handler: { uiTextField, range, replacementString in
                        print(uiTextField.text as Any) // and here!!
                        print(range)
                        print(replacementString)
                        return true
                    })
            )
            .disabled(preview)
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .padding()
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
