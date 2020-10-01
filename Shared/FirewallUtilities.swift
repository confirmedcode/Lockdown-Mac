//
//  FirewallUtilities.swift
//  LockdowniOS
//
//  Created by Johnny Lin on 8/4/19.
//  Copyright © 2019 Confirmed Inc. All rights reserved.
//

import Foundation
import NetworkExtension

// MARK: - Constants

let kLockdownBlockedDomains = "lockdown_domains"
let kUserBlockedDomains = "lockdown_domains_user"
let kLockdownWhitelistedDomains = "whitelisted_domains"
let kUserWhitelistedDomains = "whitelisted_domains_user"

// MARK: - data structures

struct IPRange : Codable {
    var subnetMask : String
    var enabled : Bool
    var IPv6 : Bool
    var subnetBits : Int
}

struct LockdownGroup : Codable {
    //format of a lockdown default
    //key: name
    //value: dictionary { iconUrl: String, enabled : Boolean, domains : [String : Enabled], IPRange: [IPAddress : [subnet : String, enabled : Boolean]}
    var version : Int
    var internalID: String
    var name: String
    var iconURL : String
    var enabled : Bool
    var domains : Dictionary<String, Bool>
    var ipRanges : Dictionary<String, IPRange>
}

struct LockdownDefaults : Codable {
    var lockdownDefaults : Dictionary<String, LockdownGroup>
}

// MARK: - Block Metrics & Block Log

let currentCalendar = Calendar.current
let blockLogDateFormatter : DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "h:mm a_"
    return formatter
}()

let kDayMetrics = "LockdownDayMetrics"
let kWeekMetrics = "LockdownWeekMetrics"
let kTotalMetrics = "LockdownTotalMetrics"

let kActiveDay = "LockdownActiveDay"
let kActiveWeek = "LockdownActiveWeek"

let kDayLogs = "LockdownDayLogs"
let kDayLogsMaxSize = 200;
let kDayLogsMaxReduction = 150;

func incrementMetricsAndLog(host: String) {
    
    let date = Date()
    
    // TOTAL - increment total
    defaults.set(Int(getTotalMetrics() + 1), forKey: kTotalMetrics)
    
    // WEEKLY - reset metrics on new week and increment week
    let currentWeek = currentCalendar.component(.weekOfYear, from: date)
    if currentWeek != defaults.integer(forKey: kActiveWeek) {
        defaults.set(0, forKey: kWeekMetrics)
        defaults.set(currentWeek, forKey: kActiveWeek)
    }
    defaults.set(Int(getWeekMetrics() + 1), forKey: kWeekMetrics)
    
    // DAY - reset metric on new day and increment day and log
    // set day metric
    let currentDay = currentCalendar.component(.day, from: date)
    if currentDay != defaults.integer(forKey: kActiveDay) {
        defaults.set(0, forKey: kDayMetrics)
        defaults.set(currentDay, forKey: kActiveDay)
        defaults.set([], forKey:kDayLogs);
    }
    defaults.set(Int(getDayMetrics() + 1), forKey: kDayMetrics)
    // set log
    let logString = blockLogDateFormatter.string(from: date) + host;
    // reduce log size if it's over the maxSize
    if var dayLog = defaults.array(forKey: kDayLogs) {
        if dayLog.count > kDayLogsMaxSize {
            dayLog = dayLog.suffix(kDayLogsMaxReduction);
        }
        dayLog.append(logString);
        defaults.set(dayLog, forKey: kDayLogs);
    }
    else {
        defaults.set([logString], forKey: kDayLogs);
    }
    
}

func getDayMetrics() -> Int {
    return defaults.integer(forKey: kDayMetrics)
}

func getDayMetricsString() -> String {
    return metricsToString(metric: getDayMetrics())
}

func getWeekMetrics() -> Int {
    return defaults.integer(forKey: kWeekMetrics)
}

func getWeekMetricsString() -> String {
    return metricsToString(metric: getWeekMetrics())
}

func getTotalMetrics() -> Int {
    return defaults.integer(forKey: kTotalMetrics)
}

func getTotalMetricsString() -> String {
    return metricsToString(metric: getTotalMetrics())
}

func metricsToString(metric : Int) -> String {
    if metric < 1000 {
        return "\(metric)"
    }
    else if metric < 1000000 {
        return "\(Int(metric / 1000))k"
    }
    else {
        return "\(Int(metric / 1000000))m"
    }
}

// MARK: - Blocked domains and lists


