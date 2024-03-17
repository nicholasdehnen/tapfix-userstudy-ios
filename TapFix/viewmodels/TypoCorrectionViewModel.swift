//
//  TypoCorrectionViewModel.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2024-03-12.
//

import Foundation
import UIKit
import Willow


class TypoCorrectionViewModel : ObservableObject
{
    @Published var textFieldIsFocused: Bool // TODO: Publishes changes in view update
    @Published var typoSentence: TypoSentenceProtocol
    @Published var userText: String
    
    @Published var methodActive: Bool
    @Published var beganEditing: Date
    @Published var beganSelecting: Date
    @Published var finishedInserting: Date
    @Published var finishedCorrecting: Date
    @Published var finishedSelecting: Date
    @Published var finishedEditing: Date
    
    @Published var testFlagged: Bool
    @Published var testFlagReason: String
    @Published var testFinished: Bool
    
    @Published var forcedWaitTime: Int
    @Published var editingAllowed: Bool
    
    @Published var showNotificationToast: Bool
    @Published var notificationToastMessage: String
    @Published var notificationToastDuration: Double
    
    // Cursed SwiftUI <> UIKit interaction
    @Published var textField: UITextField? = nil
    @Published var tapGesture: UITapGestureRecognizer? = nil
    
    let completionHandler: (TypoCorrectionResult) -> Void
    let preview: Bool
    
    let taskId: Int
    let correctionMethod: TypoCorrectionMethod
    let correctionType: TypoCorrectionType
    let refDate: Date
    
    internal var className: String { return String(describing: type(of: self))}
    internal var logger: Logger! = nil
    internal let userFlagReasonInternalError = "Sorry, an internal error occurred. Please try again."
    
    typealias TaskStatistics = (taskCompletionTime: Double, insertionTime: Double, positioningTime: Double, correctionTime: Double, methodActivationTime: Double)
    
