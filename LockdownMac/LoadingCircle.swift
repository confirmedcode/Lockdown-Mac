//
//  LoadingCircle.swift
//  Lockdown
//
//  Created by Johnny Lin on 1/21/20.
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import Foundation
import SwiftUI
import CocoaLumberjackSwift

struct LoadingCircle: View {
    
    @State private var animateStrokeStart = false
    @State private var animateStrokeEnd = true
    @State private var isRotating = true
    
    var tunnelState: TunnelState
    var toggleTapped: () -> Void
    init(toggleTapped: @escaping () -> Void, tunnelState: TunnelState) {
        self.toggleTapped = toggleTapped
        self.tunnelState = tunnelState
    }
    
    var body: some View {
        ZStack {
            if tunnelState.isLoading {
                Circle()
                    .trim(from: animateStrokeStart ? 1/3 : 1/5,
                          to: animateStrokeEnd ? 1/2 : 1)
                    .stroke(lineWidth: 4)
                    .frame(width: 100, height: 100)
                    .padding(4)
                    .foregroundColor(tunnelState.circleColor)
                    .rotationEffect(.degrees(isRotating ? 0 : 360))
                    .onAppear() {
                        withAnimation(Animation.linear(duration: 1).repeatForever(autoreverses: false))
                        {
                            self.isRotating.toggle()
                        }
                        withAnimation(Animation.linear(duration: 1).delay(0.5).repeatForever(autoreverses: true))
                        {
                            self.animateStrokeStart.toggle()
                        }
                        withAnimation(Animation.linear(duration: 1).delay(1).repeatForever(autoreverses: true))
                        {
                            self.animateStrokeEnd.toggle()
                        }
                    }
                    .zIndex(10)
            }
            else {
                Circle()
                    .stroke(lineWidth: 4)
                    .frame(width: 100, height: 100)
                    .padding(4)
                    .foregroundColor(tunnelState.circleColor)
                    .zIndex(10)
            }
            Circle()
                .fill()
                .frame(width: 100, height: 100)
                .shadow(color: Color(red: 0, green: 0, blue: 0, opacity: 0.35), radius: 4, x: 3.5, y: 3.5)
                .padding(4)
                .foregroundColor(Color.panelBackground)
                .background(Color.panelBackground)
                .zIndex(1)
            Button(
                action: {
                    self.toggleTapped()
                }) {
                    Image("power_button")
                    .resizable()
                    .padding(19)
                    .foregroundColor(tunnelState.circleColor)
                    .frame(width: 100, height: 100)
                }
                .frame(width: 100, height: 100)
                .buttonStyle(BlankButtonStyle())
                .zIndex(100)
            }
    }
}

#if DEBUG
struct LoadingCircleView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            LoadingCircle(toggleTapped: {
                DDLogInfo("toggleTapped")
            }, tunnelState: TunnelState())
            LoadingCircle(toggleTapped: {
                DDLogInfo("toggleTapped")
            }, tunnelState: TunnelState(status: "ACTIVATING", color: .confirmedBlue, circleColor: .confirmedBlue, isLoading: true))
        }
    }
}
#endif
