//
//  MainMessageViewModel.swift
//  chatUi
//
//  Created by Sebastian on 27/10/2022.
//

import Foundation
import Firebase
import FirebaseFirestore
import FirebaseFirestoreSwift

class MainMessageViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    @Published var isUserCurrentlyLoggedOut = false
    @Published var recentMessages = [RecentMessage]()
    
    init() {
        DispatchQueue.main.async {
            self.isUserCurrentlyLoggedOut = FirebaseManager.shared.auth.currentUser?.uid == nil
        }
        fetchCurrentUser()
        fetchRecentMessages()
    }
    func fetchCurrentUser() {
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).getDocument { snapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch current user:, \(error)"
                    return
                }
                guard let data = snapshot?.data() else {
                    return }
                self.chatUser = .init(data: data)
            }
    }
    
    func handleSignOut() {
        isUserCurrentlyLoggedOut.toggle()
        try? FirebaseManager.shared.auth.signOut()
    }
    
    private func fetchRecentMessages() {
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listen for recent messages: \(error)"
                    print("Failed to listen for recent messages: \(error)")
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    let documentId = change.document.documentID
                    if let index = self.recentMessages.firstIndex(where: { rMessage in
                        return rMessage.id == documentId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    do {
                        let recentMessage = try change.document.data(as: RecentMessage.self)
                        self.recentMessages.insert(recentMessage, at: 0)
                    } catch {
                        print(error)
                    }
                })
            }
        }
    }
