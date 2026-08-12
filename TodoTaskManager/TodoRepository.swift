//
//  TodoRepository.swift
//  TodoTaskManager
//
//  Created by Wojtek on 12/08/2026.
//

protocol TodoRepository {
    func fetchTodos() async throws -> [Todo]
    func toggleTodo(id: Int, completed: Bool) async throws
}

actor TodoRepositoryImpl: TodoRepository {
    private let provider: TaskProviding
    private var cache: [Todo] = []
    private var pendingToggles: Set<Int> = []
    
    init(provider: TaskProviding) {
        self.provider = provider
    }

    func fetchTodos() async throws -> [Todo] {
        do {
            cache = try await provider.fetchTodos()
            return cache
        } catch  {
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
            try await provider.patchTodo(id: id, completed: cache[index].completed)
        } catch {
            cache[index].completed.toggle()
            throw error
        }
    }
}
