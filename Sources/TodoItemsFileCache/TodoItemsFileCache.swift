import Foundation

public protocol FileCacheItem {
    var id: String { get }
    var json: Any { get }
    var csv: String { get }

    static func parse(json: Any) -> Self?
    static func parse(csv: String) -> Self?
}

public final class FileCache<T: FileCacheItem> {
    public init() { }

    // MARK: Properties
    public var todoItems = [String: T]()
    private let fileManager = FileManager.default
    private var path: URL?

    // MARK: Functions
    public func addNewTask(
        _ toDoItem: T
    ) {
        if todoItems[toDoItem.id] != nil {
            todoItems[toDoItem.id] = nil
        }
        todoItems[toDoItem.id] = toDoItem
    }

    @discardableResult
    public func deleteTask(
        id: String
    ) -> T? {
        return todoItems.removeValue(
            forKey: id
        )
    }

    public func fetchTodoItems(
        from fileName: String = "default.json"
    ) {
        guard let sourcePath = getSourcePath(
            with: fileName
        ) else {
            return
        }

        if fileManager.fileExists(
            atPath: sourcePath.path()
        ) {
            do {
                let jsons = try Data(
                    contentsOf: sourcePath,
                    options: .mappedIfSafe
                )

                guard let dictionary = try JSONSerialization.jsonObject(
                    with: jsons
                ) as? [Dictionary<
                       String,
                       Any
                       >] else {
                    print(
                        "fetchTodoItems() dictionary creation error"
                    )
                    return
                }

                todoItems = [String: T]()
                for items in dictionary {
                    guard let item = T.parse(
                        json: items
                    ) else {
                        print(
                            "fetchTodoItems() - parse error"
                        )
                        continue
                    }
                    addNewTask(
                        item
                    )
                }

            } catch {
                print(
                    "fetchTodoItems() - \(error.localizedDescription)"
                )
            }
        } else {
            print(
                "fetchTodoItems() - not exist"
            )
        }
    }

    public func saveTodoItems(
        to fileName: String = "default.json"
    ) {
        guard let sourcePath = getSourcePath(
            with: fileName
        ) else {
            return
        }

        let todoItemsJsons = todoItems.compactMap {
            $0.value.json
        }

        do {
            let json = try JSONSerialization.data(
                withJSONObject: todoItemsJsons
            )
            try json.write(
                to: sourcePath,
                options: []
            )
        } catch {
            print(
                "saveTodoItems(to fileName: String?) - error writing to the file: \(error.localizedDescription)"
            )
            return
        }
    }

    // MARK: Private Functions
    private func createSourcePath() {
        guard var documents = fileManager.urls(
            for: .documentDirectory,
            in: .userDomainMask
        ).first else {
            print(
                "getSourcePath(with fileName: String?) - error creating the source path"
            )
            return
        }
        documents.append(
            path: "CacheStorage"
        )

        do {
            try fileManager.createDirectory(
                at: documents,
                withIntermediateDirectories: true
            )
        } catch {
            print(
                """
                getSourcePath(with fileName: String?)
                - error creating the CacheStorage dir: \(error.localizedDescription)
                """
            )
        }

        path = documents
    }

    private func getSourcePath(
        with fileName: String = "default.json"
    ) -> URL? {
        if path == nil {
            createSourcePath()
        }
        guard var sourcePath = path else {
            return nil
        }

        sourcePath.append(
            path: fileName
        )

        return sourcePath
    }
}
