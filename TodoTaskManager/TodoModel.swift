//
//  TodoModel.swift
//  TodoTaskManager
//
//  Created by Wojtek on 17/08/2026.
//

import SwiftData

@Model
class TodoModel {
    var id: Int
    var userId: Int
    var title: String
    var completed: Bool
    
    init(id: Int, userId: Int, title: String, completed: Bool) {
        self.id = id
        self.userId = userId
        self.title = title
        self.completed = completed
    }
}

extension TodoModel {
    func toTodo() -> Todo {
        Todo(id: id, userId: userId, title: title, completed: completed)
    }
    
    convenience init(from todo: Todo) {
        self.init(id: todo.id, userId: todo.userId, title: todo.title, completed: todo.completed)
    }
}
