//
//  StudySetupView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2024-01-14.
//

import SwiftUI
import Combine

struct StudySetupView: View  {
    
    @ObservedObject var testManager = TestManager.shared
    @EnvironmentObject var viewController: ViewController;
    @State var regenerateTestOrder: Bool = true;
    
    let methodNameMap = [TypoCorrectionMethod.SpacebarSwipe: "Spacebar swipe", TypoCorrectionMethod.TextFieldLongPress: "Long press",
                         TypoCorrectionMethod.TapFix: "TapFix"]
    
    var body: some View {
        NavigationStack {
            Form {
                List {
                    Section (header: Text("User Settings")) {
                        NavigationLink()
                        {
                            NumberWheelPickerView(number: $testManager.ParticipantId,
                                                  range: 0...1000,
                                                  prompt: "Select the participant id:",
                                                  title: "Participant ID")
                            {
                                Section(header: Text("Additional Options")) {
                                    Toggle("Regenerate test order", isOn: $regenerateTestOrder)
                                }
                            }
                            .onDisappear(perform: {
                                if(regenerateTestOrder)
                                {
                                    testManager.generateTestOrder(regenerate: true)
                                }
                            })
                            
                        } label: {
                            Text("Participant ID")
                            Spacer()
                            Text("\(testManager.ParticipantId)")
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                    }
                    
                    Section (header: Text("Test Parts")) {
                        Toggle("Typing Test", isOn: !$testManager.SkipTypingTest)
                        Toggle("Correction Warmups", isOn: !$testManager.SkipWarmups)
                        Toggle("Correction Tests", isOn: .constant(true)).disabled(true)
                    }
                    
                    Section (header: Text("Test Options")) {
                        
                        // Typing Test Length
                        NavigationLink()
                        {
                            NumberWheelPickerView(number: $testManager.TypingTestLength, range: 0...50,
                              prompt: "Select the typing test length", title: "Typing Test Length")
                        } label: {
                            Text("Typing Test Length").layoutPriority(1)
                            Text("\(testManager.TypingTestLength)")
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }.disabled(testManager.SkipTypingTest)
                        
                        
                        // Correction Warmup Length
                        NavigationLink()
                        {
                            NumberWheelPickerView(number: $testManager.WarmupLength, range: 0...50,
                              prompt: "Select the correction warmup length", title: "Correction Warmup Length")
                        } label: {
                            Text("Correction Warmup Length").layoutPriority(1)
                            Text("\(testManager.WarmupLength)")
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }.disabled(testManager.SkipWarmups)
                        
                        // Correction Test Length
                        NavigationLink()
                        {
                            NumberWheelPickerView(number: $testManager.TestLength, range: 0...50,
                              prompt: "Select the correction test length", title: "Correction Test Length")
                        } label: {
                            Text("Correction Test Length").layoutPriority(1)
                            Text("\(testManager.TestLength)")
                                .foregroundStyle(.gray)
                                .frame(maxWidth: .infinity, alignment: .trailing)
                        }
                        
                        // Test Order
                        NavigationLink()
                        {
                            Form {
                                Section(header: Text("Test Order")) {
                                    List() {
                                        ForEach(0..<testManager.TestOrder.count, id: \.self) {
                                            index in
                                            HStack(spacing: 4) {
                                                let methodName = methodNameMap[testManager.TestOrder[index].method] ?? testManager.TestOrder[index].method.rawValue
                                                let correctionType = testManager.TestOrder[index].type.rawValue
                                                let warmup = testManager.TestOrder[index].isWarmup
                                                Text("\(correctionType):").bold()
                                                Text(methodName)
                                                if(warmup)
                                                {
                                                    Text("♨️")
                                                }
                                            }
                                        }
                                        .onMove { indexSet, offset in
                                            testManager.TestOrder.move(fromOffsets: indexSet, toOffset: offset)
                                        }
                                        .onDelete { indexSet in
                                            testManager.TestOrder.remove(atOffsets: indexSet)
                                        }
                                    }
                                }
                                Section(header: Text("Options"))
                                {
                                    Button("Restore initial order..")
                                    {
                                        testManager.generateTestOrder(regenerate: true)
                                    }
                                }
                            }
                            .onAppear(perform: {
                                testManager.generateTestOrder()
                            })
                            .navigationTitle("Modify Test Order")
                            .navigationBarTitleDisplayMode(.inline)
                            .toolbar { EditButton() }
                        } label: {
                            Text("Modify order..").foregroundStyle(.blue)
                        }
                    }
                    
                    Section {
                        Button("Done")
                        {
                            viewController.next();
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
            .navigationTitle("User Study Setup")
        }
    }
}

#Preview {
    StudySetupView()
}
