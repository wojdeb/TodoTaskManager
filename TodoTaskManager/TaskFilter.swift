//
//  TaskFilter.swift
//  TodoTaskManager
//
//  Created by Wojtek on 31/05/2026.
//

enum TaskFilter: CaseIterable {
    case all
    case active
    case done
    
    var title: String {
        switch self {
        case .all: return "All"
        case .active: return "Active"
        case .done: return "Done"
        }
    }
}
