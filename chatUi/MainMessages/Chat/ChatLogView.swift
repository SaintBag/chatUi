//
//  ChatLogView.swift
//  chatUi
//
//  Created by Sebastian on 23/10/2022.
//

import SwiftUI
import Firebase
import FirebaseFirestore

struct FirebaseConstans {
    static let senderId = "senderId"
    static let reciverId = "reciverId"
    static let text = "text"
}

struct ChatMessage: Identifiable {
    var id: String { documentId }
    
    let documentId: String
    let senderId: String
    let reciverID: String
    let text: String
    
    init(documentId: String, data: [String: Any]) {
        self.documentId = documentId
        self.senderId = data[FirebaseConstans.senderId] as? String ?? ""
        self.reciverID = data[FirebaseConstans.reciverId] as? String ?? ""
        self.text = data[FirebaseConstans.text] as? String ?? ""
    }
    
}

class ChatLogViewModel: ObservableObject {
    @Published var chatText = ""
    @Published var errorMessage = ""
    @Published var chatMessages = [ChatMessage]()
    
    let chatUser: ChatUser?
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        fetchMessage()
    }
    
    private func fetchMessage() {
        guard let senderId = FirebaseManager.shared.auth.currentUser?.uid else { return }
        
        guard let reciverId = chatUser?.uid else { return }
        
        FirebaseManager.shared.firestore
            .collection("messages")
            .document(senderId)
            .collection(reciverId)
        //        let guerySnapshot = ""
            .addSnapshotListener { querySnapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to listed for messages \(error)"
                    print(error.localizedDescription)
                    return
                }
                querySnapshot?.documents.forEach({ queryDocumentsSnapshot in
                    let data = queryDocumentsSnapshot.data()
                    let documentId = queryDocumentsSnapshot.documentID
                    let chatMessage = ChatMessage(documentId: documentId, data: data)
                    self.chatMessages.append(chatMessage)
                    // self.chatMessages.apend(.init(data: data))
                })
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
        let messageData = [FirebaseConstans.senderId: senderId, FirebaseConstans.reciverId: reciverId, FirebaseConstans.text: self.chatText, "timestamp": Timestamp()] as [String: Any]
        
        document.setData(messageData) { error in
            if let error = error {
                self.errorMessage = "failed to save messages data to firebase \(error)"
                return
            }
            self.chatText = ""
            //            print("Successfully saved current user sending message")
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
            //            print("Successfully saved recipient message")
        }
    }
}

struct ChatLogView: View {
    
    let chatUser: ChatUser?
    
    init(chatUser: ChatUser?) {
        self.chatUser = chatUser
        self.viewModel = .init(chatUser: chatUser)
    }
    
    //    @State var chatText = ""
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
                ForEach(viewModel.chatMessages) { message in
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
                    .padding(.horizontal)
                    .padding(.top, 8)
                }
                HStack {
                    Spacer()
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
        //        NavigationView {
        //            ChatLogView(chatUser: .init(data: ["uid": "OqnHwFModBM2U3sKamub9o6WY2p1","email": "flowers@gmail.com"]))
        //        }
        MainMessagesView()
    }
}
