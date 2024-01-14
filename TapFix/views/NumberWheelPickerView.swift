//
//  NumberWheelPickerView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2024-01-14.
//

import SwiftUI

struct NumberWheelPickerView<Content> : View where Content: View {
    
    @Environment(\.dismiss) var dismiss
    
    let number: Binding<Int>
    let range: ClosedRange<Int>
    let prompt: String
    let title: String
    let content: () -> Content
    
    init(number: Binding<Int>, range: ClosedRange<Int>, prompt: String, title: String, @ViewBuilder content: @escaping () -> Content) {
        self.number = number
        self.range = range
        self.prompt = prompt
        self.title = title
        self.content = content
    }
    
    init(number: Binding<Int>, range: ClosedRange<Int>, prompt: String, title: String) where Content == EmptyView {
        self.init(number: number, range: range, prompt: prompt, title: title, content: { EmptyView() })
    }
    
    var body: some View {
        Form {
            Section(header: Text(prompt)){
                Picker(title, selection: number) {
                    ForEach(range, id: \.self) { num in
                        Text("\(num)")
                    }
                }
                .pickerStyle(.wheel)
            }
            
            Section {
                Button("Done")
                {
                    dismiss()
                }
                .frame(maxWidth: .infinity)
            }
            
            content()
        }
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
        
        
    }
}

struct NumberWheelPickerView_Previews: PreviewProvider {
    static var previews: some View {
        @State var num: Int = 15
        NavigationStack {
            NumberWheelPickerView(number: $num, range: 0...30, prompt: "Pick a number", title: "Number Picker")
        }
    }
}
