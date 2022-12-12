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
    
    let completionHandler: (TypoCorrectionResult) -> Void;
    let preview: Bool;
    
    let taskId: Int;
    let correctionMethod: TypoCorrectionMethod;
    let correctionType: TypoCorrectionType;
    
    private var lastLegalTextRange: UITextRange?;
    private var typoPosition: Int = -1;
    
    internal init(id: Int, typoSentence: TypoSentence, correctionMethod: TypoCorrectionMethod, correctionType: TypoCorrectionType, completionHandler: @escaping (TypoCorrectionResult) -> Void, preview: Bool = false) {
        self.taskId = id
        self.correctionMethod = correctionMethod
        self.correctionType = correctionType
        
        self.textFieldIsFocused = false
        self.typoSentence = typoSentence
        self.userText = typoSentence.Full
        
        let refDate = Date(timeIntervalSinceReferenceDate: 0)
        self.beganEditing = refDate
        self.beganSelecting = refDate
        self.finishedSelecting = refDate
        self.finishedRemovingFaulty = refDate
        self.finishedEditing = refDate
        
        self.completionHandler = completionHandler
        self.preview = preview
        
        self.typoPosition = calculateTypoIndex()
    }
    
    private func calculateTypoIndex() -> Int
    {
        var index = -1;
        for i in 0..<typoSentence.Full.count
        {
            let charA = typoSentence.Full[i];
            let charB = typoSentence.FullCorrect[i];
            
            if(charA != charB)
            {
                index = i;
                break;
            }
        }
        return index;
    }
    
    private func calculateStatsAndFinish()
    {
        let result = TypoCorrectionResult(Id: self.taskId, CorrectionMethod: self.correctionMethod, CorrectionType: self.correctionType, FaultySentence: self.typoSentence.Full, UserCorrectedSentence: self.typoSentence.FullCorrect, TaskCompletionTime: beganEditing.distance(to: finishedEditing), CursorPositioningTime: beganEditing.distance(to: finishedSelecting), CharacterDeletionTime: beganEditing.distance(to: finishedRemovingFaulty))
        self.completionHandler(result);
        
        print("- task stats -")
        print("task completion time: " + (beganEditing.distance(to: finishedEditing)).description)
        print("selection time part: " + (beganEditing.distance(to: finishedSelecting)).description)
        print("character deletion part: " + (beganEditing.distance(to: finishedRemovingFaulty)).description)
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
        }
        else if(range.length == 1 && replacementString.isEmpty && range.location != typoPosition)
        {
            // don't allow user to replace any other character
            return false;
        }
        else if(!replacementString.isEmpty)
        {
            // user fixed error, set finishedEditing
            var newText = userText;
            newText.insert(replacementString.first!, at: userText.index(userText.startIndex, offsetBy: range.location));
            if(newText.compare(typoSentence.FullCorrect, options: .caseInsensitive) == .orderedSame)
            {
                textField.text = newText;
                self.finishedEditing = Date.now;
                return false;
            }
        }
        return true;
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
        
        if let selectedRange = textField.selectedTextRange {
            let cursorPosition = textField.offset(from: textField.beginningOfDocument, to: selectedRange.start)
            
            // set finishedSelecting once user moves cursor to correct position
            // note: this also sets finishedSelecting if user "overshoots"..
            // .. but this doesnt matter since the user has to move the cursor back to correct the text, thus overwriting it again (only if not finished editing yet)
            if(finishedEditing.timeIntervalSinceReferenceDate == 0 && cursorPosition == typoPosition+1)
            {
                finishedSelecting = Date.now
            }
            
            // dont allow user to select ranges, only move cursor
            if(selectedRange.end != textField.position(from: selectedRange.start, offset: 0)) {
                // get last legal position
                textField.selectedTextRange = lastLegalTextRange
            } else {
                // store as last legal position
                lastLegalTextRange = selectedRange;
            }
        }
    }
}
