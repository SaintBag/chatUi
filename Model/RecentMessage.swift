//
//  RecentMessage.swift
//  chatUi
//
//  Created by Sebastian on 27/10/2022.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

struct RecentMessage: Codable, Identifiable {

    @DocumentID var id: String?

    let text: String
    let senderId: String
    let reciverId: String
    let email: String
    let profileImageUrl: String
    let timestamp: Date

}
