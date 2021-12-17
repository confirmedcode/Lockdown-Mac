//
//  MenuView.swift
//  Lockdown
//
//  Created by Johnny Lin on 1/22/20.
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import Foundation
import SwiftUI
import CocoaLumberjackSwift

func getEmailTopText() -> String {
    return (getAPICredentials() != nil) ? getAPICredentials()!.email : "Not Signed In\nSign Up With Lockdown iOS"
}

func getEmailSignInText() -> String {
    return (getAPICredentials() != nil) ? "Sign Out" : "Sign In"
}

struct MenuView: View {
    
    @ObservedObject var userDefaultsManager = UserDefaultsManager()
    @State private var showEmailLogin: Bool = false
    
    let timer = Timer.publish(every: 1, on: .current, in: .common).autoconnect()
    @State var emailTopText = getEmailTopText()
    @State var emailSignInText = getEmailSignInText()
    
    var body: some View {
        
        VStack(spacing: 0) {
            HStack(spacing: 0) {
                Text("\(emailTopText)")
                    .font(cFontSubtitle2)
                    .padding(.leading, 10)
                    .multilineTextAlignment(.center)
                    .frame(height: 28)
                    .frame(minWidth: 0, maxWidth: .infinity)
                    .minimumScaleFactor(0.5)
                    .onReceive(timer) { _ in
                        print("=============== MENU TIMER FIRED")
                        self.emailTopText = getEmailTopText()
                        self.emailSignInText = getEmailSignInText()
                    }
                Button(
                    action: {
                        if (getAPICredentials() != nil) {
                            if VPNController.shared.status() == .connected {
                                VPNController.shared.setEnabled(false)
                            }
                            clearAPICredentials()
                        }
                        else {
                            self.showEmailLogin = true
                        }
                }) {
                    Text("\(emailSignInText)")
                        .font(cFontSubtitle)
                        .frame(width: 70, height: 30)
                }
                .buttonStyle(BlueButtonStyle())
                .cornerRadius(8)
                .padding(.vertical, 8)
                .padding(.horizontal, 6)
            }
            .background(Color.mainBackground)
            .cornerRadius(8)
            .frame(minWidth: 0, maxWidth: .infinity)
            
            Divider()
                .padding(.top, 6)
            
            Toggle(isOn: self.$userDefaultsManager.openOnStartup) {
                Text("Launch On Login")
            }
            .toggleStyle(LaunchOnLoginToggleStyle())
            .background(Color.mainBackground)
            .frame(minWidth: 200, maxWidth: .infinity, alignment: .leading)
            .cornerRadius(8)
            .padding(.top, 4)
            
            HStack {
                Button(
                    action: {
                        let url = URL(string: "https://lockdownhq.com/privacy")!
                        if NSWorkspace.shared.open(url) {
                            DDLogInfo("privacy opened")
                        }
                }) {
                    Text("Privacy Policy")
                        .font(cFontSubtitle2)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(BlueButtonStyle())
                .cornerRadius(8)
                .padding(.top, 8)
                
                Button(
                    action: {
                        let url = URL(string: "https://lockdownhq.com")!
                        if NSWorkspace.shared.open(url) {
                            DDLogInfo("website opened")
                        }
                }) {
                    Text("Website")
                        .font(cFontSubtitle2)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(BlueButtonStyle())
                .cornerRadius(8)
                .padding(.top, 8)
            }
            
            HStack {
                Button(
                    action: {
                        let url = URL(string: "https://lockdownhq.com/faq")!
                        if NSWorkspace.shared.open(url) {
                            DDLogInfo("faq opened")
                        }
                }) {
                    Text("FAQs")
                        .font(cFontSubtitle2)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(BlueButtonStyle())
                .cornerRadius(8)
                .padding(.top, 8)
                
                Button(
                    action: {
                        let sharingService = NSSharingService(named: NSSharingService.Name.composeEmail)
                        sharingService?.recipients = ["team@lockdownhq.com"]
                        sharingService?.subject = "Lockdown Feedback (macOS)"
                        
                        var items: [Any] = ["Hey Lockdown Team, \nI have a question, issue, or suggestion - \n\n\n\n\n"]
                        
                        let uuid = NSUUID().uuidString
                        if let tempDir = NSURL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent(uuid) {
                            let fileManager = FileManager()
                            try? fileManager.createDirectory(at: tempDir, withIntermediateDirectories: true, attributes: nil)
                            let tempFile = tempDir.appendingPathComponent("LockdownLogs.log")
                            let attachmentData = NSMutableData()
                            for logFileData in logFileDataArray {
                                attachmentData.append(logFileData as Data)
                            }
                            attachmentData.write(to: tempFile, atomically: false)
                            items.append(tempFile)
                        }

                        sharingService?.perform(withItems: items)
                }) {
                    Text("Support")
                        .font(cFontSubtitle2)
                        .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
                }
                .buttonStyle(BlueButtonStyle())
                .cornerRadius(8)
                .padding(.top, 8)
            }
        
            Button(
                action: {
                    NotificationCenter.default.post(name: Notification.Name.hideMenu, object: nil, userInfo: nil)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                        NotificationCenter.default.post(name: Notification.Name.togglePopoverOff, object: nil, userInfo: nil)
                    }
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
                        NSApplication.shared.terminate(self)
                    }
            }) {
                Text("Quit")
                    .font(cFontSubtitle2)
                    .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
            }
            .buttonStyle(GrayButtonStyle())
            .cornerRadius(8)
            .padding(.top, 8)
            
            Text("v\(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "")")
            .font(cFontSmall)
            .foregroundColor(Color.gray)
            .padding(.top, 7)
            .frame(minWidth: 0, maxWidth: .infinity, alignment: .trailing)
            .popover(isPresented: self.$showEmailLogin) {
                EmailLoginView(successCallback: {
                    DDLogInfo("success callback")
                } )
            }
            
        }
        .padding(10)
        .frame(width: 290, height: 275)
        
    }
    
}

struct MenuView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            MenuView()
        }
    }
}

struct LaunchOnLoginToggleStyle: ToggleStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        HStack {
            Text("Launch On Login")
            .font(cFontSubtitle2)
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 40)
            Spacer()
            Button(action: { configuration.isOn.toggle() } )
            {
                RoundedRectangle(cornerRadius: 16, style: .circular)
                    .fill(configuration.isOn ? Color.confirmedBlue : Color.lightGray)
                    .frame(width: 50, height: 29)
                    .overlay(
                        Circle()
                            .fill(Color.white)
                            .shadow(radius: 1, x: 0, y: 1)
                            .padding(1.5)
                            .offset(x: configuration.isOn ? 10 : -10))
                    .animation(Animation.easeInOut(duration: 0.1))
            }
            .buttonStyle(BlankButtonStyle())
        }
        .padding(.horizontal)
    }
}