func setupFirewallDefaultBlockLists() {
    var lockdownBlockedDomains = getLockdownBlockedDomains()
    
    let snapchatAnalytics = LockdownGroup.init(
        version: 26,
        internalID: "snapchatAnalytics",
        name: "Snapchat Trackers",
        iconURL: "snapchat_analytics_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "snapchat_analytics"),
        ipRanges: [:])
    
    let gameAds = LockdownGroup.init(
        version: 27,
        internalID: "gameAds",
        name: "Game Marketing",
        iconURL: "game_ads_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "game_ads"),
        ipRanges: [:])
    
    let clickbait = LockdownGroup.init(
        version: 26,
        internalID: "clickbait",
        name: "Clickbait",
        iconURL: "clickbait_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "clickbait"),
        ipRanges: [:])
    
    let crypto = LockdownGroup.init(
        version: 26,
        internalID: "crypto_mining",
        name: "Crypto Mining",
        iconURL: "crypto_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "crypto_mining"),
        ipRanges: [:])
    
    let emailOpens = LockdownGroup.init(
        version: 29,
        internalID: "email_opens",
        name: "Email Trackers",
        iconURL: "email_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "email_opens"),
        ipRanges: [:])
    
    let facebookInc = LockdownGroup.init(
        version: 30,
        internalID: "facebook_inc",
        name: "Facebook & WhatsApp",
        iconURL: "facebook_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "facebook_inc"),
        ipRanges: [:])
    
    let facebookSDK = LockdownGroup.init(
        version: 26,
        internalID: "facebook_sdk",
        name: "Facebook Trackers",
        iconURL: "facebook_white_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "facebook_sdk"),
        ipRanges: [:])
    
    let marketingScripts = LockdownGroup.init(
        version: 29,
        internalID: "marketing_scripts",
        name: "Marketing Trackers",
        iconURL: "marketing_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "marketing"),
        ipRanges: [:])
    
    let marketingScriptsII = LockdownGroup.init(
        version: 27,
        internalID: "marketing_beta_scripts",
        name: "Marketing Trackers II",
        iconURL: "marketing_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "marketing_beta"),
        ipRanges: [:])

    let ransomware = LockdownGroup.init(
        version: 26,
        internalID: "ransomware",
        name: "Ransomware",
        iconURL: "ransomware_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "ransomware"),
        ipRanges: [:])

    let googleShoppingAds = LockdownGroup.init(
        version: 34,
        internalID: "google_shopping_ads",
        name: "Google Shopping",
        iconURL: "google_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "google_shopping_ads"),
        ipRanges: [:])
    
    let dataTrackers = LockdownGroup.init(
        version: 30,
        internalID: "data_trackers",
        name: "Data Trackers",
        iconURL: "user_data_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "data_trackers"),
        ipRanges: [:])
    
    let generalAds = LockdownGroup.init(
        version: 38,
        internalID: "general_ads",
        name: "General Marketing",
        iconURL: "ads_icon",
        enabled: true,
        domains: getDomainBlockList(filename: "general_ads"),
        ipRanges: [:])
    
    let reporting = LockdownGroup.init(
        version: 27,
        internalID: "reporting",
        name: "Reporting",
        iconURL: "reporting_icon",
        enabled: false,
        domains: getDomainBlockList(filename: "reporting"),
        ipRanges: [:])
    
    let defaultLockdownSettings = [snapchatAnalytics,
                                   gameAds,
                                   clickbait,
                                   crypto,
                                   emailOpens,
                                   facebookInc,
                                   facebookSDK,
                                   marketingScripts,
                                   marketingScriptsII,
                                   ransomware,
                                   googleShoppingAds,
                                   dataTrackers,
                                   generalAds,
                                   reporting];
    
    for var defaultGroup in defaultLockdownSettings {
        if let current = lockdownBlockedDomains.lockdownDefaults[defaultGroup.internalID], current.version >= defaultGroup.version {
            // no version change, no action needed
        } else {
            if let current = lockdownBlockedDomains.lockdownDefaults[defaultGroup.internalID] {
                defaultGroup.enabled = current.enabled // don't replace whether it was disabled
            }
            lockdownBlockedDomains.lockdownDefaults[defaultGroup.internalID] = defaultGroup
        }
    }
    
    for (_, value) in lockdownBlockedDomains.lockdownDefaults {
        if lockdownBlockedDomains.lockdownDefaults[value.name] != nil {
            lockdownBlockedDomains.lockdownDefaults.removeValue(forKey: value.name)
        }
    }
    
    defaults.set(try? PropertyListEncoder().encode(lockdownBlockedDomains), forKey: kLockdownBlockedDomains)
}

