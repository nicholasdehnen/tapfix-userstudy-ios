//
//  ParticipantWelcomeView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI
import Combine


struct ParticipantWelcomeView: View {
    
    @State private var participantId: String = "";
    @EnvironmentObject var viewController: ViewController;
    @FocusState var inputFocused;
    
    func proceed() {
        inputFocused = false;
        TestManager.shared.setParticipantId(id: Int(participantId) ?? 11111)
        viewController.next();
    }
    
    var body: some View {
        VStack{
            Text("Welcome")
                .font(.title)
                .padding(.top, 10.0)
                .padding(.bottom, 1.0)
            Text("Thank you for participating in the TapFix user study!")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding(.bottom, 5.0)
            TextField("Enter your participant id..", text: $participantId)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.numberPad)
                .focused($inputFocused)
                .onReceive(Just(participantId)) { newValue in
                    // filter out non-numbers
                    let filtered = newValue.filter { "0123456789".contains($0) }
                    if filtered != newValue {
                        participantId = filtered
                    }
                    
                    // limit length to ID_LENGTH_LIMIT
                    if newValue.count > TestManager.ParticipantIdLength {
                        participantId = String(participantId.prefix(TestManager.ParticipantIdLength))
                    };
                }
                .frame(width: 250)
                .padding()
                .multilineTextAlignment(/*@START_MENU_TOKEN@*/.center/*@END_MENU_TOKEN@*/)
                
                Button("Proceed", action: proceed)
                    .buttonStyle(.bordered)
                    .disabled(participantId.count != 5)
                    .opacity(participantId.count != 5 ? 0.0 : 100.0)
        }
        .padding()
    }
}

struct ParticipantWelcomeView_Previews: PreviewProvider {
    static var previews: some View {
        ParticipantWelcomeView()
    }
}
