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
            throw TaskError.badUrl(url: "https://jsonplaceholder.typicode.com/todos")
        }
        
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(from: url)
        } catch {
            throw mapError(error)
        }
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw TaskError.invalidResponse(body: "Invalid response type")
        }

        guard (200...299).contains(httpResponse.statusCode) else {
            throw TaskError.serverError(statusCode: httpResponse.statusCode)
        }

        do {
            return try JSONDecoder().decode([Todo].self, from: data)
        } catch {
            throw mapError(error)
        }
    }

    
    func patchTodo(id: Int, completed: Bool) async throws -> Todo {
        guard let url = URL(string: "https://jsonplaceholder.typicode.com/todos/\(id)") else {
            throw TaskError.badUrl(url: "https://jsonplaceholder.typicode.com/todos/\(id)")
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "PATCH"
        request.httpBody = try JSONEncoder().encode(["completed": completed])
        
        let (data, response): (Data, URLResponse)
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw mapError(error)
        }
        
        guard let response = response as? HTTPURLResponse else {
            throw TaskError.invalidResponse(body: "Invalid response type")
        }
        guard (200...299).contains(response.statusCode) else {
            throw TaskError.serverError(statusCode: response.statusCode)
        }
                
        do {
            return try JSONDecoder().decode(Todo.self, from: data)
        } catch {
            throw mapError(error)
        }
    }
    
    private func mapError(_ error: Error) -> TaskError {
        if let urlError = error as? URLError {
            switch urlError.code {
                case .notConnectedToInternet: return .noConnection
                case .timedOut: return .timeout
                case .badServerResponse: return .invalidResponse(body: "No response body available")
                default: return .unknown(error)
            }
            
        }
        if let urlError = error as? DecodingError {
            return .decodingFailed
        }
        
        return .unknown(error)
    }
}
