//
//  DomainsModal.swift
//  Lockdown
//
//  Created by Johnny Lin on 12/5/19.
//  Copyright © 2019 Confirmed, Inc. All rights reserved.
//

import SwiftUI

struct DomainsModalView: View {
    
    @Binding var showModal: Bool
    var title: String
    var blockListDomains: [String]
    
    var body: some View {
        VStack(spacing: 0.0) {
            Section(header:
                Text("\"\(title)\" Block List")
                    .font(cFontTitle)
                    .padding(.vertical, 10))
            {
                List {
                    ForEach(blockListDomains.indices) { index in
                        Text(self.blockListDomains[index])
                    }
                }
            }
            Button("Dismiss") {
                self.showModal.toggle()
            }
            .padding(.vertical, 10)
        }
        .frame(width: 280, height: 360)
    }
}

struct DomainsModalView_Previews: PreviewProvider {
    static var previews: some View {
        DomainsModalView(showModal: .constant(true), title: "Test List", blockListDomains: ["a.com", "b.com", "z.com", "abc.org"])
    }
}
