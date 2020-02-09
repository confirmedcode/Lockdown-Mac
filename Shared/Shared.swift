//
//  Shared.swift
//  Lockdown
//
//  Created by Johnny Lin on 12/5/19.
//  Copyright © 2019 Confirmed, Inc. All rights reserved.
//

import Foundation
import SwiftUI
import KeychainAccess
import CocoaLumberjackSwift

let defaults = UserDefaults(suiteName: "V8J3Z26F6Z.group.confirmed.lockdownMac")!
let keychain = Keychain(service: "com.confirmed.lockdownMac").synchronizable(true)

extension Notification.Name {
    static let togglePopover = Notification.Name("togglePopover")
    static let togglePopoverOn = Notification.Name("togglePopoverOn")
}

// MARK: - User Interface (UI)

let viewWidth: CGFloat = 360.0
let viewHeight: CGFloat = 740.0

let cFontHeader = Font.custom("Montserrat-Bold", size: 20)
let cFontHeader2 = Font.custom("Montserrat-Bold", size: 18)
let cFontTitle = Font.custom("Montserrat-Medium", size: 16)
let cFontSubtitle = Font.custom("Montserrat-Bold", size: 12)
let cFontSubtitle2 = Font.custom("Montserrat-SemiBold", size: 14)
let cFontSmall = Font.custom("Montserrat-Bold", size: 11)
let cFontTiny = Font.custom("Montserrat-Bold", size: 9)
let cFontRegular = Font.custom("Montserrat-Regular", size: 14)
let cFontRegularSmall = Font.custom("Montserrat-Regular", size: 12)

let sfProRoundedBold20 = Font.custom("SFProRounded-Bold", size: 20)
let sfProRoundedSemiBold28 = Font.custom("SFProRounded-SemiBold", size: 28)

extension Color {
    static let confirmedBlue = Color(red: 0/255.0, green: 173/255.0, blue: 231/255.0)
    static let panelBackground = Color("Panel Background")
    static let mainBackground = Color("Main Background")
    
    static let lightGray = Color(NSColor.lightGray)
    static let flatRed = Color(red: 231/255, green: 76/255, blue: 60/255)
}

struct BlueButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.blue : Color.white)
            .background(Color.confirmedBlue)
    }
}

struct BlankButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
    }
}

struct GrayButtonStyle: ButtonStyle {
    func makeBody(configuration: Self.Configuration) -> some View {
        configuration.label
            .foregroundColor(configuration.isPressed ? Color.gray : Color.white)
            .background(Color.gray)
    }
}

// MARK: - Extensions

extension String: Error { // Error makes it easy to throw errors as one-liners
    
    func base64Encoded() -> String? {
        if let data = self.data(using: .utf8) {
            return data.base64EncodedString()
        }
        return nil
    }
    
    func base64Decoded() -> String? {
        if let data = Data(base64Encoded: self) {
            return String(data: data, encoding: .utf8)
        }
        return nil
    }
    
}

// MARK: - User wants Firewall/VPN Enabled

let kUserWantsFirewallEnabled = "user_wants_firewall_enabled"
let kUserWantsVPNEnabled = "user_wants_vpn_enabled"

func setUserWantsFirewallEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: kUserWantsFirewallEnabled)
}

func getUserWantsFirewallEnabled() -> Bool {
    return defaults.bool(forKey: kUserWantsFirewallEnabled)
}

func setUserWantsVPNEnabled(_ enabled: Bool) {
    defaults.set(enabled, forKey: kUserWantsVPNEnabled)
}

func getUserWantsVPNEnabled() -> Bool {
    return defaults.bool(forKey: kUserWantsVPNEnabled)
}

// MARK: - API Credentials

let kAPICredentialsEmail = "APICredentialsEmail"
let kAPICredentialsPassword = "APICredentialsPassword"

struct APICredentials {
    var email: String = ""
    var password: String = ""
}

func setAPICredentials(email: String, password: String) throws {
    DDLogInfo("Setting API Credentials with email: \(email)")
    if (email == "") {
        throw "Email was blank"
    }
    if (password == "") {
        throw "Password was blank"
    }
    do {
        try keychain.set(email, key: kAPICredentialsEmail)
        try keychain.set(password, key: kAPICredentialsPassword)
    }
    catch {
        throw "Unable to set API credentials on keychain"
    }
}

