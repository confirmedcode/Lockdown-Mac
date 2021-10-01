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
    
    let timer = Timer.publish(every: 20, on: .main, in: .common).autoconnect()
    let kvo = defaults.publisher(for: \.LockdownDayLogs, options: [])
        .debounce(for: 0.3, scheduler: RunLoop.main)
    
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
                .onReceive(kvo) { _ in
                    self.blockLogs = getBlockLogs()
                }
                .onReceive(timer) { _ in
                    self.blockLogs = getBlockLogs()
                }
            }
        }
        .frame(width: viewWidth, height: viewHeight * 2/3)
    }
    
}

final class BlockLogWindowController: NSWindowController, NSWindowDelegate {
    
    static var current: BlockLogWindowController?
    
    init(contentRect: CGRect) {
        let mainView = BlockLogView()

        let window = NSWindow(
            contentRect: contentRect,
            styleMask: [.titled, .closable],
            backing: .buffered,
            defer: false
        )
        window.title = "Lockdown"
        let hosting = NSHostingView(rootView: mainView)
        window.contentView = hosting

        super.init(window: window)
        window.delegate = self
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    func windowDidBecomeKey(_ notification: Notification) {
        window?.level = .floating
    }
    
    func windowWillClose(_ notification: Notification) {
        BlockLogWindowController.current = nil
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

fileprivate extension UserDefaults {
    
    @objc
    dynamic var LockdownDayLogs: [Any]? {
        get {
            assert(#function == kDayLogs)
            return array(forKey: kDayLogs)
        }
        set {
            set(newValue, forKey: kDayLogs)
        }
    }
}

struct BlockLogRow: View {
    
    @State var blockLog: BlockLog
    
    var body: some View {
        VStack (alignment: .leading, spacing: 0.0) {
            HStack {
                Text(blockLog.time)
                .font(cFontSmall.monospacedDigit())
                .multilineTextAlignment(.leading)
                .padding(.leading, 4.0)
                .padding(.vertical, 0)
                    .padding(.top, 0.5)
                .foregroundColor(Color.secondary)
                .frame(width: 70, height: 30, alignment: .leading)
                Text(blockLog.host)
                .font(cFontRegular)
                .multilineTextAlignment(.leading)
                    .padding(.leading, 0.5)
                .padding(.vertical, 0)
                .minimumScaleFactor(0.3)
                    .frame(maxHeight: 80)
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
