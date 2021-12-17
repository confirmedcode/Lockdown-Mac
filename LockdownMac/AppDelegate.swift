//
//  AppDelegate.swift
//  LockdownMac
//
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import SwiftUI
import CocoaLumberjackSwift
import Foundation

var contentView: ContentView?

let fileLogger: DDFileLogger = DDFileLogger()

let kDoNotShowQuitConfirmation = "kDoNotShowQuitConfirmation"
var isAutolaunch = false

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var window: NSWindow!
    
    var popover: NSPopover!
    var statusBarItem: NSStatusItem!
    
    var statusBarIconEnabled = NSImage(named: "StatusBarEnabled")
    var statusBarIconDisabled = NSImage(named: "StatusBarDisabled")
    
    @objc func tunnelStatusDidChange(_ notification: Notification) {
        DDLogInfo("Firewall Status: \(FirewallController.shared.status().rawValue)")
        refreshFirewallStatus()
        DDLogInfo("VPN Status: \(VPNController.shared.status().rawValue)")
        refreshVPNStatus()
        
        refreshIconState()
        
        if (VPNController.shared.status() == .disconnected && getUserWantsVPNEnabled() == true) {
            DDLogInfo("UserWantsVPNEnabled = true and disconnected, reactivating.")
            VPNController.shared.restart()
        }
    }
    
    @objc func togglePopover(_ sender: AnyObject?) {
         if let button = self.statusBarItem.button {
              if self.popover.isShown {
                self.popover.performClose(sender)
              } else {
                NSApplication.shared.activate(ignoringOtherApps: true)
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
              }
         }
    }
    
    @objc func togglePopoverOn(_ sender: AnyObject?) {
         if let button = self.statusBarItem.button {
              NSApplication.shared.activate(ignoringOtherApps: true)
              self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
         }
    }
    
    @objc func togglePopoverOff(_ sender: AnyObject?) {
        self.popover.performClose(nil)
    }
    
    func refreshIconState() {
        if (FirewallController.shared.status() == .connected || VPNController.shared.status() == .connected) {
            self.statusBarItem.button?.image = statusBarIconEnabled
        }
        else {
            self.statusBarItem.button?.image = statusBarIconDisabled
        }
    }
    
    @objc func becameInactive() {
        DDLogInfo("USERSWITCH: switched OUT from fast user")
        turnAllOffBeforeLogOutAndSaveState(completion: {
        })
    }
    
    @objc func becameActive() {
        DDLogInfo("USERSWITCH: switched IN from fast user")
        FirewallController.shared.deactivateIfEnabled(completion: { _ in
            VPNController.shared.deactivateIfEnabled(completion: { _ in
                DDLogInfo("USERSWITCH: reinstating")
                contentView?.reinstateActivatedStates()
            })
        })
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
//        // TODO: comment out for production
//        try? keychain.removeAll()
//        for key in defaults.dictionaryRepresentation().keys {
//            defaults.removeObject(forKey: key)
//        }
//        return
        
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        
        // Set up basic logging
        setupLocalLogger()
        
        DDLogInfo("App Launched")
        
        // Kill Launcher if running
        if let mainBundleId = Bundle.main.bundleIdentifier {
            let runningApps = NSWorkspace.shared.runningApplications
            let isRunning = !runningApps.filter { $0.bundleIdentifier == launcherAppId }.isEmpty
            if isRunning {
                isAutolaunch = true
                DistributedNotificationCenter.default().post(name: .killLauncher, object: mainBundleId)
            }
        }
        
        // Fast User Switching OUT
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(becameInactive),
            name: NSWorkspace.sessionDidResignActiveNotification,
            object: nil
        )

        // Fast User Switching IN
        NSWorkspace.shared.notificationCenter.addObserver(
            self,
            selector: #selector(becameActive),
            name: NSWorkspace.sessionDidBecomeActiveNotification,
            object: nil
        )
        
        setupFirewallDefaultBlockLists()
        setupLockdownWhitelistedDomains()
        
        NotificationCenter.default.addObserver(self, selector: #selector(tunnelStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
        
        contentView = ContentView()
        
        let popover = NSPopover()
        popover.contentSize = NSSize(width: viewWidth, height: viewHeight)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        self.popover = popover
        
        NotificationCenter.default.addObserver(self, selector: #selector(togglePopover(_:)), name: .togglePopover, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(togglePopoverOn(_:)), name: .togglePopoverOn, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(togglePopoverOff(_:)), name: .togglePopoverOff, object: nil)
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        self.statusBarItem.button?.action = #selector(togglePopover(_:))
        self.refreshIconState()
        refreshVPNStatus()
        refreshFirewallStatus()
        
        #if DEBUG
        #else
        // add delay for status button to render correctly, otherwise popover will be in the wrong place
        if let button = self.statusBarItem.button {
            NSApplication.shared.activate(ignoringOtherApps: true)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                self.popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
            }
        }
        #endif
        
        // Need this check otherwise the privacy policy dialog shows up twice
        if (defaults.bool(forKey: kHasAgreedToFirewallPrivacyPolicy) == true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3, qos: .userInteractive, flags: .enforceQoS) {
                self.refreshIconState()
                refreshVPNStatus()
                refreshFirewallStatus()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1, qos: .userInteractive, flags: .enforceQoS) {
                self.refreshIconState()
                refreshVPNStatus()
                refreshFirewallStatus()
            }
        }
    }
    
    func applicationDidResignActive(_ notification: Notification) {
        self.popover.performClose(nil)
    }
    
    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplication.TerminateReply {
        
        // If it's a shutdown/restart/logoff, turn everything off without prompting
        // Otherwise prompt for quitting
        let desc = NSAppleEventManager.shared().currentAppleEvent
        switch desc?.attributeDescriptor(forKeyword: kAEQuitReason)?.enumCodeValue {
            case kAELogOut, kAEReallyLogOut, kAEShowRestartDialog, kAERestart, kAEShowShutdownDialog, kAEShutDown:
                turnAllOffBeforeLogOutAndSaveState(completion: {
                    NSApplication.shared.reply(toApplicationShouldTerminate: true)
                })
                return .terminateLater
            default:
                if (defaults.bool(forKey: kDoNotShowQuitConfirmation)) {
                    turnAllOffBeforeLogOutAndSaveState(completion: {
                        NSApplication.shared.reply(toApplicationShouldTerminate: true)
                    })
                    return .terminateLater
                }
                else {
                    let alert = NSAlert()
                    alert.messageText = "Are you sure you want to quit?"
                    alert.informativeText = "This deactivates the Firewall and Secure Tunnel and quits the app entirely.\n\nIf you didn't request to close Lockdown, then your Mac is trying to automatically update Lockdown to a newer version. To complete the update, click \"Deactivate & Quit\". Lockdown will re-launch itself afterwards."
                    alert.showsSuppressionButton = true
                    alert.suppressionButton?.title = "Do not show this dialog again"
                    alert.alertStyle = .warning
                    alert.addButton(withTitle: "Deactivate & Quit")
                    alert.addButton(withTitle: "Cancel")
                    if alert.runModal() == .alertFirstButtonReturn {
                        if (alert.suppressionButton?.state == NSControl.StateValue.on) {
                            defaults.set(true, forKey: kDoNotShowQuitConfirmation)
                        }
                        turnAllOffBeforeLogOutAndSaveState(completion: {
                            NSApplication.shared.reply(toApplicationShouldTerminate: true)
                        })
                        return .terminateLater
                    }
                    else {
                        return .terminateCancel
                    }
                }
        }
        
    }
    
    func applicationShouldHandleReopen(_ sender: NSApplication, hasVisibleWindows flag: Bool) -> Bool {
        if self.popover.isShown == false {
            self.togglePopover(nil)
        }
        return true
    }
    
    @objc func turnAllOffBeforeLogOutAndSaveState(completion: @escaping () -> Void = {}) {
        setSavedUserWantsFirewallEnabled(getUserWantsFirewallEnabled())
        setSavedUserWantsVPNEnabled(getUserWantsVPNEnabled())
        setUserWantsFirewallEnabled(false)
        setUserWantsVPNEnabled(false)
        FirewallController.shared.deactivateIfEnabled(completion: { _ in
            VPNController.shared.deactivateIfEnabled(completion: { _ in
                completion()
            })
        })
    }
    
    func application(_ application: NSApplication, open urls: [URL]) {
        
//        guard let url = urls.first, let components = NSURLComponents(url: url, resolvingAgainstBaseURL: true), let host = components.host else {
//            print("No url found")
//            return
//        }
//
//        if (host == "emailconfirmed") {
            let alert = NSAlert()
            alert.messageText = "Please open this confirmation email link from your iPhone or iPad to complete signup."
            alert.addButton(withTitle: "Okay")
            alert.runModal()
//        }
        
    }
    
}

