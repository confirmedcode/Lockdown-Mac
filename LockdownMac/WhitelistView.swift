//
//  WhitelistView.swift
//  Lockdown
//
//  Created by Johnny Lin on 12/6/19.
//  Copyright © 2019 Confirmed, Inc. All rights reserved.
//

import SwiftUI

struct WhitelistView: View {
    
    @State private var newDomain: String = ""
    
    var whitelistedDomains: [WhitelistedDomain] = getLockdownWhitelistedDomainsArray()
    @State var userWhitelistedDomains: [WhitelistedDomain] = getUserWhitelistedDomainsArray()
    
    @State private var forceRefresh: String = ""
    
    var body: some View {

        VStack(spacing: 0.0) {
            VStack {
                Text("Whitelist")
                    .font(cFontHeader2)
                    .padding(.vertical, 10)
                Text("Some sites or apps do not work well with VPNs. The whitelist below allows you to whitelist sites so they bypass the VPN for a better experience.")
                    .font(cFontRegular)
                    .padding(.bottom, 10)
                    .padding(.horizontal, 12)
            }
            
            Divider()
                .padding(.vertical, 0)
            
            HStack(spacing: 0.0) {
                
                VStack(spacing: 0.0) {
                    Text("Pre-Configured Suggestions")
                    .font(cFontTitle)
                    .padding(.vertical, 10)
                    List (getLockdownWhitelistedDomainsArray().enumerated().map({ $0 }), id: \.element.domain) { index, domain in
                        VStack (alignment: .leading, spacing: 0.0) {
                            HStack {
                                Text(domain.domain)
                                .font(cFontTitle)
                                .multilineTextAlignment(.leading)
                                    .padding(.leading, 7.0)
                                .padding(.vertical, 0)
                                Spacer()
                                Button(
                                    action: {
                                        setLockdownWhitelistedDomain(domain: domain.domain, enabled: !domain.enabled)
                                        if (getUserWantsVPNEnabled()) {
                                            VPNController.shared.restart()
                                        }
                                        forceRefresh = forceRefresh + "1"
                                }) {
                                    Text(domain.enabled ? "Whitelisted" : "Not Whitelisted")
                                    .font(cFontSmall)
                                }
                            }
                            .padding(.bottom, 8)
                            Divider()
                        }
                    }
                    .accessibility(label: Text("Lockdown Whitelisted Domains List"))
                }
                
                Divider()
                
                VStack(spacing: 0.0) {
                    Text("Custom Domains")
                    .font(cFontTitle)
                    .padding(.vertical, 10)
                    HStack {
                        TextField("New Domain (e.g, domain-to-whitelist.com)", text: $newDomain, onCommit: {
                            // TODO: url checking
                            self.addDomain()
                        })
                        .introspectTextField { textField in
                            textField.becomeFirstResponder()
                        }
                        Button(action: {
                            self.addDomain()
                        }) {
                            Text("Add")
                            .font(cFontSmall)
                        }
                    }
                    .padding(.bottom, 10)
                    .padding(.horizontal, 10)
                    List (getUserWhitelistedDomainsArray().enumerated().map({ $0 }), id: \.element.domain) { index, domain in
                        VStack (alignment: .leading, spacing: 0.0) {
                            HStack {
                                Text(domain.domain)
                                .font(cFontTitle)
                                .multilineTextAlignment(.leading)
                                    .padding(.leading, 7.0)
                                .padding(.vertical, 0)
                                Spacer()
                                Button(
                                    action: {
                                        setUserWhitelistedDomain(domain: domain.domain, enabled: !domain.enabled)
                                        if (getUserWantsVPNEnabled()) {
                                            VPNController.shared.restart()
                                        }
                                        forceRefresh = forceRefresh + "1"
                                }) {
                                    Text(domain.enabled ? "Whitelisted" : "Not Whitelisted")
                                    .font(cFontSmall)
                                }
                                Button(action: {
                                    deleteUserWhitelistedDomain(domain: domain.domain)
                                    self.userWhitelistedDomains.remove(at: index)
                                    if (getUserWantsVPNEnabled()) {
                                        VPNController.shared.restart()
                                    }
                                    forceRefresh = forceRefresh + "1"
                                }) {
                                    Text("×")
                                        .padding(.bottom, 2)
                                        .foregroundColor(Color(NSColor.labelColor))
                                        .frame(width: 16, height: 16)
                                }
                                .frame(width: 16, height: 16)
                                .buttonStyle(GrayButtonStyle())
                                .opacity(0.3)
                                .cornerRadius(8)
                            }
                            .padding(.bottom, 8)
                            Divider()
                        }
                    }
                    .accessibility(label: Text("User Whitelisted Domains List"))
                }
            }
        }
        .frame(width: viewWidth * 1.9, height: viewHeight * 2/3)
        .id(forceRefresh)
    }
    
    func addDomain() {
        if self.newDomain.count > 0 {
            self.userWhitelistedDomains.append(WhitelistedDomain(domain: self.newDomain.lowercased(), enabled: true))
            addUserWhitelistedDomain(domain: self.newDomain.lowercased())
            self.newDomain = ""
            userWhitelistedDomains = getUserWhitelistedDomainsArray()
            if (getUserWantsVPNEnabled()) {
                VPNController.shared.restart()
            }
            forceRefresh = forceRefresh + "1"
        }
    }
    
}

struct WhitelistView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WhitelistView()
        }
    }
}
