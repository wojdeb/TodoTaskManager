# TodoTaskManager

Simple SwiftUI app for browsing and managing tasks.

The app fetches todos from JSONPlaceholder API and displays them in a list divided into active and completed tasks.

## Features

* Fetch todos from API
* Display tasks in sections: To do / Completed
* Filter tasks: All / Active / Completed
* Pull to refresh
* Search tasks
* Loading, empty and error states
* Toggle task status with optimistic update

## Tech

* SwiftUI
* async/await
* URLSession
* Codable
* ObservableObject
* XCTest

## API

```text
GET https://jsonplaceholder.typicode.com/todos
PATCH https://jsonplaceholder.typicode.com/todos/{id}
```

## Structure

The app uses a simple MVVM approach:

* `TaskView` — main SwiftUI view
* `TaskViewModel` — state and presentation logic
* `TaskProviding` — protocol for fetching/updating tasks
* `NetworkTaskProvider` — API implementation
* `TasksViewState` — loading/content/empty/error states

## Tests

Basic ViewModel tests are included using a mock task provider.
