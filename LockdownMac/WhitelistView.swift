//
//  WhitelistView.swift
//  Lockdown
//
//  Created by Johnny Lin on 1/22/20.
//  Copyright © 2020 Confirmed, Inc. All rights reserved.
//

import SwiftUI

struct WhitelistView: View {
    
    var body: some View {
        
        VStack(spacing: 0.0) {
            Text("The whitelist feature is not yet available.\nPlease check back soon.")
                .font(cFontSubtitle)
                .multilineTextAlignment(.center)
        }
        .frame(width: 280, height: 80)
        
    }
    
}

struct WhitelistView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            WhitelistView()
        }
    }
}
