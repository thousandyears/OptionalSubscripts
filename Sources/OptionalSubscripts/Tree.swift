//
// github.com/screensailor 2021
//

struct Tree<Key, Value> where Key: Hashable {
    
    var value: Value?
    var branches: [Key: Tree]
    
    init(value: Value? = nil, branches: [Key: Tree] = [:]) {
        self.value = value
        self.branches = branches
    }
}

extension Tree {
    
    @inlinable subscript(route: Key..., inserting defaultValue: Value) -> Value {
        mutating get {
            self[route, inserting: defaultValue]
        }
        set {
            self[route] = newValue
        }
    }
    
    subscript<Route>(route: Route, inserting defaultValue: Value) -> Value where Route: Collection, Route.Element == Key {
        mutating get {
            if let o: Value = self[route] {
                return o
            } else {
                self[route] = defaultValue
                return defaultValue
            }
        }
        set {
            self[route] = newValue
        }
    }

    @inlinable subscript(route: Key..., inserting defaultTree: Tree) -> Tree {
        mutating get {
            self[route, inserting: defaultTree]
        }
        set {
            self[route] = newValue
        }
    }
    
    subscript<Route>(route: Route, inserting defaultTree: Tree) -> Tree where Route: Collection, Route.Element == Key {
        mutating get {
            if let o: Tree = self[route] {
                return o
            } else {
                self[route] = defaultTree
                return defaultTree
            }
        }
        set {
            self[route] = newValue
        }
    }
}

extension Tree {
    
    @inlinable subscript(route: Key...) -> Value? {
        get {
            self[route]
        }
        set {
            self[route] = newValue
        }
    }

    subscript<Route>(route: Route) -> Value? where Route: Collection, Route.Element == Key {
        get {
            self[route]?.value
        }
        set {
            guard let key = route.first else {
                value = newValue
                return
            }
            branches[key, default: Tree()][route.dropFirst()] = newValue
        }
    }
}

extension Tree {
    
    @inlinable subscript(route: Key...) -> Tree? {
        get {
            self[route]
        }
        set {
            self[route] = newValue
        }
    }

    subscript<Route>(route: Route) -> Tree? where Route: Collection, Route.Element == Key {
        get {
            guard let key = route.first else {
                return self
            }
            return branches[key]?[route.dropFirst()]
        }
        set {
            guard let key = route.first else {
                value = newValue?.value
                branches = newValue?.branches ?? [:]
                return
            }
            branches[key, default: Tree()][route.dropFirst()] = newValue
        }
    }
}

extension Tree where Key: Comparable {
    
    func routes<Route>(affectedByChanging route: Route) -> [[Key]] where Route: Collection, Route.Element == Key {
        var o = route.lineage.reversed().map(Array.init)
        let subtree: Tree? = self[route]
        subtree?.traverse{ subroute, _ in o.append(route + subroute) }
        return o
    }
}

extension Tree where Key: Comparable {

    /// Depth first traversal.
    func traverse(sorted: Bool = true, yield: ((route: [Key], value: Value?)) throws -> ()) rethrows {
        try Self.traverse(sorted: sorted, route: [], tree: self, yield: yield)
    }

    private static func traverse(sorted: Bool = true, route: [Key], tree: Tree, yield: ((route: [Key], value: Value?)) throws -> ()) rethrows {
        try yield((route, tree.value))
        if sorted {
            for (key, tree) in tree.branches.sorted(by: { $0.key < $1.key }) {
                try traverse(sorted: sorted, route: route + [key], tree: tree, yield: yield)
            }
        } else {
            for (key, tree) in tree.branches {
                try traverse(sorted: sorted, route: route + [key], tree: tree, yield: yield)
            }
        }
    }
}

extension Tree: CustomStringConvertible {
    
    var description: String {
        "\(Self.self)(value: \(String(describing: value)) branches count: \(branches.count))"
    }
}

extension Tree: CustomDebugStringConvertible where Key: Comparable {

    var debugDescription: String {
        var o = "\(Self.self)"
        traverse { route, value in
            let t = repeatElement("\t|", count: route.count + 1).joined()
            o += "\n\(t)\(route):\n\(t)\(value.map(String.init(describing:)) ?? "nil")"
        }
        return o
    }
}
