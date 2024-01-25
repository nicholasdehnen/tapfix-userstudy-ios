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
                GeometryReader { geometry in
                    
                    HStack (spacing: 8) {
                        ForEach(vm.tapFixCharacters, id: \.Id)
                        { c in
                            Text(c.Character)
                                .font(Font.system(size: 32.0, weight: .bold, design: .monospaced))
                                .offset(self.charProps[c.Id]?.drag ?? .zero)
                                .highPriorityGesture(
                                    DragGesture()
                                        .onChanged({ value in
                                            self.charProps[c.Id]?.opacity = (value.startLocation.y + value.location.y + 24.0) / 24.0
                                            let dragDir = detectDirection(value: value)
                                            
                                            // drag up/down -> delete/replace
                                            if dragDir == .up || dragDir == .down {
                                                self.charProps[c.Id]?.drag = CGSize(width: 0.0, height: value.translation.height)
                                            }
                                            
                                            // drag left/right -> swap
                                            else if dragDir == .left || dragDir == .right {
                                                self.charProps[c.Id]?.drag = CGSize(width: value.translation.width, height: 0.0)
                                            }
                                            
                                            vm.onCharacterTouched(id: c.Id)
                                        })
                                        .onEnded({value in
                                            self.charProps[c.Id]?.opacity = 100.0
                                            self.charProps[c.Id]?.drag = .zero
                                            
                                            let dragDir = detectDirection(value: value)
                                            var dragTarget = -1
                                            
                                            if dragDir == .left || dragDir == .right
                                            {
                                                dragTarget = calculateTargetIndex(for: c.Id, with: value, dir: dragDir)
                                            }
                                            
                                            vm.buttonDrag(direction: detectDirection(value: value), id: c.Id, dragTarget: dragTarget)
                                            
                                        })
                                )
                                .frame(minWidth: 10.0, idealWidth: 40.0, maxWidth: 64.0, minHeight: 40.0, idealHeight: 50.0, maxHeight: 50.0, alignment: .center)
                                .background {
                                    GeometryReader { geo in
                                        Color.clear
                                            .frame(width: geo.size.width, height: geo.size.height)
                                            .onAppear {
                                                vm.updateCharacterSize(id: c.Id, size: geo.size)
                                            }
                                            .onChange(of: vm.tapFixCharacters.count) {
                                                vm.updateCharacterSize(id: c.Id, size: geo.size)
                                            }
                                    }
                                    RoundedRectangle(cornerRadius: 5.0, style: RoundedCornerStyle.circular)
                                        .fill((vm.activeReplaceId == c.Id ?  Color.red : Color.blue)).opacity(0.25)
                                        .offset(self.charProps[c.Id]?.drag ?? .zero)
                                }
                                .opacity(self.charProps[c.Id]?.opacity ?? 100.0)
                                .onAppear(perform: {
                                    self.charProps[c.Id] = (.zero, 100.0)
                                })
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                }
                
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
    
    func calculateTargetIndex(for id: Int, with gesture: DragGesture.Value, dir: SwipeHVDirection) -> Int {
        let currentIndex = vm.tapFixCharacters.firstIndex(where: { $0.Id == id }) ?? 0
        
        // Calculate the target index based on the translation
        let charWidth = vm.characterSize.width + 8
        let distance = Int(gesture.translation.width / charWidth)
        var targetIndex = currentIndex + distance

        // Adjust the target index based on the current index
        targetIndex = min(max(0, targetIndex), vm.tapFixCharacters.count)

        return targetIndex
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
            return .right
        }
        if value.startLocation.x > value.location.x + 24 {
            return .left
        }
        
        return .none
    }
}

struct TapFixView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TapFixViewModel("tapfix")
        TapFixView(vm: viewModel)
    }
}
