//
//  ViewController.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation

class ViewController: ObservableObject {
    @Published var currentState: Int = 99;
    @Published var lastError: String = "";
    
    init(){}
    
    public func next()
    {
        currentState += 1;
    }
    
    public func prev()
    {
        currentState -= 1;
    }
    
    public func error(errorMessage: String)
    {
        lastError = errorMessage;
        currentState = -1;
    }

}
