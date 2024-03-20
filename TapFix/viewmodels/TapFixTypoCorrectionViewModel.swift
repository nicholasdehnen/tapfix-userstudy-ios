//
//  TypoCorrectionViewModel.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-12.
//

import Foundation
import UIKit


class TapFixTypoCorrectionViewModel : TypoCorrectionViewModel
{
    @Published var tapFixWord: String;
    @Published var legalSelectionIndices: [Int]
    var tapFixRange: NSRange;
    
    internal init(id: Int, typoSentence: TypoSentenceProtocol, correctionType: TypoCorrectionType, completionHandler: @escaping (TypoCorrectionResult) -> Void, preview: Bool = false) {
        self.tapFixWord = "tapfix"
        self.tapFixRange = NSRange()
        self.legalSelectionIndices = typoSentence.typoWordIndex
        
        super.init(id: id, typoSentence: typoSentence, correctionMethod: .TapFix, correctionType: correctionType, completionHandler: completionHandler, preview: preview)
    }
    
    override func calculateStats() -> TaskStatistics {
        var superStats = super.calculateStats()
        
        switch(correctionType)
        {
        case .Insert:
            // TapFix quirk: if Insert, positioningTime is counted from Insertion on
            // -> This is because order is inverted, character is first inserted, then moved to the correct place
            superStats.insertionTime = beganSelecting.distance(to: finishedInserting)
            superStats.positioningTime = abs(finishedInserting.distance(to: finishedSelecting)) // abs due to floating point precision issuse when no positioning time (insert immediately fixes)
            superStats.correctionTime = finishedSelecting.distance(to: finishedEditing) // cascades to correctionTime
        case .Delete:
            superStats.insertionTime = 0
            break
        case .Replace:
            superStats.insertionTime = 0 // TapFix quirk: Insertion/Correction on Replace task is same
            break
        case .Swap:
            superStats.insertionTime = 0 // TapFix quirk: No insertion time at all
        }
        
        return superStats
    }
    
    override func shouldChangeCharacters(textField: PaddedTextField, range: NSRange, replacementString: String) -> Bool
    {
        logger.debugMessage("\(#function): range = \(range), replacementString = \(replacementString)")
        // no more editing once user fixed error
        if(self.testFinished)
        {
            logger.debugMessage("\(#function): false")
            return false;
        }
        
        // mark selection process as complete once user deletes character
        if(range.length == 1 && replacementString.isEmpty && typoSentence.typoSentenceIndex.contains(range.location)) {
            if(finishedCorrecting.timeIntervalSinceReferenceDate == 0)
            {
                finishedCorrecting = Date.now
            }
            if(correctionType == .Delete && finishedEditing.timeIntervalSinceReferenceDate == 0)
            {
                finishedEditing = Date.now
            }
            logger.debugMessage("\(#function): true")
            return true;
        }
        else if(!typoSentence.typoSentenceIndex.contains(range.location))
        {
            // don't allow user to replace any other character
            logger.debugMessage("\(#function): false")
            return false;
        }
        else
        {
            var newText = userText;
            newText.insert(replacementString.first!, at: userText.index(userText.startIndex, offsetBy: range.location));
            
            // compare corrected sentence against expected result
            if(newText == typoSentence.fullCorrect)
            {
                self.finishedEditing = Date.now;
                textField.text = newText;
            }
        }
        logger.debugMessage("\(#function): false")
        return false;
    }
    
    override func onBeganEditing(textField: PaddedTextField)
    {
        beganEditing.updateIfReferenceDate(logWith: logger, logAs: "beganEditing")
    }
    
    override func onTripleTapDetected(word: String, range: ClosedRange<Int>, began: Date, ended: Date)
    {
        if !self.editingAllowed || self.testFinished {
            logger.debugMessage("\(#function): Editing not allowed\(self.testFinished ? " anymore" : " yet"), returning.")
            if !self.testFinished {
                self.notifyUser(message: "Please take time to read the sentence before correcting it.")
            }
            return
        }
        
        let gestureDuration = began.distance(to: ended) // sanity check: triple tap really shouldnt be taking any longer than 3s (and that would be very slow!)
        if !began.isReferenceDate && gestureDuration < 3.0 {
            self.beganEditing = began
            logger.debugMessage("\(#function): Updating beganEditing with tripleTap began date, gesture duration: \(String(format: "%.4f", gestureDuration))s")
        }
        self.beganSelecting.updateIfReferenceDate(with: Date.now, logWith: logger, logAs: "beganSelecting")
        
        if word == typoSentence.typo {
            self.beganSelecting = Date.now
            self.tapFixWord = word
            self.methodActive = true
            logger.debugMessage("\(#function): methodActive = \(self.methodActive)")
        }
        else {
            // soft reset: user tried correcting wrong word
            beganEditing = self.refDate
            beganSelecting = self.refDate
            notifyUser(message: "This word does not need correction.")
        }
    }
    
    override func onChangedSelection(textField: PaddedTextField)
    {
        // Reject any selections for tapfix
        textField.selectedTextRange = nil
    }
    
