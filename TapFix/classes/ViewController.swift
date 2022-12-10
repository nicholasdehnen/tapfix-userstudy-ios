//
//  ViewController.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation

class ViewController: ObservableObject {
    static let shared = ViewController()
    
    @Published var CurrentState: Int = 0;
    private init(){}
    
    public func next()
    {
        CurrentState += 1;
    }
    public func prev()
    {
        CurrentState -= 1;
    }
}
