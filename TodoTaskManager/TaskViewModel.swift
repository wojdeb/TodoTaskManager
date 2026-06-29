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
    
    let provider: TaskProviding
    
    init(provider: TaskProviding) {
        self.provider = provider
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
            return filtered.filter {$0.title.contains(searchQuery.lowercased())}
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
        } catch {
            state = .error(message: "Something went wrong")
        }
    }
    
    func refresh() async {
        await fetchTodos()
    }
    
    func toggleTodo(id: Todo.ID) async {
        guard case .content(var tasks) = state else { return }
        
        guard let index = tasks.firstIndex(where: {task in task.id == id}) else { return }
        tasks[index].completed.toggle()
        state = .content(tasks: tasks)
        
        do {
            try await provider.patchTodo(id: id, completed: tasks[index].completed)
        } catch {
            tasks[index].completed.toggle()
            state = .error(message: "Something went wrong")
        }
    }
}
