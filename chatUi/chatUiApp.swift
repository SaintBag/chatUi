//
//  chatUiApp.swift
//  chatUi
//
//  Created by Sebastian on 18/10/2022.
//

import SwiftUI

@main
struct chatUiApp: App {
    let persistenceController = PersistenceController.shared

    var body: some Scene {
        WindowGroup {
            MainMessagesView()
//            LogInView()
//                .environment(\.managedObjectContext, persistenceController.container.viewContext)
        }
    }
}
