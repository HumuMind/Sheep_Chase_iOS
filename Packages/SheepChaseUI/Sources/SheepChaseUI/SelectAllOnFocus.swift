import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

private struct SelectAllOnFocusModifier: ViewModifier {
    @FocusState private var isFocused: Bool

    func body(content: Content) -> some View {
        content
            .focused($isFocused)
            .onChange(of: isFocused) { _, focused in
                guard focused else { return }
                selectAll()
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.12) {
                    selectAll()
                }
            }
    }

    private func selectAll() {
        #if os(macOS)
        if let editor = NSApp.keyWindow?.firstResponder as? NSTextView {
            editor.selectAll(nil)
        } else {
            NSApp.sendAction(#selector(NSText.selectAll(_:)), to: nil, from: nil)
        }
        #else
        UIApplication.shared.sendAction(
            #selector(UIResponder.selectAll(_:)),
            to: nil,
            from: nil,
            for: nil
        )
        #endif
    }
}

public extension View {
    func selectAllOnFocus() -> some View {
        modifier(SelectAllOnFocusModifier())
    }
}
