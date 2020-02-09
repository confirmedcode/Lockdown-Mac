//
//  BlockLogView.swift
//  Lockdown
//
//  Created by Johnny Lin on 12/6/19.
//  Copyright © 2019 Confirmed, Inc. All rights reserved.
//

import SwiftUI

struct BlockLogView: View {
    
    @State var blockLogs: [BlockLog] = getBlockLogs()
    
    let timer = Timer.publish(every: 5, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0.0) {
            Section(header:
                VStack {
                    Text("Today's Block Log")
                        .font(cFontTitle)
                        .padding(.vertical, 10)
                    Text("The connections blocked by Lockdown since midnight today are shown below. As per our Privacy Policy, all the blocking is done on-device and never transmitted to any servers for processing.")
                        .font(cFontRegularSmall)
                        .padding(.bottom, 10)
                        .padding(.horizontal, 12)
                }
            )
            {
                VStack(spacing: 0) {
                    List (blockLogs, id: \.id) { blockLog in
                        BlockLogRow(blockLog: blockLog)
                    }
                }
            }
        }
        .frame(width: viewWidth, height: viewHeight * 2/3)
    }
    
}

#if DEBUG
struct BlockLogView_Previews: PreviewProvider {
    static var previews: some View {
        BlockLogView()
    }
}
#endif

struct BlockLog: Identifiable {
    var id: String = UUID().uuidString
    let time: String
    let host: String
    
    init(time: String, host: String) {
        self.time = time
        self.host = host
    }
}

func getBlockLogs() -> [BlockLog] {
    var blockLogs:[BlockLog] = []
    if var dayLogs = defaults.array(forKey: kDayLogs) as? [String] {
        dayLogs = dayLogs.reversed()
        for log in dayLogs {
            let sp = log.components(separatedBy: "_")
            if sp.count == 2 {
                blockLogs.append(BlockLog(time: sp[0], host: sp[1]))
            }
        }
    }
    return blockLogs
}

struct BlockLogRow: View {
    
    @State var blockLog: BlockLog
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0.0) {
            HStack {
                Text(blockLog.time)
                .font(cFontSmall)
                .multilineTextAlignment(.leading)
                    .padding(.leading, 8.0)
                .padding(.vertical, 0)
                    .padding(.top, 2.5)
                .foregroundColor(Color.secondary)
                .frame(maxHeight: .infinity)
                Text(blockLog.host)
                .font(cFontRegular)
                .multilineTextAlignment(.leading)
                    .padding(.leading, 8.0)
                .padding(.vertical, 0)
                .frame(maxHeight: .infinity)
            }
            .frame(maxHeight: 20)
            .padding(.bottom, 7)
        }
    }
    
}

#if DEBUG
struct BlockLogRow_Previews: PreviewProvider {
    static var previews: some View {
        BlockLogRow(blockLog: BlockLog(time: "8:30 PM", host: "blockme.example.com"))
    }
}
#endif
