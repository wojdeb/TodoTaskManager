//
//  TodoTaskManagerTests.swift
//  TodoTaskManagerTests
//
//  Created by Wojtek on 30/05/2026.
//

import XCTest
@testable import TodoTaskManager

class MockTaskProvider: TaskProviding {
    var mockTodos: [Todo] = []
    var shouldFail = false
    
    func fetchTodos() async throws -> [Todo] {
        if shouldFail { throw URLError(.notConnectedToInternet) }
        return mockTodos
    }
    
    func patchTodo(id: Int, completed: Bool) async throws -> Todo {
        guard let index = mockTodos.firstIndex(where: { $0.id == id }) else {
            throw URLError(.badURL)
        }
        
        mockTodos[index].completed = completed
        return mockTodos[index]
    }
}

@MainActor
final class TodoTaskManagerTests: XCTestCase {
    func testFetchTodos_success() async {
        //given
        let mock = MockTaskProvider()
        mock.mockTodos = [Todo(id: 1, userId: 1, title: "Test", completed: false)]
        let vm = TaskViewModel(provider: mock)
        
        //when
        await vm.fetchTodos()
        
        //then
        XCTAssertEqual(vm.filteredTasks.count, 1)
    }
    
    func testFetchTodos_failure() async {
        //given
        let mock = MockTaskProvider()
        mock.shouldFail = true
        let vm = TaskViewModel(provider: mock)
        
        //when
        await vm.fetchTodos()
        
        //then
        XCTAssertEqual(vm.filteredTasks.count, 0)
        if case .error(let message) = vm.state {
            XCTAssertEqual("Something went wrong", message)
        } else {
            XCTFail("state should be error")
        }
    }
    
    func testToggleTodo_success() async {
        //given
        let mock = MockTaskProvider()
        mock.mockTodos = [Todo(id: 1, userId: 1, title: "Test", completed: false)]
        let vm = TaskViewModel(provider: mock)
        await vm.fetchTodos()
        
        //when
        await vm.toggleTodo(id: 1)
        
        //then
        XCTAssertEqual(vm.filteredTasks.first?.completed, true)
    }
    
    func testToggleTodo_failure() async {
        //given
        let mock = MockTaskProvider()
        mock.mockTodos = [Todo(id: 1, userId: 1, title: "Test", completed: false)]
        let vm = TaskViewModel(provider: mock)
        await vm.fetchTodos()
        
        //when
        await vm.toggleTodo(id: 99)
        
        //then
        XCTAssertEqual(vm.filteredTasks.first?.completed, false)
    }
}
