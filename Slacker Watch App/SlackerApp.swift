//
//  SlackerApp.swift
//  Slacker Watch App
//
//  Created by Gautam Menon on 16/07/26.
//

import SwiftUI
import SwiftData

@main
struct Slacker_Watch_AppApp: App {
    // Provide a SwiftData model container so @Query and modelContext work
    private let container: ModelContainer = {
        do {
            return try ModelContainer(for: StoredSession.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .modelContainer(container)
        }
    }
}

#Preview {
    ContentView()
}