func clearAPICredentials() {
    try? keychain.remove(kAPICredentialsEmail)
    try? keychain.remove(kAPICredentialsPassword)
}

func getAPICredentials() -> APICredentials? {
    DDLogInfo("Getting stored API credentials")
    var email: String? = nil
    do {
        email = try keychain.get(kAPICredentialsEmail)
        if email == nil {
            DDLogInfo("No stored API credential email")
            return nil
        }
    }
    catch {
        DDLogInfo("Error getting stored API credentials email: \(error)")
        return nil
    }
    var password: String? = nil
    do {
        password = try keychain.get(kAPICredentialsPassword)
        if password == nil {
            DDLogInfo("No stored API credential password")
            return nil
        }
    }
    catch {
        DDLogInfo("Error getting stored API credentials password: \(error)")
        return nil
    }
    DDLogInfo("Returning stored API credentials with email: \(email!)")
    return APICredentials(email: email!, password: password!)
}


// MARK: - VPN Credentials

let kVPNCredentialsKeyBase64 = "VPNCredentialsKeyBase64"
let kVPNCredentialsId = "VPNCredentialsId"

struct VPNCredentials {
    var id: String = ""
    var keyBase64: String = ""
}

func setVPNCredentials(id: String, keyBase64: String) throws {
    DDLogInfo("Setting VPN Credentials: \(id), base64: \(keyBase64)")
    if (id == "") {
        throw "ID was blank"
    }
    if (keyBase64 == "") {
        throw "Key was blank"
    }
    do {
        try keychain.set(id, key: kVPNCredentialsId)
        try keychain.set(keyBase64, key: kVPNCredentialsKeyBase64)
    }
    catch {
        throw "Unable to set VPN credentials on keychain"
    }
}

func getVPNCredentials() -> VPNCredentials? {
    DDLogInfo("Getting stored VPN credentials")
    var id: String? = nil
    do {
        id = try keychain.get(kVPNCredentialsId)
        if id == nil {
            DDLogInfo("No stored credential id")
            return nil
        }
    }
    catch {
        DDLogInfo("Error getting stored VPN credentials id: \(error)")
        return nil
    }
    var keyBase64: String? = nil
    do {
        keyBase64 = try keychain.get(kVPNCredentialsKeyBase64)
        if keyBase64 == nil {
            DDLogInfo("No stored credential keyBase64")
            return nil
        }
    }
    catch {
        DDLogInfo("Error getting stored VPN credentials keyBase64: \(error)")
        return nil
    }
    DDLogInfo("Returning stored VPN credentials: \(id!) \(keyBase64!)")
    return VPNCredentials(id: id!, keyBase64: keyBase64!)
}


// MARK: - VPN Region

let kSavedVPNRegionServerPrefix = "vpn_region_server_prefix"

struct VPNRegion {
    var regionDisplayName: String = ""
    var regionDisplayNameShort: String = ""
    var regionFlagEmoji: String = ""
    var serverPrefix: String = ""
}

