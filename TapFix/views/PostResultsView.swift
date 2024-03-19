//
//  PostResultsView.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-13.
//

import SwiftUI

struct PostResultsView: View {
    @ObservedObject var vm: PostResultsViewModel
    
    var body: some View {
        VStack {
            Spacer()
            Image(systemName: "heart.fill")
                .resizable()
                .frame(width: 115, height: 100)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.pink)
                .padding(.bottom, 30.0)
            Text("Thank you!")
                .font(.title)
                .padding(.bottom, 2.0)
            Text("The user study is now complete.")
                .font(.title2)
                .padding(.bottom)
            Spacer()
            
            if(!vm.uploadComplete && !vm.uploadError) {
                ProgressView()
                    .padding()
                Text("Your results are being saved, please wait..")
                    .padding(.bottom, 75.0)
            }
            else if(vm.uploadError)
            {
                Image(systemName: "x.circle")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.red)
                    .padding(.bottom, 5.0)
                Text("The results upload failed. Please contact the author and send the results files manually.")
                    .padding(.bottom, 75.0)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
            else
            {
                Image(systemName: "checkmark.circle")
                    .resizable()
                    .frame(width: 25, height: 25)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.green)
                    .padding(.bottom, 5.0)
                Text("Your results have been saved successfully, you may close the app now.")
                    .padding(.bottom, 75.0)
                    .padding(.horizontal)
                    .multilineTextAlignment(.center)
            }
        }
        .onAppear {
            //vm.startUpload()
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) { // invoke async so we dont make changes from view thread
                vm.uploadComplete = true
            }
        }
    }
}

struct PostResultsView_Previews: PreviewProvider {
    static var previews: some View {
        let viewModel = PostResultsViewModel(preview: true)
        PostResultsView(vm: viewModel)
    }
}
