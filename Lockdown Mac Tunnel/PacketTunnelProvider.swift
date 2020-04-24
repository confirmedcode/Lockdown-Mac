//
//  PacketTunnelProvider.swift
//  ConfirmedTunnel
//
//  Copyright © 2018 Confirmed, Inc.. All rights reserved.
//

import NetworkExtension
import NEKit
import os.log
import CocoaLumberjackSwift

var proxyServerPTP: GCDHTTPProxyServer!
let proxyServerAddress = "127.0.0.1"
var proxyServerPort: UInt16 = 9093
let proxyPortBuffer: UInt16 = 6000
let proxyPortBufferBackup: UInt16 = 7000

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    //MARK: - OVERRIDES
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
        if let uid = getUid() {
            DDLogInfo("PROXYPORT: Trying ports")
            if isPortOpen(port: UInt16(uid + proxyPortBuffer), address: proxyServerAddress).0 == true {
                DDLogInfo("PROXYPORT: \(UInt16(uid + proxyPortBuffer)) not used, using it")
                proxyServerPort = UInt16(uid + proxyPortBuffer)
            }
            else if isPortOpen(port: UInt16(uid + proxyPortBufferBackup), address: proxyServerAddress).0 == true {
                DDLogInfo("PROXYPORT: Normal buffer port failed, trying backup \(UInt16(uid + proxyPortBufferBackup))")
                DDLogInfo("PROXYPORT: \(UInt16(uid + proxyPortBufferBackup)) backup not used, using it")
                proxyServerPort = UInt16(uid + proxyPortBufferBackup)
            }
            else {
                DDLogInfo("PROXYPORT: Unable to get uid, using default \(proxyServerPort)")
            }
        }
        else {
            DDLogInfo("PROXYPORT: Unable to get uid, using default \(proxyServerPort)")
        }
        
        deactivateProxy()
        
        ObserverFactory.currentFactory = LDObserverFactory()
        
        self.setTunnelNetworkSettings(makeSettings(port: proxyServerPort), completionHandler: { error in
            if let e = error {
                os_log("Error setting Tunnel Network Settings %@", e.localizedDescription)
                self.cancelTunnelWithError(e)
                completionHandler(e)
            }
            else {
                os_log("Success setting Tunnel Network Settings")
                proxyServerPTP = GCDHTTPProxyServer(address: IPAddress(fromString: proxyServerAddress), port: Port(port: proxyServerPort))
                os_log("Starting proxy")
                do {
                    try proxyServerPTP.start()
                    completionHandler(nil)
                }
                catch {
                    os_log("Error starting proxy server", error.localizedDescription)
                    self.cancelTunnelWithError(error)
                    completionHandler(error)
                }
            }
        })
    }
    
    func makeSettings(port: UInt16) -> NEPacketTunnelNetworkSettings {
        let settings = NEPacketTunnelNetworkSettings(tunnelRemoteAddress: proxyServerAddress)
        settings.mtu = NSNumber(value: 1500)
        
        let proxySettings = NEProxySettings()
        proxySettings.httpEnabled = true;
        proxySettings.httpServer = NEProxyServer(address: proxyServerAddress, port: Int(port))
        proxySettings.httpsEnabled = true;
        proxySettings.httpsServer = NEProxyServer(address: proxyServerAddress, port: Int(port))
        proxySettings.excludeSimpleHostnames = false;
        proxySettings.exceptionList = []
        proxySettings.matchDomains = [""]

        settings.proxySettings = proxySettings
        
        return settings
    }
    
    func deactivateProxy() {
        if (proxyServerPTP != nil) {
            DDLogInfo("stopping proxy")
            proxyServerPTP.stop()
            proxyServerPTP = nil
        }
        ObserverFactory.currentFactory = nil
    }
    
    override func stopTunnel(with reason: NEProviderStopReason, completionHandler: @escaping () -> Void) {
        DDLogInfo("LockdownTunnel: stopping for reason: \(reason)")
        deactivateProxy()
        
        completionHandler()
        exit(EXIT_SUCCESS)
    }
    
}

