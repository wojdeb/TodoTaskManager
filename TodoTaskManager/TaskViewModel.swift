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
    
    private let todoRepository: TodoRepository
        
    init(repository: TodoRepository) {
        self.todoRepository = repository
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
    
    var activeTasks: [Todo] {
        filteredTasks.filter { !$0.completed }
    }
    
    var completedTasks: [Todo] {
        filteredTasks.filter { $0.completed }
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
        guard case .content(var tasks) = state else { return }
        
        guard let index = tasks.firstIndex(where: { $0.id == id }) else { return }
        let task = tasks[index]
        tasks[index].completed.toggle()
        state = .content(tasks: tasks)
                
        do {
            try await todoRepository.toggleTodo(id: id, completed: !task.completed)
        } catch let error as TaskError {
            print(error.developerLog)
            state = .content(tasks: tasks)
        } catch {
            let taskError = TaskError.unknown(error)
            print(taskError.developerLog)
            state = .content(tasks: tasks)
        }
    }
}