    internal init(id: Int, typoSentence: TypoSentenceProtocol, correctionMethod: TypoCorrectionMethod, correctionType: TypoCorrectionType, completionHandler: @escaping (TypoCorrectionResult) -> Void, preview: Bool = false) {
        
        self.taskId = id
        self.correctionMethod = correctionMethod
        self.correctionType = correctionType
        
        self.methodActive = false
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
        
        self.testFlagged = false
        self.testFinished = false
        self.testFlagReason = "Test not flagged."
        
        self.forcedWaitTime = TestManager.shared.UseForcedWaitTime ? (TestManager.shared.WaitTimesForCorrectionTypes[correctionType] ?? 0) : 0
        self.editingAllowed = !TestManager.shared.UseForcedWaitTime // true if not using forced wait time, otherwise set to true by timer later
        
        self.showNotificationToast = false
        self.notificationToastMessage = "No message."
        self.notificationToastDuration = 3
        
        self.logger = buildWillowLogger(name: "\(className)-\(id)")
        
        self.tapGesture = UITapGestureRecognizer(target: self, action: #selector(tapOnTextField(_:)))
        self.tapGesture!.numberOfTapsRequired = 3 // Triple-Tap for TapFix
    }
    
    func calculateStats() -> TaskStatistics
    {
        let taskCompletionTime = beganEditing.distance(to: finishedEditing)
        let methodActivationTime = beganEditing.distance(to: beganSelecting)
        let insertionTime = finishedSelecting.distance(to: finishedInserting)
        let positioningTime = beganSelecting.distance(to: finishedSelecting)
        let correctionTime = finishedSelecting.distance(to: finishedCorrecting)
        
        return (taskCompletionTime: taskCompletionTime, insertionTime: insertionTime,
                positioningTime: positioningTime, correctionTime: correctionTime, methodActivationTime: methodActivationTime)
    }
    
    func completeTask()
    {
        let stats = self.calculateStats()
        
        let result = TypoCorrectionResult(Id: self.taskId, CorrectionMethod: self.correctionMethod, CorrectionType: self.correctionType, FaultySentence: self.typoSentence.full, UserCorrectedSentence: self.typoSentence.fullCorrect, TaskCompletionTime: stats.taskCompletionTime, MethodActivationTime: stats.methodActivationTime, CursorPositioningTime: stats.positioningTime, CharacterDeletionTime: stats.correctionTime, CharacterInsertionTime: stats.insertionTime, Flagged: self.testFlagged)
        self.completionHandler(result);
        
        let taskDescription = "\(correctionMethod.description)-\(correctionType.description)-Task \(taskId)\(self.testFlagged ? "⚑" : "")"
        var statsInfoMessage = taskDescription + String(format: " statistics: taskCompletionTime = %.3fs, methodActivationTime = %.3fs, positioningTime = %.3fs",
                                                        stats.taskCompletionTime, stats.methodActivationTime, stats.positioningTime)
        
        // Conditionally append correction ("deletion") time
        if stats.correctionTime > 0 {
            statsInfoMessage.append(String(format: ", correctionTime = %.3fs", stats.correctionTime))
        }
        
        // Conditionally append insertion time
        if stats.insertionTime > 0 {
            statsInfoMessage.append(String(format: ", insertionTime = %.3fs", stats.insertionTime))
        }
        
        // Log the stats
        logger.infoMessage(statsInfoMessage)
        logger.debugMessage {
            let eps = 0.0005
            let valuesSumUp = stats.taskCompletionTime.isClose(to: (stats.methodActivationTime + stats.positioningTime + stats.correctionTime + stats.insertionTime), within: eps)
            let taskCompletionTimeNonZero = stats.taskCompletionTime > eps
            let positioningTimeNonZero = stats.positioningTime > eps
            let textOpsTimeNonZero = (stats.correctionTime + stats.insertionTime) > eps
            let statsMakeSense = valuesSumUp && taskCompletionTimeNonZero && positioningTimeNonZero && textOpsTimeNonZero
            return ("Stats make sense: \(statsMakeSense) (valuesSumUp = \(valuesSumUp), taskCompletionTimeNonZero = \(taskCompletionTimeNonZero), positioningTimeNonZero = \(positioningTimeNonZero), textOpsTimeNonZero = \(textOpsTimeNonZero))")
        }
    }
    
    func shouldReturn(textField: PaddedTextField) -> Bool
    {
        logger.debugMessage("\(#function): returnKeyType = \(textField.returnKeyType), userText = \(self.userText), typoSentence.FullCorrect = \(self.typoSentence.fullCorrect)")
        let key = textField.returnKeyType;
        if(key == UIReturnKeyType.next) {
            if(userText.compare(typoSentence.fullCorrect, options: .caseInsensitive) == .orderedSame)
            {
                self.completeTask()
                return true;
            }
        }
        return false;
    }
    
    func notifyUser(message: String, duration: Double = 3.0) {
        logger.debugMessage(#"\#(#function): Showing notification toast with message "\#(message)""#)
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
        
        // set all undefined dates to now
        self.finishedSelecting.updateIfReferenceDate(with: now, logWith: logger, logAs: "finishedSelecting")
        self.finishedCorrecting.updateIfReferenceDate(with: now, logWith: logger, logAs: "finishedCorrecting")
        self.finishedEditing.updateIfReferenceDate(with: now, logWith: logger, logAs: "finishedEditing")
        self.finishedInserting.updateIfReferenceDate(with: now, logWith: logger, logAs: "finishedInserting")
        
        // mark test as finished and disable method (eg. tapfix)
        self.testFinished = true
        self.methodActive = false
    }
    
    @discardableResult
    func updateUiKitTextField(_ textField: UITextField) -> Bool {
        if textField == self.textField {
            return false // do not update, we already have this
        }
        
        // Log TextField change
        logger.debugMessage {
            let old = self.textField == nil ? "nil" : Unmanaged.passUnretained(self.textField!).toOpaque().debugDescription
            let new = Unmanaged.passUnretained(textField).toOpaque().debugDescription
            return "\(#function): Updating textField \(old) -> \(new)"
        }
        
        // Add gesture recognizer
        textField.addGestureRecognizer(self.tapGesture!)
        logger.debugMessage("\(#function): Added gestureRecognizer to textField.")
        
        // Add touch detection
        if let tf = textField as? PaddedTextFieldWithTouchCallbacks {
            tf.touchesBeganHandler = self.onTextFieldTouched(_:)
            logger.debugMessage("\(#function): Added touchesBeganHandler to textField.")
        }
        
        self.textField = textField // finally, store textField for later use (tapOnTextField needs it)
        return true
    }
    
    @objc private func tapOnTextField(_ tapGesture: UITapGestureRecognizer){
        let point = tapGesture.location(in: textField)
        if let detectedWord = textField!.wordAtPosition(point),
           let range = userText.range(of: detectedWord)
        {
            let startIndex = userText.distance(from: userText.startIndex, to: range.lowerBound)
            let endIndex = userText.distance(from: userText.startIndex, to: range.upperBound) - 1
            logger.debugMessage("\(#function): Triple-tap detected on: '\(detectedWord)' [\(startIndex), \(endIndex)]")
            self.onTripleTapDetected(word: detectedWord, range: startIndex ... endIndex)
        }
    }
    
    // Exposed to potential sub-classes, not used in base model
    func onBeganEditing(textField: PaddedTextField) {}
    func onChangedSelection(textField: PaddedTextField) {}
    func shouldChangeCharacters(textField: PaddedTextField, range: NSRange, replacementString: String) -> Bool { return true }
    func onTripleTapDetected(word: String, range: ClosedRange<Int>) {}
    func onTextFieldTouched(_ touches: [UITouch]) {}
}
