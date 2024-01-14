//
//  PaddedTextField.swift
//  TapFix
//
//  Created by Nicholas Dehnen on 2022-12-11.
//

import SwiftUI
import UIKitTextField


prefix func ! (value: Binding<Bool>) -> Binding<Bool> {
    Binding<Bool>(
        get: { !value.wrappedValue },
        set: { value.wrappedValue = !$0 }
    )
}

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
}

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
