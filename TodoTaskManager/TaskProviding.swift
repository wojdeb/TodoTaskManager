//
//  TasksProviding.swift
//  TodoTaskManager
//
//  Created by Wojtek on 30/05/2026.
//

import Foundation

protocol TaskProviding {
    func fetchTodos() async throws -> [Todo]
    func patchTodo(id: Int, completed: Bool) async throws -> Todo
}

struct NetworkTaskProvider: TaskProviding {
    func fetchTodos() async throws -> [Todo] {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/todos") else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        let (data, response) = try await URLSession.shared.data(from: url)
        
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
            print("Network error")
            throw URLError(.badServerResponse)
        }

        return try JSONDecoder().decode([Todo].self, from: data)
        
    }

    
    func patchTodo(id: Int, completed: Bool) async throws -> Todo {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/todos/\(id)") else {
            print("Invalid URL")
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = try JSONEncoder().encode(["completed": completed])
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let response = response as? HTTPURLResponse, (200...299).contains(response.statusCode) else {
            print("Network error")
            throw URLError(.badServerResponse)
        }
        
        print("id: \(id), completed: \(completed) PATCH EXECUTED")
        return try JSONDecoder().decode(Todo.self, from: data)
    }
}
