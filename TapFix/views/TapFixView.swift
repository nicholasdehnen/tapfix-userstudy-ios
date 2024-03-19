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
    @State var charProps: [Int: (drag: CGSize, opacity: Double, touched: Bool)] = [:]
    @State var stackSpacing: CGFloat
    @State var characterWidth: CGFloat
    
    init(_ viewModel: TapFixViewModel)
    {
        vm = viewModel
        stackSpacing = CGFloat(min(max(1, (13+8)-viewModel.tapFixCharacters.count), 8))
        characterWidth = CGFloat(0)
    }
    
    var body: some View {
        if(vm.tapFixActive)
        {
            VStack {
                GeometryReader { geometry in
                    HStack (spacing: TapFixTools.calculateSpacing(tapFixCharacterCount: vm.tapFixCharacters.count)) {
                        ForEach(vm.tapFixCharacters, id: \.Id)
                        { c in
                            Text(c.Character)
                                .font(Font.system(size: 32.0, weight: .bold, design: .monospaced))
                                .offset(self.charProps[c.Id]?.drag ?? .zero)
                                .highPriorityGesture(
                                    DragGesture(minimumDistance: 0.0) // minimumDistance: 0.0 -> allow for small movements
                                        .onChanged({ value in
                                            let dragDir = TapFixTools.detectDirection(value: value, guardOn: self.charProps[c.Id]?.touched ?? true)
                                            
                                            // drag up -> delete
                                            // allow when method allowed or already been dragged up (eg. mistake -> going down again)
                                            if vm.methodDeleteAllowed && (dragDir == .up || dragDir == .down && self.charProps[c.Id]!.drag.height > 0.0) {
                                                self.charProps[c.Id]?.opacity = (value.startLocation.y + value.location.y + 24.0) / 24.0
                                                self.charProps[c.Id]?.drag = CGSize(width: 0.0, height: value.translation.height)
                                            }
                                            
                                            // drag down -> replace
                                            // allow when method allowed or already been dragged down (eg. mistake -> going up again)
                                            else if vm.methodReplaceAllowed && (dragDir == .down || dragDir == .up && self.charProps[c.Id]!.drag.height < 0.0) {
                                                self.charProps[c.Id]?.drag = CGSize(width: 0.0, height: value.translation.height)
                                            }
                                            
                                            // drag left/right -> swap
                                            // allow when method allowed and dragging left or right
                                            else if vm.methodSwapAllowed && abs(value.translation.width) > 0 {
                                                self.charProps[c.Id]?.drag = CGSize(width: value.translation.width, height: 0.0)
                                            }
                                            
                                            // report as character touched only if it hasnt been yet
                                            if(!(self.charProps[c.Id]?.touched ?? false))
                                            {
                                                self.charProps[c.Id]?.touched = true
                                                vm.onCharacterTouchStart(id: c.Id)
                                            }
                                        })
                                        .onEnded({value in
                                            self.charProps[c.Id]?.opacity = 100.0
                                            self.charProps[c.Id]?.drag = .zero
                                            
                                            let dragDir = TapFixTools.detectDirection(value: value)
                                            var dragTarget = -1
                                            
                                            // use translation width for swap detection: more intuitive, allows diagonal drag
                                            if vm.methodSwapAllowed && abs(value.translation.width) > 0
                                            {
                                                dragTarget = TapFixTools.calculateTargetIndex(for: c.Id, with: value, dir: dragDir, characters: vm.tapFixCharacters, characterWidth: characterWidth, stackSpacing: stackSpacing)
                                            }
                                            
                                            vm.buttonDrag(direction: TapFixTools.detectDirection(value: value), id: c.Id, dragTarget: dragTarget)
                                            
                                            // un-touch character
                                            self.charProps[c.Id]?.touched = false
                                            vm.onCharacterTouchEnd(id: c.Id)
                                        })
                                )
                                .frame(minWidth: 17.0, idealWidth: 40.0, maxWidth: 64.0, minHeight: 40.0, idealHeight: 50.0, maxHeight: 50.0, alignment: .center)
                                .background {
                                    GeometryReader { geo in
                                        Color.clear
                                            .frame(width: geo.size.width, height: geo.size.height)
                                            .onAppear {
                                                characterWidth = geo.size.width
                                            }
                                            .onChange(of: vm.tapFixCharacters.count) {
                                                characterWidth = geo.size.width
                                                stackSpacing = TapFixTools.calculateSpacing(tapFixCharacterCount: vm.tapFixCharacters.count)
                                            }
                                    }
                                    RoundedRectangle(cornerRadius: 5.0, style: RoundedCornerStyle.circular)
                                        .fill((vm.activeReplaceId == c.Id ?  Color.red : Color.blue)).opacity(0.25)
                                        .offset(self.charProps[c.Id]?.drag ?? .zero)
                                }
                                .opacity(self.charProps[c.Id]?.opacity ?? 100.0)
                                .onAppear(perform: {
                                    self.charProps[c.Id] = (.zero, 100.0, false)
                                })
                        }
                    }
                    .frame(width: geometry.size.width, height: geometry.size.height, alignment: .center)
                }
                .overlay(
                    HStack {
                        Spacer()
                        Button(action: vm.userFlag){
                            Image(systemName: "questionmark.circle")
                                .foregroundColor(.yellow)
                                .font(.system(size: 32))
                                .padding()
                        }
                    },
                    alignment: .topTrailing // Aligns the overlay to the top trailing corner of the VStack
                )
                
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
}

struct TapFixView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = TapFixViewModel("tapfix") // Interdisciplinary (17 chars)
        TapFixView(viewModel)
    }
}