func getDomainBlockList(filename: String) -> Dictionary<String, Bool> {
    var domains = [String : Bool]()
    guard let path = Bundle.main.path(forResource: filename, ofType: "txt") else {
        return domains
    }
    do {
        let content = try String(contentsOfFile:path, encoding: String.Encoding.utf8)
        let lines = content.components(separatedBy: "\n")
        for line in lines {
            if (line.trimmingCharacters(in: CharacterSet.whitespaces) != "" && !line.starts(with: "#")) {
                domains[line] = true;
            }
        }
    } catch _ as NSError {
    }
    return domains
}

func getAllBlockedDomains() -> Array<String> {
    let lockdownBlockedDomains = getLockdownBlockedDomains()
    let userBlockedDomains = getUserBlockedDomains()
    
    var allBlockedDomains = Array<String>()
    for (_, ldValue) in lockdownBlockedDomains.lockdownDefaults {
        if ldValue.enabled {
            for (key, value) in ldValue.domains {
                if value {
                    allBlockedDomains.append(key)
                }
            }
        }
    }
    for (key, value) in userBlockedDomains {
        if let v = value as? Bool, v == true {
            allBlockedDomains.append(key)
        }
    }
    
    return allBlockedDomains
}

// MARK: - User blocked domains

func getUserBlockedDomains() -> Dictionary<String, Any> {
    if let domains = defaults.dictionary(forKey: kUserBlockedDomains) {
        return domains
    }
    return Dictionary()
}

func addUserBlockedDomain(domain: String) {
    var domains = getUserBlockedDomains()
    domains[domain] = true
    defaults.set(domains, forKey: kUserBlockedDomains)
}

func setUserBlockedDomain(domain: String, enabled: Bool) {
    var domains = getUserBlockedDomains()
    domains[domain] = enabled
    defaults.set(domains, forKey: kUserBlockedDomains)
}

func deleteUserBlockedDomain(domain: String) {
    var domains = getUserBlockedDomains()
    domains[domain] = nil
    defaults.set(domains, forKey: kUserBlockedDomains)
}

// MARK: - Lockdown blocked domains

func getLockdownBlockedDomains() -> LockdownDefaults {
    guard let lockdownDefaultsData = defaults.object(forKey: kLockdownBlockedDomains) as? Data else {
        return LockdownDefaults(lockdownDefaults: [:])
    }
    guard let lockdownDefaults = try? PropertyListDecoder().decode(LockdownDefaults.self, from: lockdownDefaultsData) else {
        return LockdownDefaults(lockdownDefaults: [:])
    }
    return lockdownDefaults
}

struct BlockList {
    let name: String
    var lockdownGroup: LockdownGroup
}

func getLockdownBlockLists() -> [BlockList] {
    var blockLists: [BlockList] = []
    for (name, group) in getLockdownBlockedDomains().lockdownDefaults {
        blockLists.append(BlockList(name: name, lockdownGroup: group))
    }
    let blockListsSorted = blockLists.sorted { $0.name < $1.name }
    return blockListsSorted
}

struct UserBlockedDomain {
    var domain: String
    var enabled: Bool
}

func getUserBlockedDomainsArray() -> [UserBlockedDomain] {
    var blockedDomains: [UserBlockedDomain] = []
    if let bd = defaults.dictionary(forKey: kUserBlockedDomains) {
        for (domain, blocked) in bd {
            if let b = blocked as? Bool {
                blockedDomains.append(UserBlockedDomain(domain: domain, enabled: b))
            }
        }
    }
    let blockedDomainsSorted = blockedDomains.sorted { $0.domain < $1.domain }
    return blockedDomainsSorted
}

// MARK: - Whitelist Getters

func getLockdownWhitelistedDomains() -> Dictionary<String, Any> {
    if let domains = defaults.dictionary(forKey: kLockdownWhitelistedDomains) {
        return domains
    }
    return Dictionary()
}

func getUserWhitelistedDomains() -> Dictionary<String, Any> {
    if let domains = defaults.dictionary(forKey: kUserWhitelistedDomains) {
        return domains
    }
    return Dictionary()
}

