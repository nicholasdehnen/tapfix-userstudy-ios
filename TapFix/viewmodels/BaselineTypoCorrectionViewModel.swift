//
//  TypoCorrectionViewModel.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-12.
//

import Foundation
import UIKit


class BaselineTypoCorrectionViewModel : TypoCorrectionViewModel
{
    private var lastLegalTextRange: UITextRange?;
    
    internal override init(id: Int, typoSentence: TypoSentenceProtocol, correctionMethod: TypoCorrectionMethod, correctionType: TypoCorrectionType, completionHandler: @escaping (TypoCorrectionResult) -> Void, preview: Bool = false) {
        
        guard correctionMethod != .TapFix else {
            fatalError("BaselineTypoCorrectionViewModel should not be used for TapFix method.")
        }
        
        super.init(id: id, typoSentence: typoSentence, correctionMethod: correctionMethod, correctionType: correctionType, completionHandler: completionHandler, preview: preview)
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
            return true // return true - delete is ok
        }
        else
        {
            guard replacementString.first != nil else {
                logger.errorMessage("Wanted to insert character at position \(range.location), but nothing to insert!")
                flag(reason: "User tried to insert nil character (maybe delete somewhere unexpected?)", userFriendlyReason: userFlagReasonInternalError)
                return false
            }
            var newText = userText;
            newText.insert(replacementString.first!, at: userText.index(userText.startIndex, offsetBy: range.location));
            textField.text = newText;
            
            // compare corrected sentence against expected result
            if(newText == typoSentence.fullCorrect)
            {
                self.finishedEditing = Date.now;
            }
            
            logger.debugMessage("\(#function): true") // TODO: Somehow jumps to end of line after inserting here??
            return false // return false here: we make the changes to the text, not the textfield
        }
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
        
        //if(finishedEditing.timeIntervalSinceReferenceDate == 0 && userText.compare(typoSentence.full) != .orderedSame)
        //{
        //    // user made an error, flag test
        //    flag(reason: "Unexpected text change: \(self.userText) != \(self.typoSentence.full)",
        //         userFriendlyReason: "The text was changed in an unexpected way. Please try again.")
        //    return
        //}
        
        if let selectedRange = textField.selectedTextRange {
            let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
            
            // set finishedSelecting once user moves cursor to correct position
            // note: this also sets finishedSelecting if user "overshoots"..
            // .. but this doesnt matter since the user has to move the cursor back to correct the text, thus overwriting it again (only if not finished editing yet)
            if(finishedEditing.timeIntervalSinceReferenceDate == 0
               && (self.typoSentence.typoSentenceIndex.contains(cursorPosition - (correctionType == .Replace ? 0 : 1))))
            {
                finishedSelecting = Date.now
                logger.debugMessage("\(#function): finishedSelecting = \(self.finishedSelecting)")
            }
            
            // range selection only valid for tapfix (opens it), otherwise only allow cursor movement
            if(selectedRange.end != textField.position(from: selectedRange.start, offset: 0)) {
                // return to last legal position
                textField.selectedTextRange = lastLegalTextRange
                logger.debugMessage("\(#function): returned to last legal position")
            } else {
                // store as last legal position
                lastLegalTextRange = selectedRange
            }
        }
    }
}
