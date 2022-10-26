//
//  MainMessagesView.swift
//  chatUi
//
//  Created by Sebastian on 20/10/2022.
//

import SwiftUI
import SDWebImageSwiftUI
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
    
    init(documentId: String, data: [String: Any]) {
        
        self.documentId = documentId
        self.text = data[FirebaseConstans.text] as? String ?? ""
        self.senderId = data[FirebaseConstans.senderId] as? String ?? ""
        self.reciverId = data[FirebaseConstans.reciverId] as? String ?? ""
        self.email = data[FirebaseConstans.email] as? String ?? ""
        self.profileImageUrl = data[FirebaseConstans.profileImageUrl] as? String ?? ""
        self.timestamp = data[FirebaseConstans.timestamp] as? Timestamp ?? Timestamp(date: Date())
    }
}

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
                        let changeDocumentDict = change.document.data()
                    
                    if let index = self.recentMessages.firstIndex(where: { rMessage in
                        return rMessage.documentId == documentId
                    }) {
                        self.recentMessages.remove(at: index)
                    }
                    self.recentMessages.insert(.init(documentId: documentId, data: changeDocumentDict), at: 0)
                        
                })
            }
    }
}

struct MainMessagesView: View {
    
    @ObservedObject private var viewModel = MainMessageViewModel()
    @State var schouldShowLogOutOptions = false
    @State var chatUser: ChatUser?
    @State var schouldShowNewMessageScreen = false
    @State var schouldNavigateToChatLogView = false
    
    
    private var customNavBar: some View {
        HStack(spacing: 16) {
            let profileImageUrl = viewModel.chatUser?.profileImageUrl ?? ""
            WebImage(url: URL(string: profileImageUrl))
                .resizable()
                .scaledToFill()
                .frame(width: 56, height: 56)
                .clipped()
                .cornerRadius(56)
                .overlay(RoundedRectangle(cornerRadius: 56)
                    .stroke(Color(.label), lineWidth: 3))
                .shadow(radius: 10)
            VStack(alignment: .leading) {
                let nameFromEmail = viewModel.chatUser?.email.replacingOccurrences(of: "@gmail.com", with: "") ?? ""
                Text(nameFromEmail.capitalized)
                    .font(.system(size: 24, weight: .bold))
                HStack {
                    Circle()
                        .foregroundColor(.green)
                        .frame(width: 14, height: 14)
                    Text("online")
                        .font(.system(size: 14))
                        .foregroundColor(Color(.lightGray))
                }
            }
            Spacer()
            Button {
                schouldShowLogOutOptions.toggle()
            } label: {
                Image(systemName: "gear")
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(Color(.label))
            }
        }
        .padding()
        .actionSheet(isPresented: $schouldShowLogOutOptions) {
            .init(title: Text("Settings") , message: Text("What do you want to do?"), buttons: [
                .destructive(Text("Sign Out"), action: {
                    print("handle sign out")
                    viewModel.handleSignOut()
                }),
                .cancel()
            ])
        }
        .fullScreenCover(isPresented: $viewModel.isUserCurrentlyLoggedOut) {
            LogInView(didCompleteLoginProcess: {
                self.viewModel.isUserCurrentlyLoggedOut = false
                self.viewModel.fetchCurrentUser()
            })
        }
    }
    var body: some View {
        NavigationView {
            VStack {
                customNavBar
                messagesScrollView
                NavigationLink("", isActive: $schouldNavigateToChatLogView) {
                    ChatLogView(chatUser: self.chatUser)
                }
            }
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    private var messagesScrollView: some View {
        ScrollView {
            
            ForEach(viewModel.recentMessages) { recentMessage in
                VStack {
                    NavigationLink {
                        Text("Destination")
                    } label: {
                        HStack(spacing: 16) {

                            WebImage(url: URL(string: recentMessage.profileImageUrl))
                                .resizable()
                                .scaledToFill()
                                .frame(width: 44, height: 44)
                                .clipped()
                                .cornerRadius(44)
                                .overlay(RoundedRectangle(cornerRadius: 44)
                                    .stroke(Color(.label), lineWidth: 3))
                                .shadow(radius: 10)
                                .padding(8)

                            VStack(alignment: .leading) {
                                let nameFromEmail = recentMessage.email.replacingOccurrences(of: "@gmail.com", with: "").capitalized
                                
                                Text(nameFromEmail)
                                    .font(.system(size: 16, weight: .bold))
                                    .foregroundColor(Color(.label))
                                    Spacer()
                                Text(recentMessage.text)
                                    .font(.system(size: 14))
                                    .foregroundColor(Color(.darkGray))
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .foregroundColor(Color(.label))
                        Spacer()
                        Text("22d")
                            .font(.system(size: 14, weight: .semibold))
                    }
                    Divider()
                        .padding(.vertical, 8)
                }.padding(.horizontal)
            }.padding(.bottom, 50)
        }
    }
    
    private var newMessageButton: some View {
        Button {
            schouldShowNewMessageScreen.toggle()
        } label: {
            HStack {
                Spacer()
                Text("+ NEW MESSAGE")
                    .font(.system(size: 18, weight: .bold))
                Spacer()
            }
            .foregroundColor(.white)
            .padding(.vertical)
            .background(Color.blue)
            .cornerRadius(36)
            .padding(.horizontal)
            .shadow(radius: 16)
        }
        .fullScreenCover(isPresented: $schouldShowNewMessageScreen, onDismiss: nil) {
            CreateNewMessageView(didSelectNewUser: { user in
                print(user.email)
                self.schouldNavigateToChatLogView.toggle()
                self.chatUser = user
            })
        }
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
//                ChatLogView()
    }
}