    func handleInsertChange(_ oldText: String, _ newText: String) -> Bool {
        guard self.typoSentence is InsertTypoSentence else {
            self.flag(reason: "Insert task, but TypoSentence is not an Insert-type. This should never happen!",
                      userFriendlyReason: userFlagReasonInternalError)
            return true // flag and return true anyways, so continuation is possible
        }
        
        // check if insert change
        if newText.count != oldText.count + 1 {
            logger.debugMessage("\(#function): Non-insert change, allowing.")
            return true
        }
        
        // find inserted character
        // this could be made slightly more performant by combining this with indices()..
        let notFound = "?".first!
        var charInserted = newText[newText.count - 2] // rare edge case: eg. insert l into wel -> well
        for i in 0..<oldText.count
        {
            if oldText[i] != newText[i] {
                charInserted = newText[i]
                break
            }
        }
        
        guard charInserted != notFound else {
            super.flag(reason: "Insert task, but couldn't find new character. This should never happen!",
                       userFriendlyReason: userFlagReasonInternalError)
            return true // flag and return true anyways, so continuation is possible
        }
        
        let insertTypoSentence = self.typoSentence as! InsertTypoSentence
        logger.debugMessage("\(#function): charInserted = \(charInserted), characterToInsert = \(insertTypoSentence.characterToInsert)")
        if charInserted == insertTypoSentence.characterToInsert {
            self.finishedInserting.updateIfReferenceDate(logWith: logger, logAs: "finishedInserting")
            let newSelectionIndices = newText.indices(of: insertTypoSentence.characterToInsert)
            logger.debugMessage("\(#function): updating legalSelectionIndices (\(self.legalSelectionIndices) -> \(newSelectionIndices)), finishedInserting = \(self.finishedInserting)")
            self.legalSelectionIndices = newSelectionIndices
        }
        else
        {
            self.flag(reason: "Wrong character inserted (expected: \(insertTypoSentence.characterToInsert), got: \(charInserted))",
                      userFriendlyReason: "You inserted the wrong character. Try again.")
        }
        
        return true
    }
    
    func onTapFixUserFlag()
    {
        self.flag(reason: "Manual user flag.", userFriendlyReason: "You flagged this test.")
    }
    
    func onTapFixCharacterTouched(character: String, offset: Int) {
        // sanity check: make sure we dont reject or accept any touches too early (accidental quadruple-tap, etc.)
        let guardTime = 0.1
        if self.beganSelecting.distance(to: Date.now) < guardTime {
            logger.debugMessage("\(#function): Ignoring touch on character \(character), within safe-guard time.")
            return
        }
        
        // check if correct touch
        let isOffsetCorrect = self.legalSelectionIndices.contains(offset)
        if(isOffsetCorrect && finishedSelecting.timeIntervalSinceReferenceDate == 0)
        {
            finishedSelecting = Date.now
            logger.debugMessage("\(#function): finishedSelecting = \(self.finishedSelecting)")
        }
        else if(isOffsetCorrect) {
            logger.debugMessage("\(#function): correct offset (=\(offset)), but finishedSelecting already set (\(self.finishedSelecting))")
        }
        else {
            self.flag(reason: "Incorrect selection offset \(offset), should be any of \(self.legalSelectionIndices)",
                      userFriendlyReason: "You tried to correct the wrong character. Please try again.")
        }
    }
    
    func onTapFixChange(oldText: String, newText: String) -> Bool {
        if let stringRange = userText.range(of: oldText)
        {
            logger.debugMessage(#"\#(#function): oldText = \#(oldText), newText = \#(newText)"#)
            let now = Date.now
            var shouldChangeText = true
            var newString = userText
            newString.replaceSubrange(stringRange, with: newText)
            
            // check if insert task, if so, update correct index for user to touch when swapping
            if self.correctionType == .Insert {
                shouldChangeText = handleInsertChange(oldText, newText)
            }
            
            //check if user finished task
            logger.debugMessage("\(#function): newText = \(newText), correction = \(self.typoSentence.correction)")
            if(newText == self.typoSentence.correction)
            {
                self.finish(at: now)
                logger.debugMessage("\(#function): finishedEditing = \(self.finishedEditing), done = \(self.testFinished)")
            }
            if newText != self.typoSentence.correction && newText != oldText && [.Replace, .Swap].contains(self.correctionType) {
                self.flag(reason: "Erroneous user correction (\(oldText) -> \(newText)).",
                          userFriendlyReason: "You failed to correct the sentence. Please try again.")
            }
            
            //replace text
            if shouldChangeText {
                self.userText.replaceSubrange(stringRange, with: newText) // (a) in full sentence
                self.tapFixWord = newText // (b) in tapfix word
            }
            
            //close tapfix only if was replace, delete or swap and task is complete
            logger.debugMessage("\(#function): correctionType = \(self.correctionType), done = \(self.testFinished)")
        }
        else {
            logger.debugMessage("\(#function): oldText (\(oldText)) not found in userText (\(self.userText))!")
            return false
        }
        return true
    }
    
}
