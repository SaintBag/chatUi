//
//  ChatLogView.swift
//  chatUi
//
//  Created by Sebastian on 23/10/2022.
//

import SwiftUI
import Firebase
import FirebaseFirestore

class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    @Published var count = 0
    
    let chatUser: ChatUser?
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchMessages()
    }
    
    private func fetchMessages() {
        guard let senderId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let reciverId = chatUser?.uid else { return }
        
        FirebaseManager.shared.firestore
            .collection("messages")
            .document(senderId)
            .collection(reciverId)
            .order(by: "timestamp")
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listed for messages \(error)"
                    print(error.localizedDescription)
                    return
                }
                
                querySnapshot?.documentChanges.forEach({ change in
                    if change.type == .added {
                        let data = change.document.data()
                        let chatMessage = ChatMessage(documentId: change.document.documentID, data: data)
                        self.chatMessages.append(chatMessage)
                        
                    }
                })
                DispatchQueue.main.async {
                    self.count += 1
                }
            }
        }
    
    func handleSend() {
        print(chatText)
        guard let senderId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let reciverId = chatUser?.uid else { return }
        
        let document =
        FirebaseManager.shared.firestore.collection("messages")
            .document(senderId)
            .collection(reciverId)
            .document()
        let messageData =
        [FirebaseConstans.senderId: senderId, FirebaseConstans.reciverId: reciverId, FirebaseConstans.text: self.chatText, "timestamp": Timestamp()] as [String: Any]
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "failed to save messages data to firebase \(error)"
                return
            }
            self.persistRecentMessage()
            self.chatText = ""
                        print("Successfully saved current user sending message")
            self.count += 1
        }
        
        let recipientMessageDocument =
        FirebaseManager.shared.firestore.collection("messages")
            .document(reciverId)
            .collection(senderId)
            .document()
        
        recipientMessageDocument.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "failed to save messages data to firebase \(error)"
                return
            }
                        print("Successfully saved recipient message")
        }
    }
    private func persistRecentMessage() {
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        guard let reciverId = self.chatUser?.uid else { return }
        guard let chatUser = chatUser else { return }
        
        let document =
        FirebaseManager.shared.firestore
            .collection("recent_messages")
            .document(uid)
            .collection("messages")
            .document(reciverId)
        
        let data = [
            FirebaseConstans.timestamp: Timestamp(),
            FirebaseConstans.text: self.chatText,
            FirebaseConstans.senderId: uid,
            FirebaseConstans.reciverId: reciverId,
            FirebaseConstans.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstans.email: chatUser.email
        ] as [String : Any]
        
        document.setData( data ) { error in
            if let error = error {
                self.errorMessage = "Failed to save recent message: \(error)"
                print("Failed to save recent message: \(error)")
                return
            }
            
        //TODO: need to fix this data and set data
        let dataReciver = [
            FirebaseConstans.timestamp: Timestamp(),
            FirebaseConstans.text: self.chatText,
            FirebaseConstans.senderId: uid,
            FirebaseConstans.reciverId: reciverId,
            FirebaseConstans.profileImageUrl: chatUser.profileImageUrl,
            FirebaseConstans.email: chatUser.email
        ] as [String : Any]

        let recipientDocument =
        FirebaseManager.shared.firestore
            .collection(FirebaseConstans.recentMessages)
            .document(reciverId)
            .collection(FirebaseConstans.messages)
            .document(uid)


            recipientDocument.setData(dataReciver) { error in
                if let error = error {
                    self.errorMessage = "Failed to save recent message: \(error)"
                    print("Failed to save recent message: \(error)")
                    return
                }
            }
        
        }
    }
}

struct ChatLogView: View {
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.viewModel = .init(chatUser: chatUser)
    }
    @ObservedObject var viewModel: ChatLogViewModel
    
    var body: some View {
        ZStack {
            messagesView
            Text(viewModel.errorMessage)
        }
        .navigationTitle(chatUser?.email ?? "")
        .navigationBarTitleDisplayMode(.inline)
    }
    private var messagesView: some View {
        VStack {
            ScrollView {
                ScrollViewReader { ScrollViewProxy  in
                    VStack {
                        ForEach(viewModel.chatMessages) { message in
                            MessageView(message: message)
                        }
                        HStack {
                            Spacer()
                        }
                        .id("Empty")
                    }
                    .onReceive(viewModel.$count) { _ in
                        withAnimation(.easeOut(duration: 0.5)) {
                            ScrollViewProxy.scrollTo("Empty", anchor: .bottom)
                        }
                    }
                }
            }
            .background(Color(.init(white: 0.95, alpha: 1)))
            .safeAreaInset(edge: .bottom) {
                chatBottomBar
                    .background(Color(.systemBackground).ignoresSafeArea())
            }
        }
    }
    private var chatBottomBar: some View {
        HStack(spacing: 16) {
            Image(systemName: "photo")
                .font(.system(size: 24))
                .foregroundColor(Color(.darkGray))
            ZStack {
                DescriptionPlaceholder()
                TextEditor(text: $viewModel.chatText)
                    .opacity(viewModel.chatText.isEmpty ? 0.5 : 1)
            }
            .frame(height: 40)
            
            Button {
                viewModel.handleSend()
            } label: {
                Text("Send")
                    .foregroundColor(.white)
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
            .background(Color.blue)
            .cornerRadius(5)
            
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

private struct MessageView: View {
    
    let message: ChatMessage
    var body: some View {
        VStack {
            if message.senderId == FirebaseManager.shared.auth.currentUser?.uid {
                HStack {
                    Spacer()
                    HStack {
                        Text(message.text)
                            .foregroundColor(.white)
                    }
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(8)
                }
            } else {
                HStack {
                    HStack {
                        Text(message.text)
                            .foregroundColor(Color(.label))
                    }
                    .padding()
                    .background(Color.white)
                    .cornerRadius(8)
                    Spacer()
                }
            }
        }
        .padding(.horizontal)
        .padding(.top, 8)
    }
}

private struct DescriptionPlaceholder: View {
    var body: some View {
        HStack {
            Text("Description")
                .foregroundColor(Color(.gray))
                .font(.system(size: 16))
                .padding(.leading, 5)
                .padding(.top, -5)
            Spacer()
        }
    }
}

struct ChatLogView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}
