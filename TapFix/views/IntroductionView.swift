//
//  IntroductionView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-13.
//

import SwiftUI

struct IntroductionView: View {
    @EnvironmentObject var viewController: ViewController;
    @State private var desiredHeight: [CGFloat] = [0, 0]
    @State private var introText: [String?] = ["In the course of this study, you will complete a general typing speed warm-up, as well as six different typo correction tests.",
    "The tests will be administered in the following order:"]
    @State private var desiredHeightOutro: CGFloat = 0
    @State private var outroText: String? = "You will receive a detailed explanation of the method and type of task in a shorter warm-up preceding each task. Participation will take around 15 minutes in total."
    
    @State private var testOrder = TestManager.shared.generateTestOrder()
    
    let methodNameMap = [TypoCorrectionMethod.SpacebarSwipe: "Spacebar swipe", TypoCorrectionMethod.TextFieldLongPress: "Long press",
                         TypoCorrectionMethod.TapFix: "TapFix"]
    
    var body: some View {
        VStack {
            Text("Introduction")
                .font(.title)
                .fontWeight(.bold)
                .padding(.top, 1.0)
            Text("Welcome to the TapFix user study.")
                .font(.headline)
                .multilineTextAlignment(.center)
                .padding()
            ForEach(0..<introText.count, id: \.self) { index in
                Divider()
                TextView(text: $introText[index], desiredHeight: $desiredHeight[index])
                    .frame(height: desiredHeight[index])
            }
            Divider()
            VStack (alignment: .leading){
                let bullet = "    •  "
                Text("\(bullet)Typing warm-up")
                ForEach(0..<testOrder.count, id: \.self) { index in
                    if(!testOrder[index].isWarmup)
                    {
                        Text("\(bullet)\(methodNameMap[testOrder[index].method] ?? testOrder[index].method.rawValue) corrections (\(testOrder[index].type.rawValue))")
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            Divider()
            TextView(text: $outroText, desiredHeight: $desiredHeightOutro)
                .frame(height: desiredHeightOutro)
            Divider()
            Button("Proceed", action: {
                
                viewController.next()
            })
                .buttonStyle(.borderedProminent)
                .padding()
        }
        .padding()
    }
}

struct IntroductionView_Previews: PreviewProvider {
    static var previews: some View {
        IntroductionView()
    }
}
