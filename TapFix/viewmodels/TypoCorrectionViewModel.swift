//
//  TypoCorrectionViewModel.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-12.
//

import Foundation
import UIKit


class TypoCorrectionViewModel : ObservableObject
{
    @Published var textFieldIsFocused: Bool;
    @Published var typoSentence: TypoSentenceProtocol;
    @Published var userText: String;
    
    @Published var beganEditing: Date;
    @Published var beganSelecting: Date;
    @Published var finishedInserting: Date;
    @Published var finishedCorrecting: Date;
    @Published var finishedSelecting: Date;
    @Published var finishedEditing: Date;
    
    @Published var tapFixWord: String;
    @Published var tapFixVisible: Bool;
    @Published var legalSelectionIndices: [Int];
    @Published var testFlagged: Bool;
    @Published var testFlagReason: String;
    @Published var testFinished: Bool;
    
    @Published var forcedWaitTime: Int;
    @Published var editingAllowed: Bool;
    
    @Published var showNotificationToast: Bool;
    @Published var notificationToastMessage: String;
    
    var tapFixRange: NSRange;
    
    let completionHandler: (TypoCorrectionResult) -> Void;
    let preview: Bool;
    
    let taskId: Int;
    let correctionMethod: TypoCorrectionMethod;
    let correctionType: TypoCorrectionType;
    let refDate: Date;
    
    private let logger = buildWillowLogger(name: "TypoCorrectionVM")
    private var lastLegalTextRange: UITextRange?;
    private let userFlagReasonInternalError = "Sorry, an internal error occurred. Please try again."
    
    internal init(id: Int, typoSentence: TypoSentenceProtocol, correctionMethod: TypoCorrectionMethod, correctionType: TypoCorrectionType, completionHandler: @escaping (TypoCorrectionResult) -> Void, preview: Bool = false) {
        self.taskId = id
        self.correctionMethod = correctionMethod
        self.correctionType = correctionType
        
        self.textFieldIsFocused = false
        self.typoSentence = typoSentence
        self.userText = typoSentence.full
        
        self.refDate = Date(timeIntervalSinceReferenceDate: 0)
        self.beganEditing = refDate
        self.beganSelecting = refDate
        self.finishedSelecting = refDate
        self.finishedInserting = refDate
        self.finishedCorrecting = refDate
        self.finishedEditing = refDate
        
        self.completionHandler = completionHandler
        self.preview = preview
        
        self.tapFixWord = "tapfix"
        self.tapFixVisible = false
        self.tapFixRange = NSRange()
        self.legalSelectionIndices = typoSentence.typoWordIndex
        self.testFlagged = false
        self.testFinished = false
        self.testFlagReason = "Test not flagged."
        
        self.forcedWaitTime = TestManager.shared.UseForcedWaitTime ? (TestManager.shared.WaitTimesForCorrectionTypes[correctionType] ?? 0) : 0
        self.editingAllowed = !TestManager.shared.UseForcedWaitTime // true if not using forced wait time, otherwise set to true by timer later
        
        self.showNotificationToast = false
        self.notificationToastMessage = "No message."
    }
    
    
    func calculateStatsAndFinish()
    {
        let tct = beganEditing.distance(to: finishedEditing)
        let idp = beganEditing.distance(to: finishedInserting)
        var stp = beganEditing.distance(to: finishedSelecting)
        let cdp = finishedSelecting.distance(to: finishedCorrecting)

        // insert special case: selection is after inserting
        if self.typoSentence is InsertTypoSentence {
            stp = finishedInserting.distance(to: finishedSelecting)
        }
        
        let result = TypoCorrectionResult(Id: self.taskId, CorrectionMethod: self.correctionMethod, CorrectionType: self.correctionType, FaultySentence: self.typoSentence.full, UserCorrectedSentence: self.typoSentence.fullCorrect,
                                          TaskCompletionTime: tct, CursorPositioningTime: stp, CharacterDeletionTime: cdp, CharacterInsertionTime: idp, Flagged: self.testFlagged)
        self.completionHandler(result);
        
        let flagString = self.testFlagged ? "⚑ " : ""
        var statsInfoMessage = flagString + String(format: "Task statistics: taskCompletionTime = %.3fs, selectionTime = %.3fs, correctionTime = %.3fs", tct, stp, cdp)
        
        // insert special case
        if self.typoSentence is InsertTypoSentence {
            statsInfoMessage.append(String(format: ", insertTime = %.3fs", idp))
        }
        
        logger.infoMessage(statsInfoMessage)
    }
    
    func shouldReturn(textField: PaddedTextField) -> Bool
    {
        logger.debugMessage("\(#function): returnKeyType = \(textField.returnKeyType), userText = \(self.userText), typoSentence.FullCorrect = \(self.typoSentence.fullCorrect)")
        let key = textField.returnKeyType;
        if(key == UIReturnKeyType.next) {
            if(userText.compare(typoSentence.fullCorrect, options: .caseInsensitive) == .orderedSame)
            {
                self.calculateStatsAndFinish()
                return true;
            }
        }
        return false;
    }
    
