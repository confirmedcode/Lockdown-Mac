//
//  BlockMetricsView.swift
//  Lockdown
//
//  Created by Johnny Lin on 1/17/20.
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import SwiftUI
import AppKit

struct BlockMetricsView: View {
    
    @State var dayMetrics = getDayMetricsString()
    @State var weekMetrics = getWeekMetricsString()
    @State var totalMetrics = getTotalMetricsString()
    
    let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(spacing: 0.0) {
            HStack {
                VStack {
                    Text("TODAY")
                        .font(cFontSmall)
                        .foregroundColor(Color.gray.opacity(0.6))
                        .padding(.bottom, 3)
                    Text(self.dayMetrics)
                        .font(cFontSubtitle2)
                }
                .padding(.leading, 44)
                Spacer()
                VStack {
                    Text("THIS WEEK")
                        .font(cFontSmall)
                        .foregroundColor(Color.gray.opacity(0.6))
                        .padding(.bottom, 3)
                    Text(self.weekMetrics)
                        .font(cFontSubtitle2)
                }
                Spacer()
                VStack {
                    Text("ALL TIME")
                        .font(cFontSmall)
                        .foregroundColor(Color.gray.opacity(0.6))
                        .padding(.bottom, 3)
                    Text(self.totalMetrics)
                        .font(cFontSubtitle2)
                }
                .padding(.trailing, 44)
            }
            .frame(width: viewWidth, height: 60)
            .onReceive(timer) { input in
                self.dayMetrics = getDayMetricsString()
                self.weekMetrics = getWeekMetricsString()
                self.totalMetrics = getTotalMetricsString()
            }
        }
    }

}

#if DEBUG
struct BlockMatricsView_Previews: PreviewProvider {
    static var previews: some View {
        BlockMetricsView()
    }
}
#endif
