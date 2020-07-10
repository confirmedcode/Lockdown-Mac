//
//  VPNController.swift
//  Lockdown
//
//  Created by Johnny Lin on 1/15/20.
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import Foundation
import Cocoa
import NetworkExtension
import NEKit
import CocoaLumberjackSwift

let kVPNLocalizedDescription = "Lockdown VPN"
let kVPNP12Password = "rdar://12503102" // macOS requires a password here

var proxyServer: GCDHTTPProxyServer!
let vpnProxyAddress = "127.0.0.1"
var vpnProxyPort: UInt16 = 9091
let vpnPortBuffer: UInt16 = 34000
let vpnPortBufferBackup: UInt16 = 36000

class VPNController: NSObject {
    
    static let shared = VPNController()
    
    var manager = NEVPNManager.shared()
    
    private override init() {
        super.init()
        
        if let uid = getUid() {
            DDLogInfo("VPNPORT: Trying ports")
            if isPortOpen(port: UInt16(uid + vpnPortBuffer), address: vpnProxyAddress).0 == true {
                DDLogInfo("VPNPORT: \(UInt16(uid + vpnPortBuffer)) not used, using it")
                vpnProxyPort = UInt16(uid + vpnPortBuffer)
            }
            else if isPortOpen(port: UInt16(uid + vpnPortBufferBackup), address: vpnProxyAddress).0 == true {
                DDLogInfo("VPNPORT: Normal buffer port failed, trying backup \(UInt16(uid + vpnPortBufferBackup))")
                DDLogInfo("VPNPORT: \(UInt16(uid + vpnPortBufferBackup)) backup not used, using it")
                vpnProxyPort = UInt16(uid + vpnPortBufferBackup)
            }
            else {
                DDLogInfo("VPNPORT: Unable to get uid, using default \(vpnProxyPort)")
            }
        }
        else {
            DDLogInfo("VPNPORT: Unable to get uid, using default \(vpnProxyPort)")
        }
        
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in })
    }
    
    func status() -> NEVPNStatus {
        return manager.connection.status
    }
    
    func deactivateIfEnabled(completion: @escaping (_ error: Error?) -> Void = {_ in }) {
        if (VPNController.shared.status() == .connected) {
            VPNController.shared.setEnabled(false, completion: { _ in
                completion(nil)
            })
        }
        else {
            completion(nil)
        }
    }
    
    func restart() {
        // Don't let this affect userWantsVPNOn/Off config
        VPNController.shared.setEnabled(false, completion: {
            error in
            // TODO: Handle the error
            VPNController.shared.setEnabled(true)
        })
    }
 
    func setEnabled(_ enabled: Bool, completion: @escaping (_ error: Error?) -> Void = {_ in }) {
        DDLogInfo("VPNController set enabled: \(enabled)")
        setUserWantsVPNEnabled(enabled)
        if (enabled) {
            activateProxy()
            setUpAndEnableVPN { error in
                completion(error)
            }
        }
        else {
            self.deactivateProxy()
            manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
                self.manager.isEnabled = false
                self.manager.isOnDemandEnabled = false
                self.manager.onDemandRules = []
                self.manager.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                    // TODO: will this ever error?
                    completion(error)
                })
            })
        }
    }
    
    private func setUpAndEnableVPN(completion: @escaping (_ error: Error?) -> Void) {
        guard let vpnCredentials = getVPNCredentials() else {
            // TODO: handle error
            return completion("No VPN credentials found while enabling VPN")
        }
        
        // Install certificate if it isn't installed
        DDLogInfo("Checking for installed certificate")
        var installedCertificate = getInstalledCertificate(localIdentifier: vpnCredentials.id)
        if installedCertificate == nil {
            do {
                try self.installCertificate(p12Encoded: vpnCredentials.keyBase64)
            }
            catch {
                return completion("Error installing certificate \(error)")
            }
            installedCertificate = getInstalledCertificate(localIdentifier: vpnCredentials.id)
            if (installedCertificate == nil) {
                return completion("Error getting certificate after installing")
            }
        }
        
        // Use certificate to install the VPN
        let manager = NEVPNManager.shared()
        manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
            DDLogInfo("Loading Error \(String(describing: error))")

            let p = NEVPNProtocolIKEv2()
            
            p.serverAddress = getSavedVPNRegion().serverPrefix + vpnSourceID + "." + vpnDomain
            p.remoteIdentifier = vpnRemoteIdentifier
            p.serverCertificateIssuerCommonName = vpnRemoteIdentifier
            p.localIdentifier = vpnCredentials.id
            
            p.certificateType = NEVPNIKEv2CertificateType.ECDSA256
            p.authenticationMethod = NEVPNIKEAuthenticationMethod.certificate
            p.useExtendedAuthentication = false
            p.disconnectOnSleep = false
            p.enablePFS = true
            
            p.ikeSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES128GCM
            p.ikeSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group19
            p.ikeSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA512
            p.ikeSecurityAssociationParameters.lifetimeMinutes = 1440
            
            p.childSecurityAssociationParameters.encryptionAlgorithm = NEVPNIKEv2EncryptionAlgorithm.algorithmAES128GCM
            p.childSecurityAssociationParameters.diffieHellmanGroup = NEVPNIKEv2DiffieHellmanGroup.group19
            p.childSecurityAssociationParameters.integrityAlgorithm = NEVPNIKEv2IntegrityAlgorithm.SHA512
            p.childSecurityAssociationParameters.lifetimeMinutes = 1440
            
            p.deadPeerDetectionRate = NEVPNIKEv2DeadPeerDetectionRate.high
            p.disableRedirect = true

            var ref: CFData?
            _ = SecKeychainItemCreatePersistentReference(installedCertificate!, &ref)

            p.identityReference = (ref as Data?)!
            p.disconnectOnSleep = false

            if (getUserWantsFirewallEnabled() ) {
                DDLogInfo("using vpn proxy port: \(vpnProxyPort)")
                let proxy = NEProxySettings()
                proxy.httpEnabled = true
                proxy.httpServer = NEProxyServer(address: vpnProxyAddress, port: Int(vpnProxyPort))
                proxy.httpsEnabled = true
                proxy.httpsServer = NEProxyServer(address: vpnProxyAddress, port: Int(vpnProxyPort))
                proxy.excludeSimpleHostnames = false
                proxy.matchDomains = [""]
                p.proxySettings = proxy
            }

            manager.protocolConfiguration = p
            manager.isEnabled = true
            manager.isOnDemandEnabled = true
            
            var onDemandRules:[NEOnDemandRule] = [];
            let whitelist = getAllWhitelistedDomains()
            if whitelist.count > 0 {
                let disconnectDomainRule = NEEvaluateConnectionRule(matchDomains: getAllWhitelistedDomains(), andAction: .neverConnect)
                let disconnectRule = NEOnDemandRuleEvaluateConnection()
                disconnectRule.connectionRules = [disconnectDomainRule]
                onDemandRules.append(disconnectRule)
            }
            let connectRule = NEOnDemandRuleConnect()
            connectRule.interfaceTypeMatch = .any
            onDemandRules.append(connectRule)
            manager.onDemandRules = onDemandRules

            DDLogInfo("VPN status before loading: \(self.manager.connection.status)")
            self.manager.localizedDescription! = kVPNLocalizedDescription
            self.manager.saveToPreferences(completionHandler: {(_ error: Error?) -> Void in
                if let e = error {
                    DDLogError("Saving VPN Error \(e)")
                    if ((e as NSError).code == 4) { // if config is stale, probably multithreading bug
                        DDLogError("Stale config, trying again")
                        self.setUpAndEnableVPN(completion: { error in
                            completion(error)
                        })
                    }
                    else {
                        completion(e)
                    }
                }
                else {
                    // refresh the reference then force start the VPN
                    manager.loadFromPreferences(completionHandler: {(_ error: Error?) -> Void in
                        if let e = error {
                            DDLogError("Reloading manager error: \(e)")
                            completion(e)
                        }
                        else {
                            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                                do {
                                    try manager.connection.startVPNTunnel()
                                    completion(nil)
                                }
                                catch {
                                    DDLogError("Activating VPN Error \(error)")
                                    completion(error) // TODO: Better error handling
                                }
                            }
                        }
                    })
                }
            })
        })
        
    }
    
    private func activateProxy() {
        DDLogInfo("activating proxy")
        if (getUserWantsFirewallEnabled()) {
            DDLogInfo("activating proxy by deactivating it first if it exists")
            deactivateProxy()
            DDLogInfo("activate vpn proxy port: \(vpnProxyPort)")
            proxyServer = GCDHTTPProxyServer(address: IPAddress(fromString: vpnProxyAddress), port: Port(port: vpnProxyPort))
            do {
                try proxyServer.start()
                ObserverFactory.currentFactory = LDObserverFactory()
                DDLogInfo("proxy server started")
            }
            catch {
                DDLogInfo("Error starting proxy server \(error)")
            }
        }
        else {
            DDLogInfo("not activating proxy bc user doesn't want firewall")
        }
    }
    
    private func deactivateProxy() {
        DDLogInfo("deactivating proxy")
        if (proxyServer != nil) {
            proxyServer.stop()
            proxyServer = nil
            DDLogInfo("deactivated proxy")
        }
        ObserverFactory.currentFactory = nil
    }

    private func installCertificate(p12Encoded: String) throws {
        var p12Decoded = Data(base64Encoded: p12Encoded)
        p12Decoded = try addPasswordFromP12(rootCertData: p12Decoded!)

        // add certificate into keychain with a password because macOS requires it (rdar://12503102)
        var clientCertificates: CFArray? = nil
        let certOptions: CFDictionary = [kSecImportExportPassphrase: kVPNP12Password] as CFDictionary
        let importResult: OSStatus = SecPKCS12Import(p12Decoded! as CFData, certOptions, &clientCertificates)

        switch importResult {
            case noErr:
                DDLogInfo("noErr: Success \(String(describing: clientCertificates))")
            case errSecAuthFailed:
                throw "errSecAuthFailed: Authorization/Authentication failed. \(String(describing: clientCertificates))"
            default:
                throw "Unspecified OSStatus error: \(importResult)"
        }
        
        // get the certificate from keychain
        let getquery: [String: Any] = [kSecClass as String: kSecClassCertificate,
                                       kSecAttrLabel as String: vpnRemoteIdentifier,
                                       kSecReturnRef as String: kCFBooleanTrue]
        var item: CFTypeRef?
        var status = SecItemCopyMatching(getquery as CFDictionary, &item)
        guard status == errSecSuccess else {
            throw "Error with copying cert into item \(status)"
        }
        DDLogInfo("Successfully copied cert from keychain")

        // trust that certificate
        let certificate = item as! SecCertificate
        status = SecTrustSettingsSetTrustSettings(certificate, SecTrustSettingsDomain.user, nil)
        guard status == errSecSuccess else {
            throw "Error with trusting root cert \(status)"
        }
        DDLogInfo("Successfully trusted root cert")
    }

    private func getInstalledCertificate(localIdentifier: String) -> SecKeychainItem? {
        let localID = localIdentifier
        let getquery: [String: Any] = [kSecClass as String: kSecClassCertificate,
                                       kSecAttrLabel as String: localID,
                                       kSecReturnRef as String: kCFBooleanTrue]
        var item: CFTypeRef?
        let status = SecItemCopyMatching(getquery as CFDictionary, &item)
        if status != errSecSuccess {
            DDLogInfo("Error getting certificate with ID \(status)")
            return nil
        }
        else {
            DDLogInfo("Success getting certificate with ID")
            return (item as! SecKeychainItem)
        }
    }
    
    private func addPasswordFromP12(rootCertData : Data) throws -> Data {
        guard let userDomainDir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            throw "Error getting user domain directory"
        }
        let appSupportDirectory = userDomainDir.appendingPathComponent("com.confirmed.lockdownMac")
        let appSupportPath = userDomainDir.appendingPathComponent("com.confirmed.lockdownMac/serverCert.p12")
        let tempAppSupportPath = userDomainDir.appendingPathComponent("com.confirmed.lockdownMac/temp.pem")
        let outputAppSupportPath = userDomainDir.appendingPathComponent("com.confirmed.lockdownMac/severCertProtected.p12")
        
        do {
            try FileManager.default.createDirectory(at: appSupportDirectory, withIntermediateDirectories: true, attributes: nil)
        } catch {
            throw "Error creating directory \(appSupportDirectory): \(error)"
        }
        
        do {
            try rootCertData.write(to: appSupportPath)
        } catch {
            throw "Error writing rootCertData to \(appSupportPath): \(error)"
        }
        
        shell(launchPath: "/usr/bin/openssl", arguments: ["pkcs12", "-in", appSupportPath.path, "-out", tempAppSupportPath.path, "-passin", "pass:", "-passout", "pass:" + kVPNP12Password])
        sleep(2)
        shell(launchPath: "/usr/bin/openssl", arguments: ["pkcs12", "-export", "-in", tempAppSupportPath.path, "-out", outputAppSupportPath.path, "-passin", "pass:" + kVPNP12Password, "-passout", "pass:" + kVPNP12Password])
        
        do {
            let passwordCertData = try Data(contentsOf: outputAppSupportPath)

            // remove all 3 files - no need to throw if error
            try? FileManager.default.removeItem(at: appSupportPath)
            try? FileManager.default.removeItem(at: tempAppSupportPath)
            try? FileManager.default.removeItem(at: outputAppSupportPath)

            return passwordCertData
        } catch {
            throw "Error getting final passwordCertData at \(outputAppSupportPath): \(error)"
        }
    }
    
    private func shell(launchPath path: String, arguments args: [String]) {
        DDLogInfo("Run shell command \(path) with args \(args)")
        
        let task = Process()
        task.launchPath = path
        task.arguments = args
        
        let pipe = Pipe()
        task.standardOutput = pipe
        task.standardError = pipe
        task.launch()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        task.waitUntilExit()
        
        if let o = output {
            DDLogInfo("Shell Result: \(o)")
        }
        else {
            DDLogInfo("No shell result")
        }
    }
    
}

