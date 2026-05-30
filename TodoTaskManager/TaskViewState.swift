//
//  TaskViewState.swift
//  TodoTaskManager
//
//  Created by Wojtek on 30/05/2026.
//

enum TasksViewState {
    case loading
    case content(tasks: [Todo])
    case error(message: String)
    case empty
    
}
