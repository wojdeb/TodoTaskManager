//
//  TaskView.swift
//  TodoTaskManager
//
//  Created by Wojtek on 31/05/2026.
//

import SwiftUI

struct TaskView: View {
    @ObservedObject var vm: TaskViewModel
    
    var body: some View {
        NavigationStack {
            content
                .task {
                    await vm.fetchTodos()
                }
        }
    }
    
    @ViewBuilder
    private var content: some View {
        switch vm.state {
        case .loading:
            ProgressView()
        case .error(let message):
            ErrorView(message: message, retry: {
                    Task { await vm.refresh() }
                })
        case .empty:
            EmptyView()
        case .content:
            VStack {
                Picker(selection: $vm.filter, label: Text("Filter")) {
                    ForEach(TaskFilter.allCases, id: \.self) { filter in
                        Text(filter.title).tag(filter)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)
                
                List {
                    Section("To do") {
                        ForEach(vm.filteredTasks.filter { !$0.completed }) { task in
                            TaskRow(task: task, onTap: {await vm.toggleTodo(id: task.id)})
                        }
                    }
                    Section("Completed") {
                        ForEach(vm.filteredTasks.filter { $0.completed }) { task in
                            TaskRow(task: task, onTap: {await vm.toggleTodo(id: task.id)})
                        }
                    }
                }
                .searchable(text: $vm.searchQuery, prompt: "Search tasks...")
                .refreshable {
                    await vm.refresh()
                }
            }
            
        }
    }
}

struct TaskRow: View {
    let task: Todo
    let onTap: () async -> Void
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: task.completed ? "checkmark.circle.fill" : "circle")
            VStack(alignment: .leading, spacing: 2) {
                Text(task.title)
                    .foregroundColor(task.completed ? .secondary : .primary)
                Text("User: \(task.userId)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .onTapGesture {
                Task { await onTap() }
            }
            Spacer()
        }
    }
}

struct ErrorView: View {
    let message: String
        let retry: () -> Void
        
        var body: some View {
            VStack(spacing: 16) {
                Text(message)
                Button("Try again") { retry() }
            }
        }
}

#Preview {
    TaskView(vm: TaskViewModel(provider: NetworkTaskProvider()))
}
