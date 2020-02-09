//
//  SetRegionView.swift
//  Lockdown
//
//  Created by Johnny Lin on 1/22/20.
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import SwiftUI
import CocoaLumberjackSwift

struct SetRegionView: View {
    
    @Environment(\.presentationMode) var presentationMode
    
    @State private var newDomain: String = ""
    
    var blockLists: [BlockList] = getLockdownBlockLists()
    @State var customBlockedDomains: [CustomBlockedDomain] = getCustomBlockedDomains()
    
    var body: some View {
        
        VStack(spacing: 0.0) {
            Section(header:
                VStack {
                    Text("Set Region")
                        .font(cFontTitle)
                        .padding(.vertical, 10)
                    Text("For fastest speeds, choose a region closest to you. You can also anonymize your IP through other regions.")
                        .font(cFontRegularSmall)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 12)
                }
            )
            {
                VStack(spacing: 0) {
                    List (vpnRegions, id: \.serverPrefix) { vpnRegion in
                        SetRegionRow(vpnRegion: vpnRegion, regionTapped: {
                            self.presentationMode.wrappedValue.dismiss()
                        })
                    }
                }
            }
        }
        .frame(width: viewWidth, height: viewHeight * 3/5)
        
    }
    
}

struct SetRegionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            SetRegionView()
        }
    }
}

struct SetRegionRow: View {
    
    @State private var showDomains = false
    @State var vpnRegion: VPNRegion
    
    var regionTapped: () -> Void
    init(vpnRegion: VPNRegion, regionTapped: @escaping () -> Void) {
        _vpnRegion = State(initialValue: vpnRegion)
        self.regionTapped = regionTapped
    }
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0.0) {
            Button(action: {
                DDLogInfo("set saved region")
                setSavedVPNRegion(vpnRegion: self.vpnRegion)
                if VPNController.shared.status() == .connected {
                    VPNController.shared.restart()
                }
                self.regionTapped()
            }) {
                HStack {
                    Text(vpnRegion.regionFlagEmoji)
                        .font(Font.system(size: 35))
                        .padding(.leading, 15)
                    Text(vpnRegion.regionDisplayName)
                        .font(cFontTitle)
                        .frame(minWidth: 0, maxWidth: .infinity)
                    Text("􀆅")
                        .font(sfProRoundedBold20)
                        .foregroundColor(Color.confirmedBlue)
                        .opacity(getSavedVPNRegion().serverPrefix == vpnRegion.serverPrefix ? 1 : 0)
                        .padding(.trailing, 15)
                }
                .padding(.bottom, 8)
            }
            .buttonStyle(BlankButtonStyle())
            .frame(minWidth: 0, maxWidth: viewWidth, minHeight: 40, maxHeight: 40)
            Divider()
        }
        .frame(minWidth: 0, maxWidth: viewWidth)
    }
    
}

#if DEBUG
struct SetRegionRow_Previews: PreviewProvider {
    static var previews: some View {
        SetRegionRow(vpnRegion: vpnRegions[0], regionTapped: {
            DDLogInfo("region tapped")
        })
    }
}
#endif
