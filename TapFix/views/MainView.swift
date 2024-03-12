//
//  MainView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct MainView: View {
    
    @State var testNavigationPath = NavigationPath()
    @StateObject var viewController = ViewController();
    @State var testOrder: [(method: TypoCorrectionMethod, type: TypoCorrectionType, isWarmup: Bool)] = []
    @State var currentTest: Int = 0
    
    @State private var typoCorrectionVmId: UUID = UUID()
    @State private var typoCorrectionViewModel: TypoCorrectionViewModel?
    
    #if DEBUG
    let isDebug = true
    private func generateAndDisplayNewTypo() {
        let correctionType = TypoCorrectionType.Swap
        let typoGen = TypoGenerator(sentences: SentenceManager.shared.getSentences(shuffle: true))
        let typoSentence = typoGen.generateSentence(type: correctionType)
        //InsertTypoSentence(prefix: "well", typo: "connectd", correction: "connected", suffix: "with people", full: "well connectd with people", fullCorrect: "well connected with people", typoWordIndex: [7], typoSentenceIndex: [5+7], characterToInsert: "e")
        
        let newViewModel = TypoCorrectionViewModel(id: 0, typoSentence: typoSentence, correctionMethod: TypoCorrectionMethod.TapFix, correctionType: correctionType) { [self] _ in
            self.generateAndDisplayNewTypo() // call self on complete to generate new vm and view
        }
        
        updateCorrectionVmWithTransition(with: newViewModel)
    }
    private func setupDebugMode() {
        if isDebug {
            generateAndDisplayNewTypo()
        }
    }
    #endif
    
    func updateCorrectionVmWithTransition(with newVM: TypoCorrectionViewModel) {
        withAnimation {
            self.typoCorrectionVmId = UUID()
            self.typoCorrectionViewModel = newVM
        }
    }
    
    var body: some View {
        Group {
            if isDebug, let vm = typoCorrectionViewModel {
                TypoCorrectionView(vm: vm)
                    .id(typoCorrectionVmId)
                    .transition(.asymmetric(
                        insertion: .move(edge: .trailing), // Enter from the right
                        removal: .move(edge: .leading) // Exit to the left
                    ))
            }
            else {
                switch(viewController.currentState)
                {
                case 0:
                    StudySetupView().environmentObject(viewController)
                        .transition(.slide)
                case 1:
                    IntroductionView()
                        .environmentObject(viewController)
                        .transition(.slide)
                        .onAppear {
                            // these have already been generated at this point, we're just getting them here
                            testOrder = TestManager.shared.generateTestOrder()
                        }
                case 2:
                    TypingWarmupView()
                        .environmentObject(viewController)
                        .transition(.slide)
                    
                case 3:
                    ForEach(testOrder.indices, id: \.self)
                    { index in
                        if(currentTest == index)
                        {
                            let testCase = testOrder[index]
                            let viewModel = TypoCorrectionTestViewModel(correctionMethod: testCase.method, correctionType: testCase
                                .type, isWarmup: testCase.isWarmup, onCompletion: {
                                    currentTest += 1
                                    if(currentTest == testOrder.count)
                                    {
                                        viewController.next()
                                    }
                                }
                            )
                            TypoCorrectionTestView(vm: viewModel)
                                .environmentObject(viewController)
                                .transition(.slide)
                        }
                    }
                case 4:
                    PostResultsView(vm: PostResultsViewModel())
                case -1:
                    ErrorView(errorMessage: viewController.lastError)
                default:
                    ErrorView(errorMessage: "No more views to show.")
                }
            }
        }
        #if DEBUG
        .onAppear {
            setupDebugMode()
        }
        #endif
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
