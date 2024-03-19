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
    @State var testOrder: [TestOrderInformation] = []
    @State var currentTest: Int = 0
    
    @State private var typoCorrectionVmId: UUID = UUID()
    @State private var typoCorrectionViewModel: TypoCorrectionViewModel?
    
    #if DEBUG
    let isDebug = false
    let types: [TypoCorrectionType] = [.Delete, .Replace, .Insert, .Swap]
    @State var methodCounter = 0
    private func generateAndDisplayNewTypo() {
        let correctionMethod = TypoCorrectionMethod.TextFieldLongPress
        let correctionType = types[methodCounter % types.count]
        methodCounter += 1
        let typoGen = TypoGenerator(sentences: SentenceManager.shared.getSentences(shuffle: true))
        let typoSentence = typoGen.generateSentence(type: correctionType)
        
        let newViewModel = TapFixTools.buildTypoCorrectionViewModel(id: 0, typoSentence: typoSentence, correctionMethod: correctionMethod, correctionType: correctionType) { [self] _ in
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
    
    private func filterTestOrder() {
        testOrder = TestManager.shared.generateTestOrder()
        testOrder = testOrder.filter { $0.isWarmup == false && TestManager.shared.SkipWarmups
            || !TestManager.shared.SkipWarmups } // skip warmups depending on setting
    }
    
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
            else if TestManager.shared.State == .Failure {
                ErrorView(errorMessage: TestManager.shared.StatusMessage)
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
                            filterTestOrder() // no idea why this doesnt complain about updates from view thread, maybe cause its not our view
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
                            let viewModel = TypoCorrectionTestViewModel(correctionMethod: testCase.method, correctionType: testCase.type,
                                                                        isWarmup: testCase.isWarmup, onCompletion: {
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
