//
//  SnapshotTests.swift
//  TodoTaskManager
//
//  Created by Wojtek on 16/09/2026.
//

import SnapshotTesting
import SwiftUI
import XCTest
@testable import TodoTaskManager

class SnapshotTests: XCTestCase {
    func testTaskRow_active() {
        let todo = Todo(id: 1, userId: 1, title: "Test", completed: false)
        let view = TaskRow(task: todo, onTap: {})
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 390, height: 80)))
    }
    
    func testTaskRow_completed() {
        let todo = Todo(id: 1, userId: 1, title: "Test", completed: true)
        let view = TaskRow(task: todo, onTap: {})
        assertSnapshot(of: view, as: .image(layout: .fixed(width: 390, height: 80)))
    }
    
    func testErrorView() {
        let view = ErrorView(message: "Test", retry: {})
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
    
    @MainActor
    func testLoadingView() {
        let mock = MockTodoRepository()
        let vm = TaskViewModel(repository: mock)
        
        let view = TaskView(vm: vm)
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
    
    @MainActor
    func testEmptyView() {
        let mock = MockTodoRepository()
        let vm = TaskViewModel(repository: mock)
        vm.setState(.empty)
        
        let view = TaskView(vm: vm)
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
    
    @MainActor
    func testContentView() async {
        let todos = [
            Todo(id: 1, userId: 1, title: "Test1", completed: false),
            Todo(id: 2, userId: 1, title: "Test2", completed: true),
            Todo(id: 3, userId: 1, title: "Test3", completed: true),
            Todo(id: 4, userId: 1, title: "Test4", completed: false)
        ]
        let mock = MockTodoRepository()
        let vm = TaskViewModel(repository: mock)
        
        vm.setState(.content(tasks: todos))
        
        let view = TaskView(vm: vm)
        assertSnapshot(of: view, as: .image(layout: .device(config: .iPhone13Pro)))
    }
    
    @MainActor
    func testContentView_darkmode() async {
        let todos = [
            Todo(id: 1, userId: 1, title: "Test1", completed: false),
            Todo(id: 2, userId: 1, title: "Test2", completed: true),
            Todo(id: 3, userId: 1, title: "Test3", completed: true),
            Todo(id: 4, userId: 1, title: "Test4", completed: false)
        ]
        let mock = MockTodoRepository()
        let vm = TaskViewModel(repository: mock)
        
        vm.setState(.content(tasks: todos))
        
        let view = TaskView(vm: vm)
        
        assertSnapshot(of: view, as: .image(
            layout: .device(config: .iPhone13Pro),
            traits: UITraitCollection(userInterfaceStyle: .dark)
        ))
    }
}