func getAllWhitelistedDomains() -> [String] {
    var toReturn:[String] = [];
    for d in getLockdownWhitelistedDomains() {
        if (d.value as? Bool) == true {
            toReturn.append(d.key)
        }
    }
    for d in getUserWhitelistedDomains() {
        if (d.value as? Bool) == true {
            toReturn.append(d.key)
        }
    }
    return toReturn
}

struct WhitelistedDomain {
    var domain: String
    var enabled: Bool
}

func getLockdownWhitelistedDomainsArray() -> [WhitelistedDomain] {
    return getWhitelistedDomainsArray(key: kLockdownWhitelistedDomains)
}

func getUserWhitelistedDomainsArray() -> [WhitelistedDomain] {
    return getWhitelistedDomainsArray(key: kUserWhitelistedDomains)
}

func getWhitelistedDomainsArray(key: String) -> [WhitelistedDomain] {
    var whitelistedDomains: [WhitelistedDomain] = []
    if let wd = defaults.dictionary(forKey: key) {
        for (domain, whitelisted) in wd {
            if let w = whitelisted as? Bool {
                whitelistedDomains.append(WhitelistedDomain(domain: domain, enabled: w))
            }
        }
    }
    let whitelistedDomainsSorted = whitelistedDomains.sorted { $0.domain < $1.domain }
    return whitelistedDomainsSorted
}

// MARK: - Whitelist Setters

func setLockdownWhitelistedDomain(domain: String, enabled: Bool) {
    var domains = getLockdownWhitelistedDomains()
    domains[domain] = enabled
    defaults.set(domains, forKey: kLockdownWhitelistedDomains)
}

func setUserWhitelistedDomain(domain: String, enabled: Bool) {
    var domains = getUserWhitelistedDomains()
    domains[domain] = enabled
    defaults.set(domains, forKey: kUserWhitelistedDomains)
}

func deleteUserWhitelistedDomain(domain: String) {
    var domains = getUserWhitelistedDomains()
    domains[domain] = nil
    defaults.set(domains, forKey: kUserWhitelistedDomains)
}

func addUserWhitelistedDomain(domain: String) {
    var domains = getUserWhitelistedDomains()
    domains[domain] = true
    defaults.set(domains, forKey: kUserWhitelistedDomains)
}

func setupLockdownWhitelistedDomains() {
    addLockdownWhitelistedDomainIfNotExists(domain: "amazon.com") // This domain is not used for tracking (the tracker amazon-adsystem.com is blocked), but it does sometimes stop Secure Tunnel VPN users from viewing Amazon reviews. Users may un-whitelist this if they wish.
    addLockdownWhitelistedDomainIfNotExists(domain: "api.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "apple.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "apple.news")
    addLockdownWhitelistedDomainIfNotExists(domain: "apple-cloudkit.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "archive.is")
    addLockdownWhitelistedDomainIfNotExists(domain: "bamgrid.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "cdn-apple.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "coinbase.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "confirmedvpn.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "creditkarma.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "digicert.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "disney-plus.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "disneyplus.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "firstdata.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "go.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hbc.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hbo.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hbomax.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "houzz.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "hulu.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "huluim.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "icloud-content.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "icloud.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "kroger.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "letsencrypt.org")
    addLockdownWhitelistedDomainIfNotExists(domain: "lowes.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "m.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "marcopolo.me")
    addLockdownWhitelistedDomainIfNotExists(domain: "mobile.twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "mzstatic.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "netflix.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "nflxvideo.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "quibi.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "saks.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "saksfifthavenue.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "skype.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "slickdeals.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "southwest.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "t.co")
    addLockdownWhitelistedDomainIfNotExists(domain: "tapbots.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "tapbots.net")
    addLockdownWhitelistedDomainIfNotExists(domain: "twimg.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "twitter.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "usbank.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "verisign.com")
    addLockdownWhitelistedDomainIfNotExists(domain: "vudu.com")
    
    setAsFalseLockdownWhitelistedDomain(domain: "nianticlabs.com")
}

func addLockdownWhitelistedDomainIfNotExists(domain: String) {
    // only add it if it doesn't exist, and add it as true
    var domains = getLockdownWhitelistedDomains()
    if domains[domain] == nil {
        domains[domain] = NSNumber(value: true)
    }
    defaults.set(domains, forKey: kLockdownWhitelistedDomains)
}

func setAsFalseLockdownWhitelistedDomain(domain: String) {
    var domains = getLockdownWhitelistedDomains()
    domains[domain] = NSNumber(value: false)
    defaults.set(domains, forKey: kLockdownWhitelistedDomains)
}
