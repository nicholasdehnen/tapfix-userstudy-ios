//
//  TestData.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-10.
//

import Foundation
import GameplayKit

class SentenceManager {
    
    public static private(set) var Error = false
    public static private(set) var ErrorMessage = ""
    
    private var sentences = [String]()
    
    static let shared = SentenceManager()
    private init(){
        if let path = Bundle.main.path(forResource: "phrases2", ofType: "txt") {
          do {
              let sentencesString = try String(contentsOfFile: path, encoding: .utf8);
              sentences = sentencesString.components(separatedBy: .newlines).map{ $0.lowercased() }
          } catch let error {
              SentenceManager.Error = true;
              SentenceManager.ErrorMessage = error.localizedDescription;
              sentences = ["error loading sentences"]
          }
        }
    }
    
    func getSentences(shuffle: Bool = false, randomSeed: UInt64 = 0, maxSentenceLength: Int = 38) -> [String] {
        var sentences_ = sentences.filter {$0.count <= maxSentenceLength}
        
        if(shuffle) {
            let mersenneTwister = GKMersenneTwisterRandomSource(seed: randomSeed);
            sentences_ = mersenneTwister.arrayByShufflingObjects(in: sentences) as! [String];
        }
        
        return sentences_;
    }
}
