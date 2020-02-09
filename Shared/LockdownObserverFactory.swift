//
//  LockdownObserverFactory.swift
//  LockdownMac
//
//  Created by Johnny Lin on 1/17/20.
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import NetworkExtension
import NEKit
import os.log

class LDObserverFactory: ObserverFactory {

    override func getObserverForProxySocket(_ socket: ProxySocket) -> Observer<ProxySocketEvent>? {
        return LDProxySocketObserver()
    }

    class LDProxySocketObserver: Observer<ProxySocketEvent> {

        let blockedDomains = getAllBlockedDomains()

        override func signal(_ event: ProxySocketEvent) {

            switch event {
            case .receivedRequest(let session, let socket):

                if (!getUserWantsFirewallEnabled()) {
                    return
                }
                
                // Remove subdomain
                // TODO: Use a smarter method: https://github.com/Dashlane/SwiftDomainParser
                var baseHost = session.host
                let components = session.host.components(separatedBy: ".")
                if components.count > 2 {
                    baseHost = components.suffix(2).joined(separator: ".")
                }

                if (blockedDomains.contains(baseHost) || blockedDomains.contains(session.host)) {
                    incrementMetricsAndLog(host: session.host)
                    //os_log("blocking host: %{public}@", session.host)
                    socket.forceDisconnect()
                }

            default:
                break;
            }
        }

    }

}
