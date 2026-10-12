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
    @Published var snackbarMessage: String?
    
    private var pendingIDs: Set<Todo.ID> = []
    private let todoRepository: TodoRepository
    
    init(repository: TodoRepository) {
        self.todoRepository = repository
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
    
    var activeTasks: [Todo] {
        filteredTasks.filter { !$0.completed }
    }
    
    var completedTasks: [Todo] {
        filteredTasks.filter { $0.completed }
    }
    
    func keychainTesting() {
        
    }
    
    func fetchTodos() async {
        state = .loading
        
        do {
            let tasks = try await todoRepository.fetchTodos()
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
        guard case .content(var tasks) = state,
              let index = tasks.firstIndex(where: { $0.id == id })
        else {
            return
        }

        guard !pendingIDs.contains(id) else {
            return
        }

        pendingIDs.insert(id)
        defer {
            pendingIDs.remove(id)
        }

        let previousValue = tasks[index].completed
        let newValue = !previousValue

        tasks[index].completed = newValue
        state = .content(tasks: tasks)

        do {
            try await todoRepository.toggleTodo(
                id: id,
                completed: newValue
            )
        } catch {
            rollbackTodo(id: id, completed: previousValue)

            showSnackbar(
                newValue
                    ? "Failed to mark task"
                    : "Failed to unmark task"
            )

            let taskError = error as? TaskError ?? TaskError.unknown(error)
            print(taskError.developerLog)
        }
    }
    
    private func rollbackTodo(
        id: Todo.ID,
        completed previousValue: Bool
    ) {
        guard case .content(var tasks) = state,
              let index = tasks.firstIndex(where: { $0.id == id })
        else {
            return
        }

        tasks[index].completed = previousValue
        state = .content(tasks: tasks)
    }
    
    func showSnackbar(_ message: String) {
        snackbarMessage = message
        Task {
            try? await Task.sleep(for: .seconds(3))
            snackbarMessage = nil
        }
    }
    
#if DEBUG
    func setState(_ state: TasksViewState) {
        self.state = state
    }
#endif
}
