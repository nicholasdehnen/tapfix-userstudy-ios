//
//  TypoCorrectionWarmup.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct TypoCorrectionTestView: View {
    
    @EnvironmentObject var viewController: ViewController;
    @State private var navigationPath = NavigationPath();
    @StateObject var vm: TypoCorrectionTestViewModel
    
    private let correctionMethodExplanations: [TypoCorrectionMethod : String] = [
        TypoCorrectionMethod.SpacebarSwipe: "Long press the space bar and move your finger horizontally to position the cursor behind the faulty letter.",
        TypoCorrectionMethod.TextFieldLongPress: "Long press on the text field and use the magnifying glass to position the cursor behind the faulty letter.",
        TypoCorrectionMethod.TapFix: "Double tap the faulty word and swipe up to delete a letter, or down to replace it."]
    
    func handleTypoCorrectionComplete(result: TypoCorrectionResult)
    {
        vm.currentSentence += 1;
        if(!vm.isWarmup)
        {
            TestManager.shared.addTypoCorrectionResult(result: result)
        }
        navigationPath.append(vm.currentSentence)
    }
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            VStack {
                Text("Typo Correction " + (vm.isWarmup ? "Warmup" : "Test"))
                    .font(.title)
                    .fontWeight(.bold)
                    .padding(.top)
                List {
                    HStack {
                        Text("Task: ")
                            .fontWeight(.bold)
                        switch(vm.correctionType)
                        {
                        case .Replace:
                            Text("Correct typos in sentence.")
                        case .Delete:
                            Text("Delete extra characters.")
                        }
                    }
                    HStack {
                        Text("Method: ")
                            .fontWeight(.bold)
                        switch(vm.correctionMethod)
                        {
                        case .SpacebarSwipe:
                            Text("Swiping on space bar.")
                        case .TextFieldLongPress:
                            Text("Long press on text field.")
                        case .TapFix:
                            Text("Proposed TapFix method.")
                        }
                    }
                    Text("In the following screens, you'll be shown correction tasks of the following layout:")
                    VStack(alignment: .center) {
                        let example = vm.sentences.last!
                        let viewModel = TypoCorrectionViewModel(id: 0, typoSentence: example, correctionMethod: TypoCorrectionMethod.SpacebarSwipe, correctionType: TypoCorrectionType.Replace, completionHandler: {_ in }, preview: true)
                        TypoCorrectionView(vm: viewModel)
                    }
                    Text("Your task is to correct the mistake in the given sentence using ")+Text("only").underline()+Text(" this method:")
                    Text(correctionMethodExplanations[vm.correctionMethod]!)
                        .italic()
                    Text("Do this as fast and accurately as possible.")
                    Text("Time measurement will start the moment you touch the text field. Press the button below to continue.")
                }
                .padding(.horizontal)
                .listStyle(.plain)
                Button("Start " + (vm.isWarmup ? "warm-up" : "testing") + "..") {
                    navigationPath.append(vm.currentSentence)
                }
                .buttonStyle(.bordered)
            }
            .navigationDestination(for: Int.self) { i in
                VStack {
                    if(i < vm.correctionCount)
                    {
                        ProgressView(value: Double(i) / Double(vm.correctionCount)) {
                            Text("Sentence \(i+1) out of \(vm.correctionCount)")
                        }
                        .padding(.horizontal)
                        .padding(.top)
                        let viewModel = TypoCorrectionViewModel(id: i, typoSentence: vm.sentences[i], correctionMethod: vm.correctionMethod, correctionType: vm.correctionType, completionHandler: handleTypoCorrectionComplete)
                        TypoCorrectionView(vm: viewModel)
                            .navigationBarBackButtonHidden(true)
                    }
                    else
                    {
                        VStack {
                            Spacer()
                            Text("Done!")
                                .font(.title)
                                .padding()
                            Text("The typo-correction " + (vm.isWarmup ? "warm-up" : "test") + " is now complete.")
                            Button("Continue") {
                                vm.completionHandler()
                                navigationPath = NavigationPath()
                            }
                            .buttonStyle(.bordered)
                            Spacer()
                        }
                        .navigationBarBackButtonHidden(true)
                    }
                }
            }
        }
    }
}

struct TypoCorrectionWarmup_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TypoCorrectionTestViewModel(correctionMethod: TypoCorrectionMethod.TapFix, correctionType: TypoCorrectionType.Delete, isWarmup: false)
        TypoCorrectionTestView(vm: viewModel)
    }
}
