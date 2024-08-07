//
//  PaddedTextField.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-11.
//

import SwiftUI
import UIKitTextField
import Willow


// Inverted Boolean Binding
prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
    Binding<Bool>(
        get: { !value.wrappedValue },
        set: { value.wrappedValue = !$0 }
    )
}

// TextField with padding
class PaddedTextField: BaseUITextField {
    var padding = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8) {
        didSet {
            setNeedsLayout()
        }
    }
    
    public override func textRect(forBounds bounds: CGRect) -> CGRect {
        super.textRect(forBounds: bounds).inset(by: padding)
    }
    
    public override func editingRect(forBounds bounds: CGRect) -> CGRect {
        super.editingRect(forBounds: bounds).inset(by: padding)
    }
    
    // return range of selection
    public var selectedSwiftTextRange: ClosedRange<Int>? {
        if let selectedRange = super.selectedTextRange {
            let start = offset(from: beginningOfDocument, to: selectedRange.start)
            let end = offset(from: beginningOfDocument, to: selectedRange.end)
            return start ... end
        }
        else {
            return nil
        }
    }
}

// PaddedTextField with low-level touch callbacks
class PaddedTextFieldWithTouchCallbacks : PaddedTextField {
    var touchesBeganHandler : ((_ touches: [UITouch] ) -> Void)? = nil
    var touchesMovedHandler : ((_ touches: [UITouch], _ locations : [CGPoint]) -> Void)? = nil
    var touchesEndedHandler : ((_ touches: [UITouch] ) -> Void)? = nil
    
    private(set) var lastGestureRecognizerShouldBeginEvent: Date = Date.referenceDate
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        lastGestureRecognizerShouldBeginEvent = Date.now
        return true
    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        touchesBeganHandler?(Array(touches))
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesMoved(touches, with: event)
        touchesMovedHandler?(Array(touches), touches.map { $0.location(in: self) })
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        touchesEndedHandler?(Array(touches))
    }
}


// Allow getting word at coordinate (hit-test) from UITextField
extension UITextField {
    func wordAtPosition(_ point: CGPoint) -> String? {
        if let textPosition = closestPosition(to: point)
        {
            if let range = tokenizer.rangeEnclosingPosition(textPosition, with: .word, inDirection: UITextDirection(rawValue: 1))
            {
                return self.text(in: range)
            }
        }
        return nil
    }
}


// UITextInput range as NSRange
// from: https://stackoverflow.com/a/38805072
extension UITextInput {
    var selectedRange: NSRange? {
        guard let range = selectedTextRange else { return nil }
        let location = offset(from: beginningOfDocument, to: range.start)
        let length = offset(from: range.start, to: range.end)
        return NSRange(location: location, length: length)
    }
}

// Wrapper for UITextView with dynamic height
struct TextView: UIViewRepresentable {
    
    @Binding var text: String?
    @Binding var desiredHeight: CGFloat
    
    func makeUIView(context: Context) -> UITextView {
        let textView = UITextView()
        textView.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body)
        textView.textAlignment = .justified
        textView.isEditable = false
        textView.isUserInteractionEnabled = false
        return textView
    }
    
    func updateUIView(_ uiView: UITextView, context: Context) {
        uiView.text = self.text
        
        // Compute the desired height for the content
        let fixedWidth = uiView.frame.size.width
        let newSize = uiView.sizeThatFits(CGSize(width: fixedWidth, height: CGFloat.greatestFiniteMagnitude))
        
        DispatchQueue.main.async {
            self.desiredHeight = newSize.height
        }
    }
}

// Swaps two indices without mutating the array
extension Array {
    func swapping(_ index1: Int, with index2: Int) -> Array {
        var newArray = self
        guard index1 < count, index2 < count, index1 != index2 else { return newArray }
        newArray.swapAt(index1, index2)
        return newArray
    }
}


// Allow Date to be easily compared to reference Date (timeIntervalSinceReferenceDate == 0)
extension Date {
    var isReferenceDate: Bool {
        return self.timeIntervalSinceReferenceDate == 0
    }
    
    static var referenceDate: Date {
        return Date(timeIntervalSinceReferenceDate: 0)
    }
    
    mutating func updateIfReferenceDate(with newDate: Date = Date.now, logWith logger: Logger? = nil, logAs logName: String = "date",
                                        logSource: String = #function, logLevel : LogLevel = .debug)
    {
        if self.isReferenceDate {
            if let logger = logger {
                logger.logMessage({
                    "Updating \(logName) = \(newDate)" + (" (Source: \(logSource))")
                }, with: logLevel)
            }
            self = newDate
        }
    }
}

// Allow Double to be compared with another, given
extension Double {
    func isClose(to value: Double, within delta: Double = Double.ulpOfOne) -> Bool {
        return abs(self - value) <= delta
    }
}

// Convert Bool to Int. Wild that this is not part of the language
extension Bool {
    var intValue: Int {
        return self ? 1 : 0
    }
}

// https://stackoverflow.com/a/64455539
extension String {
    func size(with font: UIFont) -> CGSize
    {
        let fontAttributes = [NSAttributedString.Key.font: font]
        return self.size(withAttributes: fontAttributes)
    }
}
