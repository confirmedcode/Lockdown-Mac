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

class PacketTunnelProvider: NEPacketTunnelProvider {
    
    let proxyServerPort: UInt16 = 9093
    let proxyServerAddress = "127.0.0.1"
    
    //MARK: - OVERRIDES
    
    override func startTunnel(options: [String : NSObject]?, completionHandler: @escaping (Error?) -> Void) {
        
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
                proxyServerPTP = GCDHTTPProxyServer(address: IPAddress(fromString: self.proxyServerAddress), port: Port(port: self.proxyServerPort))
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

