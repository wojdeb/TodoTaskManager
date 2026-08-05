//
//  TaskViewModel.swift
//  TodoTaskManager
//
//  Created by Wojtek on 30/05/2026.
//

import Foundation
import Combine

@MainActor
class TaskViewModel: ObservableObject {
    @Published private(set) var state: TasksViewState = .loading
    @Published var filter: TaskFilter = .all
    @Published var searchQuery: String = ""
    
    private var pendingToggles: Set<Todo.ID> = []
    
    let provider: TaskProviding
    
    init(provider: TaskProviding) {
        self.provider = provider
        Task {
            await fetchTodos()
        }
    }
    
    var filteredTasks: [Todo] {
        guard case .content(let tasks) = state else { return [] }
        let filtered: [Todo]

        switch filter {
        case .all:
            filtered = tasks
        case .active:
            filtered = tasks.filter {$0.completed == false}
        case .done:
            filtered = tasks.filter {$0.completed == true}
        }
        
        if !searchQuery.isEmpty {
            return filtered.filter {$0.title.lowercased().contains(searchQuery.lowercased())}
        } else {
            return filtered
        }
    }

    func fetchTodos() async {
         state = .loading

         do {
             let tasks = try await provider.fetchTodos()
             if tasks.isEmpty {
                 state = .empty
             } else {
                 state = .content(tasks: tasks)
             }
         } catch let error as TaskError {
             print(error.developerLog)
             state = .error(message: error.userMessage)
         } catch {
             let taskError = TaskError.unknown(error)
             print(taskError.developerLog)
             state = .error(message: taskError.userMessage)
         }
     }
    
    func toggleTodo(id: Todo.ID) async {
        guard case .content(var tasks) = state else { return }
        
        guard !pendingToggles.contains(id) else { return }
        pendingToggles.insert(id)
        defer { pendingToggles.remove(id) }
        
        guard let index = tasks.firstIndex(where: {task in task.id == id}) else { return }
        tasks[index].completed.toggle()
        state = .content(tasks: tasks)
        
        do {
            try await provider.patchTodo(id: id, completed: tasks[index].completed)
        } catch let error as TaskError {
            print(error.developerLog)
            tasks[index].completed.toggle()
            state = .content(tasks: tasks)
        } catch {
            let taskError = TaskError.unknown(error)
            print(taskError.developerLog)
            tasks[index].completed.toggle()
            state = .content(tasks: tasks)
        }
    }
}
