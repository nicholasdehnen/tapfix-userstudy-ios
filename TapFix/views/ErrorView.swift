//
//  ErrorView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import SwiftUI

struct ErrorView: View {
    
    @State var errorMessage: String;
    
    var body: some View {
        VStack {
            Image(systemName: "exclamationmark.triangle.fill")
                .resizable()
                .frame(width: 100, height: 100)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.white, Color.yellow)
            Text("An error occurred: ")
                .padding()
            TextEditor(text: $errorMessage)
                .multilineTextAlignment(.center)
                .padding(.bottom)
                .foregroundStyle(Color.gray)
                .frame(height: 150.0)
        }
        .padding()
    }
}

struct ErrorView_Previews: PreviewProvider {
    static var previews: some View {
        ErrorView(errorMessage: "Preview, no error!")
    }
}
