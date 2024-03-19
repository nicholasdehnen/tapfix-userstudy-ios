//
//  TypoCorrectionWarmup.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct TypoCorrectionTestView: View {
    
    @EnvironmentObject var viewController: ViewController;
    @StateObject var vm: TypoCorrectionTestViewModel
    
    @State private var currentTestVmId: UUID = UUID()
    @State private var currentTestVm: TypoCorrectionViewModel?
    
    enum TypoCorrectionTestState: Equatable {
        case introduction
        case test(Int)
        case done
    }
    @State private var currentState: TypoCorrectionTestState = .introduction
    
    func buildTestViewModel(id: Int, onCompletion: @escaping () -> Void) -> TypoCorrectionViewModel {
        return TapFixTools.buildTypoCorrectionViewModel(id: id, typoSentence: vm.getSentence(id), correctionMethod: vm.correctionMethod, correctionType: vm.correctionType) { result in
            // Update test progress and store result
            vm.currentSentence += 1
            if !vm.isWarmup {
                TestManager.shared.addTypoCorrectionResult(result: result)
                vm.additionalCorrections += result.Flagged.intValue
            }
            // Do any additional actions (see ViewBuilder below)
            onCompletion()
        }
    }
    
    var body: some View {
        VStack {
            if case .test(let testNumber) = currentState {
                ProgressView(value: Float(testNumber), total: Float(vm.totalCorrectionCount)) {
                    HStack {
                        Text("Sentence \(testNumber) out of \(vm.correctionCount)")
                        if vm.additionalCorrections > 0 {
                            Text("(+\(vm.additionalCorrections))").fontWeight(.thin)
                        }
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
            TypoCorrectionTestIntroductionView(warmup: vm.isWarmup, correctionType: vm.correctionType, correctionMethod: vm.correctionMethod)
            Button("Start " + (vm.isWarmup ? "warm-up" : "testing") + "..") {
                currentState = .test(1)
            }
            .buttonStyle(.bordered)
            
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
        let viewModel = TypoCorrectionTestViewModel(correctionMethod: TypoCorrectionMethod.TapFix, correctionType: TypoCorrectionType.Insert, isWarmup: false)
        TypoCorrectionTestView(vm: viewModel)
    }
}
