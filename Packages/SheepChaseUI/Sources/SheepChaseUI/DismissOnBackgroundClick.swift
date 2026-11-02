import SwiftUI

#if os(macOS)
import AppKit

private struct BackgroundClickMonitor: NSViewRepresentable {
    let onDismiss: () -> Void

    func makeNSView(context: Context) -> MonitorView {
        let view = MonitorView()
        view.onDismiss = onDismiss
        return view
    }

    func updateNSView(_ nsView: MonitorView, context: Context) {
        nsView.onDismiss = onDismiss
        nsView.installMonitorIfNeeded()
    }

    static func dismantleNSView(_ nsView: MonitorView, coordinator: ()) {
        nsView.removeMonitor()
    }

    final class MonitorView: NSView {
        var onDismiss: (() -> Void)?
        private var monitor: Any?

        override func viewDidMoveToWindow() {
            super.viewDidMoveToWindow()
            DispatchQueue.main.async { [weak self] in
                self?.installMonitorIfNeeded()
            }
        }

        func installMonitorIfNeeded() {
            guard monitor == nil,
                  let sheetWindow = window,
                  let parent = sheetWindow.sheetParent ?? sheetWindow.parent
            else { return }

            monitor = NSEvent.addLocalMonitorForEvents(matching: [.leftMouseDown]) { [weak self] event in
                guard let self, event.window === parent else { return event }
                self.onDismiss?()
                return nil
            }
        }

        func removeMonitor() {
            if let monitor {
                NSEvent.removeMonitor(monitor)
                self.monitor = nil
            }
        }

        deinit {
            removeMonitor()
        }
    }
}
#endif

public extension View {
    @ViewBuilder
    func dismissOnBackgroundClick(_ action: @escaping () -> Void) -> some View {
        #if os(macOS)
        background(BackgroundClickMonitor(onDismiss: action))
        #else
        self
        #endif
    }
}
