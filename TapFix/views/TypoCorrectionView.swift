//
//  TypoCorrectionView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-11.
//

import SwiftUI
import UIKitTextField
import Willow

struct TypoCorrectionView: View {
    
    @ObservedObject var vm: TypoCorrectionViewModel
    @State private var timerCountUp = 0
    
    // Timer to force user to read sentence and understand needed correction
    private let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    
    var body: some View {
        VStack {
            Text("Correct the following sentence:")
                .font(.headline)
                .padding(.bottom, 3.0)
            TypoVisualizationView(vm: self.vm)
            
            UIKitTextField(
                config: .init {PaddedTextFieldWithTouchCallbacks()}
                    .configure { uiTextField in
                        uiTextField.padding = .init(top: 8, left: 8, bottom: 8, right: 8)
                        //uiTextField.backgroundColor = .clear
                        
                        // expose uiTextField to VM for UIKit gesture recognition
                        // needs to be dispatched separately or apple gets angry
                        DispatchQueue.main.async { [self] in
                            vm.updateUiKitTextField(uiTextField)
                        }
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
            .disabled(!vm.editingAllowed || vm.preview || vm.methodActive ||
                      (vm.correctionMethod == .TapFix && vm.finishedEditing.timeIntervalSinceReferenceDate != 0))
            .overlay(
                RoundedRectangle(cornerRadius: 5)
                    .stroke(Color(.systemGray5), lineWidth: 1)
            )
            .background(vm.editingAllowed ? Color(.clear) : Color(.systemGray6))
            .padding(.all, vm.preview ? 0 : nil)
            
            if !vm.preview {
                Button(action: vm.completeTask)
                {
                    Text(vm.editingAllowed ? "Proceed" : "Please wait.. \(vm.forcedWaitTime-vm.timerTime)")
                        .onReceive(timer) { _ in
                            vm.timerTime += 1
                            if vm.timerTime >= vm.forcedWaitTime {
                                vm.editingAllowed = true
                                timer.upstream.connect().cancel()
                            }
                        }
                }
                .buttonStyle(.bordered)
                .disabled(!vm.editingAllowed || vm.finishedEditing.timeIntervalSinceReferenceDate == 0)
            }
            
            if vm.testFlagged {
                Text(vm.testFlagReason)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.red.opacity(0.8))
                    .foregroundColor(.white)
                    .cornerRadius(10)
                    .padding(.horizontal, 8)
                    .padding(.top, 16)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
                    .animation(.easeIn(duration: 1), value: vm.testFlagged)
            }
            
            if !vm.preview
            {
                Spacer()
            }
        }
        .padding()
        .padding(.top, vm.preview ? 0 : 200)
        .ignoresSafeArea(.keyboard, edges: .bottom)
        .overlay (
            HStack {
                Spacer()
                if !vm.preview && !vm.testFlagged && !vm.methodActive && vm.finishedEditing.isReferenceDate {
                    Button(action: {
                        DispatchQueue.main.async { // invoke async so we dont make changes from view thread
                            vm.flag(reason: "User flagged in TypoCorrectionView", userFriendlyReason: "You manually flagged this test.")
                        }}) {
                        Image(systemName: "questionmark.circle")
                            .foregroundColor(.yellow)
                            .font(.system(size: 32))
                            .padding()
                    }
                }
                if vm.testFlagged {
                    Image(systemName: "flag.fill")
                        .foregroundColor(Color(.systemRed))
                        .padding()
                }
                else if !vm.testFlagged && vm.finishedEditing.timeIntervalSinceReferenceDate != 0 {
                    Image(systemName: "checkmark.seal.fill")
                        .foregroundColor(Color(.systemGreen))
                        .padding()
                }
            },
            alignment: .topTrailing
        )
        .overlay(
            Group {
                if vm.showNotificationToast {
                    VStack {
                        Spacer()
                        toastView
                            .transition(.move(edge: .bottom).combined(with: .opacity))
                            .animation(.easeInOut, value: vm.showNotificationToast)
                    }
                }
                else {
                    EmptyView()
                }
            }
        )
        .overlay(tapFixOverlay)
    }
    
    @ViewBuilder private var tapFixOverlay : some View {
        if let vm = vm as? TapFixTypoCorrectionViewModel, vm.methodActive
        {
            let tapFixVm = TapFixViewModel(vm.tapFixWord, vm.onTapFixChange, vm.onTapFixCharacterTouched, vm.onTapFixUserFlag, [vm.correctionType])
            GeometryReader { geometry in
                TapFixView(tapFixVm)
                    .background(
                        RoundedRectangle(cornerRadius: 5.0)
                            .fill(UITraitCollection.current.userInterfaceStyle == .dark ? Color.black :  Color.white)
                            .opacity(0.95)
                            .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center))
                    .animation(.easeIn, value: vm.methodActive == true)
                    .animation(.easeOut, value: vm.methodActive == false)
                    .ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
    }
    
    @ViewBuilder private var toastView: some View {
        Text(vm.notificationToastMessage)
            .padding()
            .background(Color.yellow.opacity(0.8))
            .foregroundColor(.white)
            .cornerRadius(8)
            .padding(.bottom, 50)
    }
}

struct TypoCorrectionView_Previews: PreviewProvider {
    static var previews: some View {
        //let typoSentence = TypoSentence(Prefix: "this is", Typo: "iust", Correction: "just", Suffix: "a preview", Full: "this is iust a preview", FullCorrect: "this is just a preview")
        let correctionType = TypoCorrectionType.Swap
        let correctionMethod = TypoCorrectionMethod.TapFix
        let typoGen = TypoGenerator(sentences: SentenceManager.shared.getSentences(shuffle: true))
        let typoSentence = typoGen.generateSentence(type: correctionType)
        let viewModel = TapFixTools.buildTypoCorrectionViewModel(id: 0, typoSentence: typoSentence, correctionMethod: correctionMethod, correctionType: correctionType, completionHandler: {_ in })
        TypoCorrectionView(vm: viewModel)
    }
}
