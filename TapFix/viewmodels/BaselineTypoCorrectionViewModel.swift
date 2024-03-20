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
    var beganInserting: Date = Date.referenceDate
    
    private var lastLegalTextRange: UITextRange?
    private var swapDeletionCount: Int = 0
    
    internal override init(id: Int, typoSentence: TypoSentenceProtocol, correctionMethod: TypoCorrectionMethod, correctionType: TypoCorrectionType, completionHandler: @escaping (TypoCorrectionResult) -> Void, preview: Bool = false) {
        
        guard correctionMethod != .TapFix else {
            fatalError("BaselineTypoCorrectionViewModel should not be used for TapFix method.")
        }
        
        super.init(id: id, typoSentence: typoSentence, correctionMethod: correctionMethod, correctionType: correctionType, completionHandler: completionHandler, preview: preview)
    }
    
    // Adjusted typoSentenceIndex for baseline methods
    // Indicies need to be shifted by + 1, since cursor will be placed behind index to be corrected
    // Exception: Insert
    private var adjustedTypoSentenceIndex : [Int] {
        if self.correctionType == .Insert {
            return self.typoSentence.typoSentenceIndex
        } else {
            return self.typoSentence.typoSentenceIndex.map { $0 + 1 }
        }
    }
    
    override func calculateStats() -> TaskStatistics {
        var superStats = super.calculateStats()
        
        // Baseline methods: Insertion time heavily depends on correction type
        switch correctionType {
        case .Swap:
            // Distance from finishedCorrecting -> beganInserting -> finishedInserting
            superStats.insertionTime = finishedCorrecting.distance(to: finishedInserting) // Account for double-insert
            break
        case .Replace:
            superStats.insertionTime = finishedCorrecting.distance(to: finishedInserting) // Insert time starts from deletion of wrong character on
            break
        case .Delete:
            superStats.insertionTime = 0 // Delete has no insertion time (no inserts taking place)
            break
        case .Insert:
            //superStats.insertionTime = finishedSelecting.distance(to: finishedInserting) // Insert time starts from assuming correct insertion position
            superStats.correctionTime = 0 // Insert has no correction time (no deletes taking place)
            break
        }
        return superStats
    }
    
    override func shouldChangeCharacters(textField: PaddedTextField, range: NSRange, replacementString: String) -> Bool
    {
        let isDeleting = range.length == 1 && replacementString.isEmpty
        let isInserting = !isDeleting
        let isExpectedPosition = self.typoSentence.typoSentenceIndex.contains(range.location) // use non-adjusted version: fine for insert, and delete shifts cursor by -1 anyways
        
        // no more editing once user fixed error
        if self.testFinished || !finishedEditing.isReferenceDate {
            logger.debugMessage("\(#function): testFinished=\(self.testFinished), finishedEditing=\(self.finishedEditing)")
            return false
        }
        
        logger.debugMessage("\(#function): range = \(range), change = \(isDeleting ? "delete" : "insert")\(isInserting ? ", text = " + replacementString : "")")
        
        // For Replace, Delete: Mark correction process as complete once user deletes character(s)
        if isDeleting && isExpectedPosition && [.Replace, .Delete].contains(correctionType) {
            finishedCorrecting.updateIfReferenceDate(logWith: logger, logAs: "finishedCorrecting")
            if correctionType == .Delete { // Delete finishes here, Replace after Insert
                self.finish()
            }
            return true // return true - delete is ok
        }
        // For Swap, more logic is required (two separate deletes, may not be sequential, but assumed to be)
        // Non-sequential swap (eg. select-delete-insert x2) would be highly unoptimal, participants are instructed before tests to choose the fastest, error-free way to correct sentence
        else if isDeleting && isExpectedPosition && correctionType == .Swap {
            swapDeletionCount += 1
            if swapDeletionCount == 2 {
                finishedCorrecting.updateIfReferenceDate(logWith: logger, logAs: "finishedCorrecting")
            } else if swapDeletionCount > 2 {
                self.flag(reason: "More than 2 deletes in swap, non-error-free correction.",
                          userFriendlyReason: "An error-free correction should not require more than two deletions. Please try again.")
            }
            return true
        }
        else if isDeleting && !isExpectedPosition {
            flag(reason: "User tried deleting at unexpected (most likely wrong) position.",
                 userFriendlyReason: "You tried to delete a character at an unexpected position. Please try again.")
            return false
        }
        else
        {
            guard replacementString.first != nil else {
                flag(reason: "User tried to insert nil character (maybe delete somewhere unexpected?)", userFriendlyReason: userFlagReasonInternalError)
                return false
            }
            
            // Set beganInserting if unset: Swap using baseline requires 2 inserts!
            self.beganInserting.updateIfReferenceDate(logWith: logger, logAs: "beganInserting")
            
            var newText = userText
            newText.insert(replacementString.first!, at: userText.index(userText.startIndex, offsetBy: range.location))
            //textField.text = newText // this very likely makes it so the selection changes to the back, disabled for now. TODO: See if this causes any issues
            
            // compare corrected sentence against expected result
            if(newText == typoSentence.fullCorrect)
            {
                self.finish() // Test is done
            }
            
            return true // Return true, change is allowed. See above comments. OLD: return false here: we make the changes to the text, not the textfield
        }
    }
    
    override func onTextFieldTouched(_ touches: [UITouch])
    {
        self.beganEditing.updateIfReferenceDate(logWith: logger, logAs: "beganEditing")
    }
    
    override func onBeganEditing(textField: PaddedTextField)
    {
        self.beganEditing.updateIfReferenceDate(logWith: logger, logAs: "beganEditing")
    }
    
    override func onChangedSelection(textField: PaddedTextField)
    {
        let selectedRange = textField.selectedTextRange
        logger.debugMessage("\(#function): textField.selectedTextRange = \(selectedRange?.description ?? "<none>")")
        
        // Do not allow editing when (a) test just started and forcedWaitTime still running or (b) test finished
        if(!self.editingAllowed || self.testFinished)
        {
            logger.debugMessage("\(#function): Editing not allowed\(self.testFinished ? " anymore" : " yet"), returning.")
            textField.selectedTextRange = nil // undo selection and return
            if(!self.testFinished) {
                self.notifyUser(message: "Please take time to read the sentence before correcting it.")
            }
            return
        }
        
        // We're selecting! Set beganEditing and beganSelecting if not already set.
        let now = Date.now
        self.beganEditing.updateIfReferenceDate(with: now, logWith: logger, logAs: "beganEditing")
        self.beganSelecting.updateIfReferenceDate(with: now, logWith: logger, logAs: "beganSelecting")
        
        if let selectedRange = selectedRange {
            let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
            
            // Update finishedSelecting once user moves cursor to correct position
            // Note: This also sets finishedSelecting if user "overshoots", but it gets overwritten later so all is well
            // Also: Only update until we started inserting
            if beganInserting.isReferenceDate && self.adjustedTypoSentenceIndex.contains(cursorPosition) {
                finishedSelecting = Date.now
                logger.debugMessage {
                    let posIndex = self.adjustedTypoSentenceIndex.firstIndex(of: cursorPosition)!
                    return "\(#function): cursorPosition = \(cursorPosition) == typoSentenceIndex[\(posIndex)], finishedSelecting = \(self.finishedSelecting)"
                }
            }
            
            // range selection only valid for tapfix (opens it), otherwise only allow cursor movement
            if(selectedRange.end != textField.position(from: selectedRange.start, offset: 0)) {
                // return to last legal position
                textField.selectedTextRange = lastLegalTextRange
                logger.debugMessage("\(#function): Rejected range selection and returned to last legal cursor position")
            } else {
                // store as last legal position
                lastLegalTextRange = selectedRange
            }
        }
    }
}
