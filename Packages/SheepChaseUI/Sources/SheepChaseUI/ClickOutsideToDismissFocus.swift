import SwiftUI

#if os(macOS)
import AppKit
#else
import UIKit
#endif

public struct ClickOutsideToDismissFocus: ViewModifier {
    public init() {}

    public func body(content: Content) -> some View {
        #if os(macOS)
        content.modifier(MacFocusDismissModifier())
        #else
        content.modifier(IOSFocusDismissModifier())
        #endif
    }
}

public extension View {
    func dismissFocusOnBackgroundClick() -> some View {
        modifier(ClickOutsideToDismissFocus())
    }
}

#if os(macOS)
private struct MacFocusDismissModifier: ViewModifier {
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear {
                guard monitor == nil else { return }
                monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown, .rightMouseDown]) { event in
                    guard let window = event.window,
                          let contentView = window.contentView
                    else { return event }

                    if let responder = window.firstResponder as? NSView {
                        let point = responder.convert(event.locationInWindow, from: nil)
                        if responder.bounds.contains(point) { return event }
                    }

                    let point = contentView.convert(event.locationInWindow, from: nil)
                    var hit = contentView.hitTest(point)
                    while let view = hit {
                        if view is NSTextView || view is NSTextField { return event }
                        hit = view.superview
                    }

                    window.makeFirstResponder(nil)
                    return event
                }
            }
            .onDisappear {
                if let monitor {
                    NSEvent.removeMonitor(monitor)
                    self.monitor = nil
                }
            }
    }
}
#else
private struct IOSFocusDismissModifier: ViewModifier {
    func body(content: Content) -> some View {
        content.background(FocusDismissInstaller())
    }
}

private struct FocusDismissInstaller: UIViewRepresentable {
    func makeCoordinator() -> Coordinator { Coordinator() }

    func makeUIView(context: Context) -> UIView {
        let view = UIView()
        view.isUserInteractionEnabled = false
        DispatchQueue.main.async { context.coordinator.install() }
        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async { context.coordinator.install() }
    }

    static func dismantleUIView(_ uiView: UIView, coordinator: Coordinator) {
        coordinator.uninstall()
    }

    final class Coordinator: NSObject, UIGestureRecognizerDelegate {
        private weak var installedWindow: UIWindow?
        private var recognizer: UITapGestureRecognizer?

        func install() {
            guard let window = Self.keyWindow() else { return }
            guard installedWindow !== window else { return }
            uninstall()
            let tap = UITapGestureRecognizer(target: self, action: #selector(handle(_:)))
            tap.cancelsTouchesInView = false
            tap.delegate = self
            window.addGestureRecognizer(tap)
            recognizer = tap
            installedWindow = window
        }

        func uninstall() {
            if let recognizer {
                recognizer.view?.removeGestureRecognizer(recognizer)
            }
            recognizer = nil
            installedWindow = nil
        }

        @objc private func handle(_ gesture: UITapGestureRecognizer) {
            guard let window = gesture.view as? UIWindow else { return }
            let point = gesture.location(in: window)
            var hit = window.hitTest(point, with: nil)
            while let view = hit {
                if view is UITextField || view is UITextView { return }
                hit = view.superview
            }
            window.endEditing(true)
        }

        func gestureRecognizer(
            _ gestureRecognizer: UIGestureRecognizer,
            shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer
        ) -> Bool {
            true
        }

        private static func keyWindow() -> UIWindow? {
            UIApplication.shared.connectedScenes
                .compactMap { $0 as? UIWindowScene }
                .flatMap(\.windows)
                .first { $0.isKeyWindow }
        }
    }
}
#endif
