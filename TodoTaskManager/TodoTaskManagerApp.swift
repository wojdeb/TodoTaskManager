//
//  TodoTaskManagerApp.swift
//  TodoTaskManager
//
//  Created by Wojtek on 30/05/2026.
//

import SwiftUI
import SwiftData

@main
struct TodoTaskManagerApp: App {
    let container: ModelContainer
    
    init() {
        do {
            container = try ModelContainer(for: TodoModel.self)
        } catch {
            fatalError("Failed to create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            TaskView(vm: TaskViewModel(
                repository: TodoRepositoryImpl(
                    provider: NetworkTaskProvider(),
                    context: container.mainContext
                )
            ))
        }
        .modelContainer(for: TodoModel.self)
    }
}
