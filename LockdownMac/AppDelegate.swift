//
//  AppDelegate.swift
//  LockdownMac
//
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import SwiftUI
import CocoaLumberjackSwift

var contentView: ContentView?

let fileLogger: DDFileLogger = DDFileLogger()

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
    
    func refreshIconState() {
        if (FirewallController.shared.status() == .connected || VPNController.shared.status() == .connected) {
            self.statusBarItem.button?.image = statusBarIconEnabled
        }
        else {
            self.statusBarItem.button?.image = statusBarIconDisabled
        }
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        
        // TODO: comment out for production
//        try? keychain.removeAll()
//        for key in defaults.dictionaryRepresentation().keys {
//            defaults.removeObject(forKey: key)
//        }
        
        UserDefaults.standard.register(defaults: ["NSApplicationCrashOnExceptions": true])
        
        // Set up basic logging
        setupLocalLogger()
        
        DDLogInfo("App Launched")
        
        setupFirewallDefaultBlockLists()
        
        NotificationCenter.default.addObserver(self, selector: #selector(tunnelStatusDidChange(_:)), name: .NEVPNStatusDidChange, object: nil)
        
        contentView = ContentView()
        
        let popover = NSPopover()
        popover.contentSize = NSSize(width: viewWidth, height: viewHeight)
        popover.behavior = .transient
        popover.contentViewController = NSHostingController(rootView: contentView)
        
        self.popover = popover
        
        NotificationCenter.default.addObserver(self, selector: #selector(togglePopover(_:)), name: .togglePopover, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(togglePopoverOn(_:)), name: .togglePopoverOn, object: nil)
        
        self.statusBarItem = NSStatusBar.system.statusItem(withLength: CGFloat(NSStatusItem.variableLength))
        self.statusBarItem.button?.action = #selector(togglePopover(_:))
        self.refreshIconState()
        refreshVPNStatus()
        refreshFirewallStatus()
        
        #if DEBUG
        #else
        NSApplication.shared.activate(ignoringOtherApps: true)
        self.togglePopover(nil)
        #endif
        
        // Need this check otherwise the privacy policy dialog shows up twice
        if (defaults.bool(forKey: kHasAgreedToFirewallPrivacyPolicy) == true) {
            DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                self.refreshIconState()
                refreshVPNStatus()
                refreshFirewallStatus()
            }
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
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
                turnAllOff(completion: {
                    NSApplication.shared.reply(toApplicationShouldTerminate: true)
                })
                return .terminateLater
            default:
                let alert = NSAlert()
                alert.messageText = "Are you sure you want to quit?"
                alert.informativeText = "This deactivates the Firewall and Secure Tunnel and quits the app entirely."
                alert.alertStyle = .warning
                alert.addButton(withTitle: "Deactivate & Quit")
                alert.addButton(withTitle: "Cancel")
                if alert.runModal() == .alertFirstButtonReturn {
                    turnAllOff(completion: {
                        NSApplication.shared.reply(toApplicationShouldTerminate: true)
                    })
                    return .terminateLater
                }
                else {
                    return .terminateCancel
                }
        }
        
    }
    
    @objc func turnAllOff(completion: @escaping () -> Void = {}) {
        setUserWantsFirewallEnabled(false)
        setUserWantsVPNEnabled(false)
        FirewallController.shared.deactivateIfEnabled(completion: { _ in
            VPNController.shared.deactivateIfEnabled(completion: { _ in
                completion()
            })
        })
    }
    
}

