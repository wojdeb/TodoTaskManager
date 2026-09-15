//
//  TodoTaskManagerTests.swift
//  TodoTaskManagerTests
//
//  Created by Wojtek on 30/05/2026.
//

import XCTest
import SwiftData
@testable import TodoTaskManager

class MockTodoRepository: TodoRepository {
    private var cache: [Todo] = []

    var mockTodos: [Todo] = []
    var shouldFailFetch = false
    var shouldFailToggle = false
    
    func fetchTodos() async throws -> [Todo] {
        if shouldFailFetch { throw TaskError.noConnection }
        return mockTodos
    }
    
    func toggleTodo(id: Int, completed: Bool) async throws {
        if shouldFailToggle { throw TaskError.serverError(statusCode: 500) }
        guard let index = mockTodos.firstIndex(where: { $0.id == id }) else { return }
        mockTodos[index].completed = completed
    }
}

@MainActor
final class TodoTaskManagerTests: XCTestCase {
    var mock: MockTodoRepository!
    var vm: TaskViewModel!
    
    override func setUp() async throws {
        mock = MockTodoRepository()
        vm = TaskViewModel(repository: mock)
    }
    
    override func tearDown() {
        mock = nil
        vm = nil
        super.tearDown()
    }
    
    func testFetchTodos_success() async {
        mock.mockTodos = [Todo(id: 1, userId: 1, title: "Test", completed: false)]
        await vm.fetchTodos()
        XCTAssertEqual(vm.filteredTasks.count, 1)
    }
    
    func testFetchTodos_failure() async {
        mock.shouldFailFetch = true
        await vm.fetchTodos()
        XCTAssertEqual(vm.filteredTasks.count, 0)
        if case .error(let message) = vm.state {
            XCTAssertEqual("No internet connection. Check your network and try again.", message)
        } else {
            XCTFail("state should be error")
        }
    }
    
    func testToggleTodo_success() async {
        mock.mockTodos = [Todo(id: 1, userId: 1, title: "Test", completed: false)]
        await vm.fetchTodos()
        await vm.toggleTodo(id: 1)
        XCTAssertEqual(vm.filteredTasks.first?.completed, true)
    }
    
    func testToggleTodo_failure() async {
        mock.mockTodos = [Todo(id: 1, userId: 1, title: "Test", completed: false)]
        await vm.fetchTodos()
        await vm.toggleTodo(id: 99)
        XCTAssertEqual(vm.filteredTasks.first?.completed, false)
    }
    
    func testFilterActive_returnsActiveTasks() async {
        mock.mockTodos = [
            Todo(id: 1, userId: 1, title: "Test1", completed: false),
            Todo(id: 2, userId: 1, title: "Test2", completed: true),
            Todo(id: 3, userId: 1, title: "Test3", completed: true),
            Todo(id: 4, userId: 1, title: "Test4", completed: false)
        ]

        await vm.fetchTodos()
        
        XCTAssertEqual(vm.activeTasks.count, 2)
    }
    
    func testFilterDone_returnsCompletedTasks() async {
        mock.mockTodos = [
            Todo(id: 1, userId: 1, title: "Test1", completed: false),
            Todo(id: 2, userId: 1, title: "Test2", completed: true),
            Todo(id: 3, userId: 1, title: "Test3", completed: true),
            Todo(id: 4, userId: 1, title: "Test4", completed: false),
            Todo(id: 5, userId: 1, title: "Test5", completed: true)
        ]

        await vm.fetchTodos()
        
        XCTAssertEqual(vm.completedTasks.count, 3)
    }
    
    func testFilterAll_returnsAllTasks() async {
        mock.mockTodos = [
            Todo(id: 1, userId: 1, title: "Test1", completed: false),
            Todo(id: 2, userId: 1, title: "Test2", completed: true),
            Todo(id: 3, userId: 1, title: "Test3", completed: true),
            Todo(id: 4, userId: 1, title: "Test4", completed: false),
            Todo(id: 5, userId: 1, title: "Test5", completed: true)
        ]

        await vm.fetchTodos()
        
        XCTAssertEqual(vm.filteredTasks.count, 5)
    }
    
    func testSearchQuery_returnsMatchingTasks() async {
        mock.mockTodos = [
            Todo(id: 1, userId: 1, title: "Test1", completed: false),
            Todo(id: 2, userId: 1, title: "Test2_QUERY", completed: true),
            Todo(id: 3, userId: 1, title: "QUERY_Test3", completed: true),
            Todo(id: 4, userId: 1, title: "Test4", completed: false),
            Todo(id: 5, userId: 1, title: "Te_QUERY_st5", completed: true)
        ]
        
        await vm.fetchTodos()
        vm.searchQuery = "QUERY"
        
        XCTAssertEqual(vm.filteredTasks.count, 3)
    }
    
    func testSearchQuery_empty_returnsAllFilteredTasks() async {
        mock.mockTodos = [
            Todo(id: 1, userId: 1, title: "Test1", completed: false),
            Todo(id: 2, userId: 1, title: "Test2", completed: true)
            ]
        
        await vm.fetchTodos()
        vm.searchQuery = ""
        
        XCTAssertEqual(vm.filteredTasks.count, 2)
    }
    
    func testFetchTodos_emptyResponse_emptyState() async {
        mock.mockTodos = []
        
        await vm.fetchTodos()
        
        guard case .empty = vm.state else {
            XCTFail("State shoud be empty")
            return
        }
    }
    
    func testToggleTodo_rollback_onFailure() async {
        mock.mockTodos = [
            Todo(id: 1, userId: 1, title: "Test1", completed: false),
            Todo(id: 2, userId: 1, title: "Test2", completed: true)
            ]
        
        await vm.fetchTodos()
        mock.shouldFailToggle = true
        await vm.toggleTodo(id: 1)
        
        XCTAssertEqual(vm.filteredTasks.first?.completed, false)
        guard case .content = vm.state else {
            XCTFail("State should be content after rollback")
            return
        }
    }
}