    func shouldChangeCharacters(textField: PaddedTextField, range: NSRange, replacementString: String) -> Bool
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
    
    func onBeganEditing(textField: PaddedTextField)
    {
        logger.debugMessage("\(#function): beganEditing = \(self.beganEditing) (unset = \(self.beganEditing.timeIntervalSinceReferenceDate == 0))")
        // set beganEditing if not set
        if(beganEditing.timeIntervalSinceReferenceDate == 0)
        {
            beganEditing = Date.now;
        }
    }
    
    func onChangedSelection(textField: PaddedTextField)
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
            let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
            
            // set finishedSelecting once user moves cursor to correct position (only if not TapFix)
            // note: this also sets finishedSelecting if user "overshoots"..
            // .. but this doesnt matter since the user has to move the cursor back to correct the text, thus overwriting it again (only if not finished editing yet)
            if(finishedEditing.timeIntervalSinceReferenceDate == 0 && self.correctionMethod != .TapFix
               && (self.typoSentence.typoSentenceIndex.contains(cursorPosition - (correctionType == .Replace ? 0 : 1)))) // TODO: Legacy "add 1 if deletion task". What does this do?
            {
                finishedSelecting = Date.now
                logger.debugMessage("\(#function): finishedSelecting = \(self.finishedSelecting)")
            }
            
            // range selection only valid for tapfix (opens it), otherwise only allow cursor movement
            if(selectedRange.end != textField.position(from: selectedRange.start, offset: 0)) {
                if(self.correctionMethod == TypoCorrectionMethod.TapFix)
                {
                    // open tapfix
                    if let tapFixWord_ = textField.text(in: selectedRange)
                    {
                        // as part of user study, only open tapfix when correct selection is made
                        // (same behaviour as with deletion / selection on other methods)
                        if(tapFixWord_ == typoSentence.typo)
                        {
                            self.beganSelecting = Date.now
                            self.tapFixWord = tapFixWord_
                            self.tapFixVisible = true
                            logger.debugMessage("\(#function): tapFixVisible = \(self.tapFixVisible)")
                        }
                        else {
                            notifyUser(message: "This word does not need correction.")
                        }
                    }
                    textField.selectedTextRange = nil
                    logger.debugMessage("\(#function): cleared selected text range")
                }
                else
                {
                    // return to last legal position
                    textField.selectedTextRange = lastLegalTextRange
                    logger.debugMessage("\(#function): returned to last legal position")
                }
            } else {
                // store as last legal position
                lastLegalTextRange = selectedRange
            }
        }
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
    
    func notifyUser(message: String, duration: Double = 3.0) {
        logger.debugMessage(#"\(#function): Showing notification toast with message ""\#(message)""#)
        self.notificationToastMessage = message
        self.showNotificationToast = true
        
        // Hide the toast after a <duration> seconds
        DispatchQueue.main.asyncAfter(deadline: .now() + duration) {
            self.showNotificationToast = false
            self.notificationToastMessage = "No message."
        }
    }
    
    func flag(reason: String = "", userFriendlyReason: String? = nil) {
        logger.warnMessage("Test flagged.\(reason.isEmpty ? "" : " Reason: " + reason)")
        self.testFlagReason = userFriendlyReason != nil ? userFriendlyReason! : reason
        self.textFieldIsFocused = false
        self.testFlagged = true
        finish()
    }
    
    func finish(at now: Date = Date.now) {
        logger.infoMessage("Test \(self.taskId) finished.")
        if self.finishedSelecting == self.refDate { // case where insert immediately corrects sentence (midpoint)
            self.finishedSelecting = now
        }
        if self.finishedCorrecting  == self.refDate { // same as above
            self.finishedCorrecting = now
        }
        if self.finishedEditing == self.refDate { // in case it hasnt been set (what is finishedEditing used for anyways?)
            self.finishedEditing = now
        }
        self.testFinished = true
        self.tapFixVisible = false
    }
    
    func onTapFixUserFlag()
    {
        self.flag(reason: "Manual user flag.", userFriendlyReason: "You flagged this test.")
    }
    
    func indices(of character: Character, in string: String) -> [Int] {
        var indices = [Int]()
        for (index, eachCharacter) in string.enumerated() {
            if eachCharacter == character {
                indices.append(index)
            }
        }
        return indices
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
            self.flag(reason: "Insert task, but couldn't find new character. This should never happen!",
                      userFriendlyReason: userFlagReasonInternalError)
            return true // flag and return true anyways, so continuation is possible
        }
        
        let insertTypoSentence = self.typoSentence as! InsertTypoSentence
        logger.debugMessage("\(#function): charInserted = \(charInserted), characterToInsert = \(insertTypoSentence.characterToInsert)")
        if charInserted == insertTypoSentence.characterToInsert {
            self.finishedInserting = Date.now
            let newSelectionIndices = self.indices(of: insertTypoSentence.characterToInsert, in: newText)
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
