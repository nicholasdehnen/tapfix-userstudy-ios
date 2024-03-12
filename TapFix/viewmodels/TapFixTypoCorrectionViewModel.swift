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
    @Published var legalSelectionIndices: [Int];
    var tapFixRange: NSRange;
    
    internal init(id: Int, typoSentence: TypoSentenceProtocol, correctionType: TypoCorrectionType, completionHandler: @escaping (TypoCorrectionResult) -> Void, preview: Bool = false) {
        self.tapFixWord = "tapfix"
        self.tapFixRange = NSRange()
        self.legalSelectionIndices = typoSentence.typoWordIndex
        
        super.init(id: id, typoSentence: typoSentence, correctionMethod: .TapFix, correctionType: correctionType, completionHandler: completionHandler, preview: preview)
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
        logger.debugMessage("\(#function): beganEditing = \(self.beganEditing) (unset = \(self.beganEditing.timeIntervalSinceReferenceDate == 0))")
        // set beganEditing if not set
        if(beganEditing.timeIntervalSinceReferenceDate == 0)
        {
            beganEditing = Date.now;
        }
    }
    
    override func onChangedSelection(textField: PaddedTextField)
    {
        logger.debugMessage("\(#function): textField.selectedTextRange = \(textField.selectedSwiftTextRange?.description ?? "<none>")")
        
        if(!self.editingAllowed || self.testFinished)
        {
            logger.debugMessage("\(#function): Editing not allowed\(self.testFinished ? " anymore" : " yet"), returning.")
            textField.selectedTextRange = nil // undo selection and return
            if(!self.testFinished) {
                self.notifyUser(message: "Please take time to read the sentence before correcting it.")
            }
            return
        }
        
        if(self.beganEditing.timeIntervalSinceReferenceDate == 0)
        {
            //corner case: began selecting without onBeganEditing called?
            self.beganEditing = Date.now
            logger.debugMessage("\(#function): beganEditing = \(self.beganEditing)")
        }
        
        if(self.beganEditing.timeIntervalSinceReferenceDate != 0 && self.beganSelecting.timeIntervalSinceReferenceDate == 0) {
            self.beganSelecting = Date.now
            logger.debugMessage("\(#function): beganSelecting = \(self.beganSelecting)")
        }
        
        if(finishedEditing.timeIntervalSinceReferenceDate == 0 && userText.compare(typoSentence.full) != .orderedSame)
        {
            // user made an error, flag test
            self.flag(reason: "Unexpected text change: \(self.userText) != \(self.typoSentence.full)",
                      userFriendlyReason: "The text was changed in an unexpected way. Please try again.")
            return
        }
        
        if let selectedRange = textField.selectedTextRange {
            if selectedRange.end != textField.position(from: selectedRange.start, offset: 0), let tapFixWord_ = textField.text(in: selectedRange) {
                // as part of user study, only open tapfix when correct selection is made
                // (same behaviour as with deletion / selection on other methods)
                if(tapFixWord_ == typoSentence.typo)
                {
                    self.beganSelecting = Date.now
                    self.tapFixWord = tapFixWord_
                    self.methodActive = true
                    logger.debugMessage("\(#function): methodActive = \(self.methodActive)")
                }
                else {
                    notifyUser(message: "This word does not need correction.")
                }
                textField.selectedTextRange = nil
            }
        }
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
            self.finishedInserting = Date.now
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
            
            // TODO: Check how finishedCorrecting was used, we might have lost some information here
            
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
