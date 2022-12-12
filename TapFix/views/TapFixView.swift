//
//  TapFixView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-12.
//

import SwiftUI
import UIKitTextField

struct TapFixView: View {
    
    @ObservedObject var vm: TapFixViewModel
    @State var charProps: [Int: (drag: CGSize, opacity: Double)] = [:]
    
    var body: some View {
        if(vm.tapFixActive)
        {
            VStack {
                HStack {
                    Spacer()
                    ForEach(vm.selectedWordCharacters, id: \.Id)
                    { c in
                        Button(c.Character, action: {})
                            .buttonStyle(.bordered)
                            .foregroundColor(.black)
                            .fontWeight(.bold)
                            .font(.title)
                            .tint(vm.activeReplaceId == c.Id ? .red : .blue)
                            .offset(self.charProps[c.Id]?.drag ?? .zero)
                            .highPriorityGesture(
                                DragGesture()
                                    .onChanged({ value in
                                        self.charProps[c.Id]?.opacity = (value.startLocation.y + value.location.y + 24.0) / 24.0
                                        self.charProps[c.Id]?.drag = CGSize(width: 0.0, height: value.translation.height)
                                    })
                                    .onEnded({value in
                                        vm.buttonDrag(direction: detectDirection(value: value), id: c.Id)
                                        self.charProps[c.Id]?.drag = .zero
                                    })
                            )
                            .opacity(self.charProps[c.Id]?.opacity ?? 100.0)
                            
                            .onAppear(perform: {
                                self.charProps[c.Id] = (.zero, 100.0)
                            })
                        Spacer()
                    }
                }
                .padding(.vertical)
                
                UIKitTextField(
                    config: .init()
                        .value(text: $vm.textInput)
                        .focused($vm.textInputFocused)
                        .keyboardType(.alphabet)
                        .returnKeyType(.next)
                        .autocapitalizationType(UITextAutocapitalizationType.none)
                        .autocorrectionType(.no)
                        .textAlignment(.center)
                        .shouldChangeCharacters(handler: vm.keyboardInput)
                )
                .tint(.clear)
            }
            .padding()
        }
    }
    
    /*
     SwipeHVDirection / detectDirection from: https://stackoverflow.com/a/61806129
     */
    func detectDirection(value: DragGesture.Value) -> SwipeHVDirection {
        if value.startLocation.y < value.location.y - 24 {
            return .down
        }
        if value.startLocation.y > value.location.y + 24 {
            return .up
        }
        if value.startLocation.x < value.location.x - 24 {
            return .left
        }
        if value.startLocation.x > value.location.x + 24 {
            return .right
        }
        
        return .none
    }
}

struct TapFixView_Previews: PreviewProvider {
    static var previews: some View {
        var viewModel = TapFixViewModel()
        TapFixView(vm: viewModel)
    }
}
