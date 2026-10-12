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
            
            guard !cache.isEmpty else { throw error }
            return cache
        }
    }

    func toggleTodo(id: Int, completed: Bool) async throws {
        let updatedTodo = try await provider.patchTodo(
            id: id,
            completed: completed
        )

        if let index = cache.firstIndex(where: { $0.id == id }) {
            cache[index] = updatedTodo
        } else {
            cache.append(updatedTodo)
        }

        saveToSwiftData(cache)
    }
    
    private func saveToSwiftData(_ todos: [Todo]) {
        do {
            let fetchDescriptor = FetchDescriptor<TodoModel>()
            let existing = try context.fetch(fetchDescriptor)
            existing.forEach { context.delete($0) }
            todos.forEach { context.insert(TodoModel(from: $0)) }
            try context.save()
        } catch {
            context.rollback()
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
