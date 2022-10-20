//
//  MainMessagesView.swift
//  chatUi
//
//  Created by Sebastian on 20/10/2022.
//

import SwiftUI
import SDWebImageSwiftUI

struct ChatUser {
    let uid: String
    let email: String
    let profileImageUrl: String
}

class MainMessageViewModel: ObservableObject {
    
    @Published var errorMessage = ""
    @Published var chatUser: ChatUser?
    
    init() {
        fetchCurrentUser()
    }
    private func fetchCurrentUser() {
        
        guard let uid = FirebaseManager.shared.auth.currentUser?.uid else { return }
        FirebaseManager.shared.firestore.collection("users")
            .document(uid).getDocument { snapshot, error in
                if let error = error {
                    self.errorMessage = "Failed to fetch current user:, \(error)"
                    return
                }
                guard let data = snapshot?.data() else {
                    return }
                let uid = data["uid"] as? String ?? ""
                let email = data["email"] as? String ?? ""
                let profileImageUrl = data["profileImageUrl"] as? String ?? ""
                self.chatUser = ChatUser(uid: uid, email: email, profileImageUrl: profileImageUrl)
            }
    }
}

struct MainMessagesView: View {
    
    @ObservedObject private var viewModel = MainMessageViewModel()
    @State var schouldShowLogOutOptions = false
    
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
                Text(nameFromEmail)
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
                }),
                .cancel()
            ])
        }
    }
    var body: some View {
        NavigationView {
            
            VStack {
                customNavBar
                messagesScrollView
            }
            .overlay(
                newMessageButton, alignment: .bottom)
            .navigationBarHidden(true)
        }
    }
    private var messagesScrollView: some View {
        ScrollView {
            ForEach(0..<10, id: \.self) { num in
                VStack {
                    HStack(spacing: 16) {
                        Image(systemName: "person.fill")
                            .font(.system(size: 36))
                            .padding(8)
                            .overlay(RoundedRectangle(cornerRadius: 46)
                                .stroke(Color(.label), lineWidth: 3)
                            )
                        
                        VStack(alignment: .leading) {
                            Text("Username")
                                .font(.system(size: 16, weight: .bold))
                            Text("Message send to user")
                                .font(.system(size: 14))
                                .foregroundColor(Color(.lightGray))
                        }
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
            // TODO: add functionalities
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
    }
}

struct MainMessagesView_Previews: PreviewProvider {
    static var previews: some View {
        MainMessagesView()
    }
}
