//
//  TaskModel.swift
//  TodoTaskManager
//
//  Created by Wojtek on 30/05/2026.
//

struct Todo: Identifiable, Codable {
    let id: Int
    let userId: Int
    let title: String
    var completed: Bool
}
