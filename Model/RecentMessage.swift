//
//  RecentMessage.swift
//  chatUi
//
//  Created by Sebastian on 27/10/2022.
//

import Foundation
import Firebase
import FirebaseFirestore

struct RecentMessage: Identifiable {
    var id: String { documentId }
    
    let documentId: String
    let text: String
    let senderId: String
    let reciverId: String
    let email: String
    let profileImageUrl: String
    let timestamp: Timestamp
    
//    init(documentId: String, data: [String: Any]) {
//        
//        self.documentId = documentId
//        self.text = data[FirebaseConstans.text] as? String ?? ""
//        self.senderId = data[FirebaseConstans.senderId] as? String ?? ""
//        self.reciverId = data[FirebaseConstans.reciverId] as? String ?? ""
//        self.email = data[FirebaseConstans.email] as? String ?? ""
//        self.profileImageUrl = data[FirebaseConstans.profileImageUrl] as? String ?? ""
//        self.timestamp = data[FirebaseConstans.timestamp] as? Timestamp ?? Timestamp(date: Date())
//    }
}