let vpnRegions:[VPNRegion] = [
    VPNRegion(regionDisplayName: NSLocalizedString("United States - West", comment: ""),
              regionDisplayNameShort: NSLocalizedString("USA West", comment: ""),
              regionFlagEmoji: "🇺🇸",
              serverPrefix: "us-west"),
    VPNRegion(regionDisplayName: NSLocalizedString("United States - East", comment: ""),
              regionDisplayNameShort: NSLocalizedString("USA East", comment: ""),
              regionFlagEmoji: "🇺🇸",
              serverPrefix: "us-east"),
    VPNRegion(regionDisplayName: NSLocalizedString("United Kingdom", comment: ""),
              regionDisplayNameShort: NSLocalizedString("United Kingdom", comment: ""),
              regionFlagEmoji: "🇬🇧",
              serverPrefix: "eu-london"),
    VPNRegion(regionDisplayName: NSLocalizedString("Ireland", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Ireland", comment: ""),
              regionFlagEmoji: "🇮🇪",
              serverPrefix: "eu-ireland"),
    VPNRegion(regionDisplayName: NSLocalizedString("Germany", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Germany", comment: ""),
              regionFlagEmoji: "🇩🇪",
              serverPrefix: "eu-frankfurt"),
    VPNRegion(regionDisplayName: NSLocalizedString("Canada", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Canada", comment: ""),
              regionFlagEmoji: "🇨🇦",
              serverPrefix: "canada"),
    VPNRegion(regionDisplayName: NSLocalizedString("India", comment: ""),
              regionDisplayNameShort: NSLocalizedString("India", comment: ""),
              regionFlagEmoji: "🇮🇳",
              serverPrefix: "ap-mumbai"),
    VPNRegion(regionDisplayName: NSLocalizedString("Japan", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Japan", comment: ""),
              regionFlagEmoji: "🇯🇵",
              serverPrefix: "ap-tokyo"),
    VPNRegion(regionDisplayName: NSLocalizedString("Australia", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Australia", comment: ""),
              regionFlagEmoji: "🇦🇺",
              serverPrefix: "ap-sydney"),
    VPNRegion(regionDisplayName: NSLocalizedString("South Korea", comment: ""),
              regionDisplayNameShort: NSLocalizedString("South Korea", comment: ""),
              regionFlagEmoji: "🇰🇷",
              serverPrefix: "ap-seoul"),
    VPNRegion(regionDisplayName: NSLocalizedString("Singapore", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Singapore", comment: ""),
              regionFlagEmoji: "🇸🇬",
              serverPrefix: "ap-singapore"),
    VPNRegion(regionDisplayName: NSLocalizedString("Brazil", comment: ""),
              regionDisplayNameShort: NSLocalizedString("Brazil", comment: ""),
              regionFlagEmoji: "🇧🇷",
              serverPrefix: "sa")
]

func getVPNRegionForServerPrefix(serverPrefix: String) -> VPNRegion {
    DDLogInfo("Getting VPN region for server prefix: \(serverPrefix)")
    for vpnRegion in vpnRegions {
        if vpnRegion.serverPrefix == serverPrefix {
            return vpnRegion
        }
    }
    DDLogInfo("Could not find VPN region for server prefix: \(serverPrefix)")
    return vpnRegions[0]
}

func getSavedVPNRegion() -> VPNRegion {
    DDLogInfo("getSavedVPNRegion")
    if let savedVPNRegionServerPrefix = defaults.string(forKey: kSavedVPNRegionServerPrefix) {
        return getVPNRegionForServerPrefix(serverPrefix: savedVPNRegionServerPrefix)
    }
    
    // get default savedRegion by locale
    let locale = NSLocale.autoupdatingCurrent
    if let regionCode = locale.regionCode {
        switch regionCode {
        case "US":
            if let timezone = TimeZone.autoupdatingCurrent.abbreviation() {
                if timezone == "EST" || timezone == "EDT" || timezone == "CST" {
                    return getVPNRegionForServerPrefix(serverPrefix: "us-east")
                }
            }
            else {
                return getVPNRegionForServerPrefix(serverPrefix: "us-west")
            }
        case "GB":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-london")
        case "IE":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-london")
        case "CA":
            return getVPNRegionForServerPrefix(serverPrefix: "canada")
        case "KO":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-seoul")
        case "ID", "SG", "MY", "PH", "TH", "TW", "VN":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-singapore")
        case "DE", "FR", "IT", "PT", "ES", "AT", "PL", "RU", "UA", "NG", "TR", "ZA":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-frankfurt")
        case "AU", "NZ":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-sydney")
        case "AE", "IN", "PK", "BD", "QA", "SA":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-mumbai")
        case "EG":
            return getVPNRegionForServerPrefix(serverPrefix: "eu-frankfurt")
        case "JP":
            return getVPNRegionForServerPrefix(serverPrefix: "ap-tokyo")
        case "BR", "CO", "VE", "AR":
            return getVPNRegionForServerPrefix(serverPrefix: "sa")
        default:
            return vpnRegions[0]
        }
    }
    return vpnRegions[0]
}

func setSavedVPNRegion(vpnRegion: VPNRegion) {
    defaults.set(vpnRegion.serverPrefix, forKey: kSavedVPNRegionServerPrefix)
}
