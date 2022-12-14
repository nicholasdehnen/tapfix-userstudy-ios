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
    
    var body: some View {
        switch(viewController.currentState)
        {
        case 0:
            ParticipantWelcomeView().environmentObject(viewController)
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

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
