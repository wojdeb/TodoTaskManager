//
//  TodoRepository.swift
//  TodoTaskManager
//
//  Created by Wojtek on 12/08/2026.
//

import SwiftData

protocol TodoRepository {
    func fetchTodos() async throws -> [Todo]
    func toggleTodo(id: Int, completed: Bool) async throws
}

@MainActor
class TodoRepositoryImpl: TodoRepository {
    private let provider: TaskProviding
    private let context: ModelContext
    private var cache: [Todo] = []
    private var pendingToggles: Set<Int> = []
    
    init(provider: TaskProviding, context: ModelContext) {
        self.provider = provider
        self.context = context
    }

    func fetchTodos() async throws -> [Todo] {
        do {
            cache = try await provider.fetchTodos()
            saveToSwiftData(cache)
            return cache
        } catch  {
            cache = loadFromSwiftData()
            return cache
        }
    }

    func toggleTodo(id: Int, completed: Bool) async throws {
        guard !pendingToggles.contains(id) else { return }
        pendingToggles.insert(id)
        defer { pendingToggles.remove(id) }
        
        
        guard let index = cache.firstIndex(where: {task in task.id == id}) else { return }
        cache[index].completed.toggle()
        
        do {
            _ = try await provider.patchTodo(id: id, completed: cache[index].completed)
            saveToSwiftData(cache)
        } catch {
            cache[index].completed.toggle()
            throw error
        }
    }
    
    private func saveToSwiftData(_ todos: [Todo]) {
        do {
            let fetchDescriptor = FetchDescriptor<TodoModel>()
            let existing = try context.fetch(fetchDescriptor)
            existing.forEach { context.delete($0) }
            todos.forEach { context.insert(TodoModel(from: $0)) }
            try context.save()
        } catch {
            print(TaskError.unknown(error).developerLog)
        }
    }
    private func loadFromSwiftData() -> [Todo] {
        do {
            let fetchDescriptor = FetchDescriptor<TodoModel>()
            let results = try context.fetch(fetchDescriptor)
            return results.map { $0.toTodo() }
        } catch {
            print(TaskError.unknown(error).developerLog)
            return []
        }
        
    }
}
