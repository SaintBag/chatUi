//
//  ChatMessage.swift
//  chatUi
//
//  Created by Sebastian on 27/10/2022.
//

import Foundation
import Firebase
import FirebaseFirestore

struct ChatMessage: Identifiable {
    var id: String { documentId }
    
    let documentId: String
    let senderId: String
    let reciverId: String
    let text: String
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.senderId = data[FirebaseConstans.senderId] as? String ?? ""
        self.reciverId = data[FirebaseConstans.reciverId] as? String ?? ""
        self.text = data[FirebaseConstans.text] as? String ?? ""
    }
}
