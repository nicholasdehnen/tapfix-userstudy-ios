//
//  MainView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct MainView: View {
    
    @State var currentState: Int = 0;
    
    var body: some View {
        
        ViewController.shared.$CurrentState.sink { newState in
            currentState = newState;
        }
        
        switch(ViewController.shared.CurrentState)
        {
        case 0:
            ParticipantWelcomeView()
                .transition(.slide)
        case 1:
            TypingWarmupView()
                .transition(.slide)
        default:
            ParticipantWelcomeView()
        }
    }
}

struct MainView_Previews: PreviewProvider {
    static var previews: some View {
        MainView()
    }
}
