//
//  TypoCorrectionWarmup.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct TypoCorrectionTestView: View {
    enum TypoCorrectionTestState: Equatable {
        case introduction
        case test(Int)
        case done
    }
    
    @State var currentState: TypoCorrectionTestState = .introduction
    @StateObject var vm: TypoCorrectionTestViewModel
    @State private var currentTestVmId: UUID = UUID()
    @State private var currentTestVm: TypoCorrectionViewModel?
    
    private let motivationalProgressMessages = ["You got this!", "Almost done!", "Not too long to go..", "We're getting there..", "Wow, that was fast!", "Thank you for participating :-)"]
    
    func buildTestViewModel(id: Int, onCompletion: @escaping () -> Void) -> TypoCorrectionViewModel {
        return TapFixTools.buildTypoCorrectionViewModel(id: id, typoSentence: vm.getSentence(id), correctionMethod: vm.correctionMethod, correctionType: vm.correctionType) { result in
            
            // Update test progress and store result
            vm.currentSentence += 1
            if !vm.isWarmup {
                TestManager.shared.addTypoCorrectionResult(result: result)
            }
            
            // Add additional correction if this was flagged
            vm.additionalCorrections += result.Flagged.intValue
            
            // Do any additional actions (see ViewBuilder below)
            onCompletion()
        }
    }
    
    var body: some View {
        VStack {
            if case .test(let testNumber) = currentState {
                ProgressView(value: Float(testNumber), total: Float(vm.totalCorrectionCount)) {
                    HStack {
                        Text("Trial \(testNumber) out of \(vm.correctionCount)")
                            .fontWeight(.thin)
                            .font(.footnote)
                        if vm.additionalCorrections > 0 {
                            Text("(+\(vm.additionalCorrections))")
                                .fontWeight(.thin)
                                .font(.footnote)
                                .foregroundStyle(.orange)
                        }
                        Spacer()
                        Text("\(vm.correctionMethod.description)-\(vm.correctionType)")
                        .fontWeight(.thin)
                        .font(.footnote)
                        .foregroundStyle(.gray)
                    }
                }
                .padding(.horizontal)
                .padding(.top)
            }
            
            // Dynamic content based on state
            contentForCurrentState()
        }
        .transition(.slide)
        .animation(.easeInOut, value: currentState)
    }
    
    @ViewBuilder
    private func contentForCurrentState() -> some View {
        switch currentState {
        case .introduction:
            VStack(alignment: .leading) {
                ProgressView(value: Float(vm.trialNumber), total: Float(vm.totalTrials)) {
                    HStack {
                        Text("\(vm.totalTrials-vm.trialNumber) tests remaining..")
                            .fontWeight(.thin)
                            .font(.footnote)
                        if vm.trialNumber > 0 {
                            Spacer()
                            Text(motivationalProgressMessages.randomElement()!)
                            .fontWeight(.thin)
                            .font(.footnote)
                        }
                    }
                }
                .progressViewStyle(.linear)
                .padding(.horizontal)
            
                TypoCorrectionTestIntroductionView(warmup: vm.isWarmup, correctionType: vm.correctionType, correctionMethod: vm.correctionMethod)
                
                HStack(alignment: .center){
                    Spacer()
                    Button("Start " + (vm.isWarmup ? "warm-up" : "testing") + "..") {
                        currentState = .test(1)
                    }
                    .buttonStyle(.bordered)
                    Spacer()
                }
            }
            
        case .test(let testNumber):
            let testVm = buildTestViewModel(id: testNumber) {
                if testNumber < vm.totalCorrectionCount {
                    currentState = .test(testNumber + 1)
                } else {
                    currentState = .done
                }
            }
            TypoCorrectionView(vm: testVm)
            
        case .done:
            VStack {
                Spacer()
                Text("Done!").font(.title).padding()
                Text("The typo-correction " + (vm.isWarmup ? "warm-up" : "test") + " is now complete.")
                Button("Continue") {
                    vm.completionHandler()
                }
                .buttonStyle(.bordered)
                Spacer()
            }
        }
    }
}

struct TypoCorrectionWarmup_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TypoCorrectionTestViewModel(correctionMethod: TypoCorrectionMethod.TextFieldLongPress, correctionType: TypoCorrectionType.Replace, isWarmup: false, trialNumber: 5, totalTrials: 18)
        TypoCorrectionTestView(vm: viewModel)
    }
}
