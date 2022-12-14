//
//  TypoCorrectionView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-11.
//

import SwiftUI
import UIKitTextField

struct TypoCorrectionView: View {
    
    @StateObject var vm: TypoCorrectionViewModel;
    
    var body: some View {
        
        VStack {
            if(!vm.preview)
            {
                Spacer()
            }
            Text("Correct the following sentence:")
                .font(.headline)
                .padding(.bottom, 3.0)
            HStack(alignment: .top) {
                Text(vm.typoSentence.Prefix)
                VStack {
                    Text(vm.typoSentence.Typo)
                        .foregroundColor(Color.red)
                        .underline()
                    Image(systemName: "arrow.down")
                }
                Text(vm.typoSentence.Suffix)
            }
            HStack(alignment: .top) {
                Text(vm.typoSentence.Prefix)
                Text(vm.typoSentence.Correction)
                    .foregroundColor(Color.green)
                Text(vm.typoSentence.Suffix)
            }
            
            UIKitTextField(
                config: .init {PaddedTextField()}
                    .configure { uiTextField in
                        uiTextField.padding = .init(top: 8, left: 8, bottom: 8, right: 8)
                    }
                    .value(text: $vm.userText)
                    .focused($vm.textFieldIsFocused)
                    .keyboardType(.alphabet)
                    .returnKeyType(.next)
                    .autocapitalizationType(UITextAutocapitalizationType.none)
                    .autocorrectionType(.no)
                    .textAlignment(.center)
                    .shouldReturn(handler: vm.shouldReturn)
                    .onChangedSelection(handler: vm.onChangedSelection)
                    .shouldChangeCharacters(handler: vm.shouldChangeCharacters)
                    .onBeganEditing(handler: vm.onBeganEditing)
            )
            .disabled(vm.preview || vm.tapFixVisible ||
            (vm.correctionMethod == .TapFix && vm.finishedEditing.timeIntervalSinceReferenceDate != 0))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .padding(.all, vm.preview ? 0 : nil)
            
            if(vm.finishedEditing.timeIntervalSinceReferenceDate != 0)
            {
                Button("Proceed", action: vm.calculateStatsAndFinish)
                    .buttonStyle(.bordered)
            }
            
            if(!vm.preview)
            {
                Spacer()
            }
        }
        .padding()
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay(tapFixOverlay)
    }
    @ViewBuilder private var tapFixOverlay : some View {
        if vm.tapFixVisible {
            let tapFixVm = TapFixViewModel(vm.tapFixWord, vm.onTapFixChange, vm.onTapFixCharacterTouched)
            GeometryReader { geometry in
                TapFixView(vm: tapFixVm)
                    .background(
                        RoundedRectangle(cornerRadius: 5.0)
                            .fill(UITraitCollection.current.userInterfaceStyle == .dark ? Color.black :  Color.white)
                            .opacity(0.95)
                            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center))
                    .animation(.easeIn, value: vm.tapFixVisible == true)
                    .animation(.easeOut, value: vm.tapFixVisible == false)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
    }
}

struct TypoCorrectionView_Previews: PreviewProvider {
    static var previews: some View {
        let typoSentence = TypoSentence(Prefix: "this is", Typo: "iust", Correction: "just", Suffix: "a preview", Full: "this is iust a preview", FullCorrect: "this is just a preview")
        let viewModel = TypoCorrectionViewModel(id: 0, typoSentence: typoSentence, correctionMethod: TypoCorrectionMethod.TapFix, correctionType: TypoCorrectionType.Replace, completionHandler: {_ in })
        TypoCorrectionView(vm: viewModel)
    }
}
