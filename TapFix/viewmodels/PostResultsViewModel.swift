//
//  PostResultsViewModel.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-13.
//

import Foundation
import Alamofire

class PostResultsViewModel : ObservableObject
{
    @Published var uploadComplete = false
    @Published var uploadError = false
    
    let preview: Bool
    
    init(preview: Bool = false)
    {
        self.preview = preview
    }

    func startUpload()
    {
        if(preview)
        {
            DispatchQueue.main.asyncAfter(deadline: .now() + .seconds(5), execute: {
                self.uploadComplete = true
            })
        }
        else
        {
            doUpload(id: TestManager.shared.getTestIdentifier(),
                     data: TestManager.shared.getResultsJson())
        }
    }
    
    private func doUpload(id: String, data: Data)
    {
        let endpoint = "https://api.jsonbin.io/v3/b"
        let accessKey = "$2b$10$Z8JpojnWBU9uZGJXT6SQkOZx3gbXH8GeTfTcl6k8TNsbwWg/0nOrm"
        let collectionId = "6398c503811f2b20b0877b8a"
        let binName = id
        
        let headers: HTTPHeaders = [
            "Content-Type": "application/json",
            "X-Access-Key": accessKey,
            "X-Bin-Name": binName,
            "X-Collection-Id": collectionId
        ]
        
        AF.upload(data, to: endpoint, headers: headers)
            .responseString { response in
                debugPrint(response)
                if let error = response.error
                {
                    self.uploadError = true
                    debugPrint("error occurred in post: \(error)")
                }
                else
                {
                    self.uploadComplete = true
                }
            }
    }
}
