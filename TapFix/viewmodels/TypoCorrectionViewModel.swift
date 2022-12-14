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
    @Published var typoSentence: TypoSentence;
    @Published var userText: String;
    
    @Published var beganEditing: Date;
    @Published var beganSelecting: Date;
    @Published var finishedRemovingFaulty: Date;
    @Published var finishedSelecting: Date;
    @Published var finishedEditing: Date;
    
    @Published var tapFixWord: String;
    @Published var tapFixVisible: Bool;
    var tapFixRange: NSRange;
    
    let completionHandler: (TypoCorrectionResult) -> Void;
    let preview: Bool;
    
    let taskId: Int;
    let correctionMethod: TypoCorrectionMethod;
    let correctionType: TypoCorrectionType;
    let refDate: Date;
    
    private var lastLegalTextRange: UITextRange?;
    private var typoPosition: Int = -1;
    private var typoDeletedSentence: String;
    
    internal init(id: Int, typoSentence: TypoSentence, correctionMethod: TypoCorrectionMethod, correctionType: TypoCorrectionType, completionHandler: @escaping (TypoCorrectionResult) -> Void, preview: Bool = false) {
        self.taskId = id
        self.correctionMethod = correctionMethod
        self.correctionType = correctionType
        
        self.textFieldIsFocused = false
        self.typoSentence = typoSentence
        self.userText = typoSentence.Full
        
        self.refDate = Date(timeIntervalSinceReferenceDate: 0)
        self.beganEditing = refDate
        self.beganSelecting = refDate
        self.finishedSelecting = refDate
        self.finishedRemovingFaulty = refDate
        self.finishedEditing = refDate
        
        self.completionHandler = completionHandler
        self.preview = preview
        
        self.tapFixWord = "tapfix"
        self.tapFixVisible = false
        self.tapFixRange = NSRange()
        
        self.typoDeletedSentence = typoSentence.Full
        self.typoPosition = calculateTypoIndex()
        self.typoDeletedSentence.remove(at: typoDeletedSentence.index(typoDeletedSentence.startIndex, offsetBy: typoPosition))
    }
    
    private func calculateTypoIndex(local: Bool = false) -> Int
    {
        var index = -1;
        var typoStr = local ? typoSentence.Typo : typoSentence.Full
        var correctStr = local ? typoSentence.Correction : typoSentence.FullCorrect
        for i in 0..<typoStr.count
        {
            let charA = typoStr[i];
            let charB = correctStr[i];
            
            if(charA != charB)
            {
                index = i;
                break;
            }
        }
        return index;
    }
    
    func calculateStatsAndFinish()
    {
        let result = TypoCorrectionResult(Id: self.taskId, CorrectionMethod: self.correctionMethod, CorrectionType: self.correctionType, FaultySentence: self.typoSentence.Full, UserCorrectedSentence: self.typoSentence.FullCorrect, TaskCompletionTime: beganEditing.distance(to: finishedEditing), CursorPositioningTime: beganEditing.distance(to: finishedSelecting), CharacterDeletionTime: beganEditing.distance(to: finishedRemovingFaulty))
        self.completionHandler(result);
        
        debugPrint("- task stats -")
        debugPrint("task completion time: " + (beganEditing.distance(to: finishedEditing)).description)
        debugPrint("selection time part: " + (beganEditing.distance(to: finishedSelecting)).description)
        debugPrint("character deletion part: " + (beganEditing.distance(to: finishedRemovingFaulty)).description)
    }
    
    func shouldReturn(textField: PaddedTextField) -> Bool
    {
        let key = textField.returnKeyType;
        if(key == UIReturnKeyType.next) {
            if(userText.compare(typoSentence.FullCorrect, options: .caseInsensitive) == .orderedSame)
            {
                self.calculateStatsAndFinish()
                return true;
            }
        }
        return false;
    }
    
    func shouldChangeCharacters(textField: PaddedTextField, range: NSRange, replacementString: String) -> Bool
    {
        // no more editing once user fixed error
        if(self.finishedEditing.timeIntervalSinceReferenceDate != 0)
        {
            return false;
        }
        
        // mark selection process as complete once user deletes character
        if(range.length == 1 && replacementString.isEmpty && range.location == typoPosition) {
            if(finishedRemovingFaulty.timeIntervalSinceReferenceDate == 0)
            {
                finishedRemovingFaulty = Date.now
            }
            if(correctionType == .Delete && finishedEditing.timeIntervalSinceReferenceDate == 0)
            {
                finishedEditing = Date.now
            }
            return true;
        }
        else if(range.location != typoPosition)
        {
            // don't allow user to replace any other character
            return false;
        }
        else
        {
            var newText = userText;
            newText.insert(replacementString.first!, at: userText.index(userText.startIndex, offsetBy: range.location));
            
            // compare corrected sentence against expected result
            if(newText == typoSentence.FullCorrect)
            {
                self.finishedEditing = Date.now;
                textField.text = newText;
            }
        }
        return false;
    }
    
    func onBeganEditing(textField: PaddedTextField)
    {
        // set beganEditing if not set
        if(beganEditing.timeIntervalSinceReferenceDate == 0)
        {
            beganEditing = Date.now;
        }
    }
    
    func onChangedSelection(textField: PaddedTextField)
    {
        if(self.beganEditing.timeIntervalSinceReferenceDate != 0 && self.beganSelecting.timeIntervalSinceReferenceDate == 0) {
            self.beganSelecting = Date.now
        }
        
        if(finishedEditing.timeIntervalSinceReferenceDate == 0 && userText.compare(typoSentence.Full) != .orderedSame
           && userText.compare(typoDeletedSentence) != .orderedSame)
        {
            // user made an error, reset the whole test
            textField.text = typoSentence.Full
            textFieldIsFocused = false
            self.beganEditing = refDate
            self.beganSelecting = refDate
            self.finishedRemovingFaulty = refDate
            self.finishedSelecting = refDate
            self.finishedEditing = refDate
        }
        
        if let selectedRange = textField.selectedTextRange {
            let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
            
            // set finishedSelecting once user moves cursor to correct position
            // note: this also sets finishedSelecting if user "overshoots"..
            // .. but this doesnt matter since the user has to move the cursor back to correct the text, thus overwriting it again (only if not finished editing yet)
            if(finishedEditing.timeIntervalSinceReferenceDate == 0
               && cursorPosition == (typoPosition + (correctionType == .Replace ? 0 : 1))) // add 1 to typo position if deletion task
            {
                finishedSelecting = Date.now
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
                        if(tapFixWord_ == typoSentence.Typo)
                        {
                            self.beganSelecting = Date.now
                            self.tapFixWord = tapFixWord_
                            self.tapFixVisible = true
                        }
                    }
                    textField.selectedTextRange = nil
                }
                else
                {
                    // return to last legal position
                    textField.selectedTextRange = lastLegalTextRange
                }
            } else {
                // store as last legal position
                lastLegalTextRange = selectedRange
            }
        }
    }
    
    func onTapFixCharacterTouched(character: String, offset: Int) {
        if(calculateTypoIndex(local: true) == offset && finishedSelecting.timeIntervalSinceReferenceDate == 0)
        {
            finishedSelecting = Date.now
        }
    }
    
    func onTapFixChange(oldText: String, newText: String) -> Bool {
        if let stringRange = userText.range(of: oldText)
        {
            let now = Date.now
            var newString = userText
            var deletionString = userText
            
            newString.replaceSubrange(stringRange, with: newText)
            deletionString.remove(at: userText.index(userText.startIndex, offsetBy: self.typoPosition))
            
            //check if user finished deleting character
            if(deletionString == newString)
            {
                self.finishedRemovingFaulty = now
            }
            
            //check if user finished task
            if(newText == self.typoSentence.Correction)
            {
                self.finishedRemovingFaulty = now
                self.finishedEditing = now
            }
            
            //replace text and close tapfix again
            self.userText.replaceSubrange(stringRange, with: newText)
            self.tapFixVisible = false //close tapfix again
        }
        return true
    }
}

// from: https://stackoverflow.com/a/38805072
extension UITextInput {
    var selectedRange: NSRange? {
        guard let range = selectedTextRange else { return nil }
        let location = offset(from: beginningOfDocument, to: range.start)
        let length = offset(from: range.start, to: range.end)
        return NSRange(location: location, length: length)
    }
}
