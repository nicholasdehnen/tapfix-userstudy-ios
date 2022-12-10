//
//  MainView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct MainView: View {
    
    @State var currentState: Int = 0;
    @StateObject var viewController = ViewController();
    
    var body: some View {
        switch(viewController.currentState)
        {
        case 0:
            ParticipantWelcomeView().environmentObject(viewController)
                .transition(.slide)
        case 1:
            TypingWarmupView()
                .environmentObject(viewController)
                .transition(.slide)
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
