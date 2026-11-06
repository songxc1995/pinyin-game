import SwiftUI
#if os(macOS)
import AppKit
#endif

@main
public struct PinyinKitchenApp: App {
    #if os(macOS)
    @NSApplicationDelegateAdaptor(MacAppDelegate.self) private var appDelegate
    #endif

    public init() {}

    public var body: some Scene {
        WindowGroup("满满的奇妙料理城 · 沪教一年级语数英冒险屋") {
            MainContainerView()
                #if os(macOS)
                .frame(minWidth: 940, idealWidth: 1200, minHeight: 700, idealHeight: 800)
                #endif
        }
        #if os(macOS)
        .defaultSize(width: 1200, height: 800)
        #endif
    }
}

#if os(macOS)
public final class MacAppDelegate: NSObject, NSApplicationDelegate {
    public func applicationDidFinishLaunching(_ notification: Notification) {
        NSApp.setActivationPolicy(.regular)
        NSApp.activate(ignoringOtherApps: true)
    }

    public func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        true
    }
}
#endif
