//
//  ChatLogView.swift
//  chatUi
//
//  Created by Sebastian on 23/10/2022.
//

import SwiftUI

struct ChatLogView: View {
    let chatUser: ChatUser?
    
    var body: some View {
        ScrollView {
            ForEach(0..<10) { num in
                Text("Fake message")
            }
            
        }.navigationTitle(chatUser?.email ?? "")
            .navigationBarTitleDisplayMode(.inline)
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            ChatLogView(chatUser: nil)
        }
    }
}
