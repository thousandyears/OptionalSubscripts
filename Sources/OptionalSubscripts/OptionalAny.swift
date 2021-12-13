//
//  Created by Milos Rankovic on 12/12/2021.
//

protocol RecursivelyWrapped {
    var recursivelyFlatMapped: Any? { get }
}

extension Optional: RecursivelyWrapped {

    @inlinable public var recursivelyFlatMapped: Any? {
        flatMap(Any?.init)
    }
}

public extension Optional where Wrapped == Any {
    
    init(_ any: Any) {
        self = (any as? RecursivelyWrapped)?.recursivelyFlatMapped ?? any
    }
}

public extension Optional where Wrapped == Any {
    
    typealias KeyPath = WritableKeyPath<Any?, Any?>

    @inlinable static func keyPath(_ route: Location...) -> KeyPath {
        (\Any?.self).appending(route: route)
    }
    
    @inlinable static func keyPath<Route>(_ route: Route) -> KeyPath where Route: Collection, Route.Index == Int, Route.Element == Location {
        (\Any?.self).appending(route: route)
    }
}

public extension WritableKeyPath where Root == Any?, Value == Any? {
    
    func appending<Route>(route o: Route) -> WritableKeyPath where Route: Collection, Route.Index == Int, Route.Element == Optional<Any>.Location {
        /*
         The performance of repeatedly calling `appending(path:)` is currently (Dec 2021) rather poor.
         This implementation is an optimisation workaround over something like:
         
         var o = \Any?.self
         
         for fork in route {
             switch fork {
             case let .key(key): o = o.appending(path: \.[key])
             case let .index(index): o = o.appending(path: \.[index])
             }
         }
         
         Note that Working with index offsets so that Array.init can be avoided did not yield better performance.
        */
        switch o.count {
        case 0: return self
        case 1: return appending(path: \.[o[0]])
        case 2: return appending(path: \.[o[0]][o[1]])
        case 3: return appending(path: \.[o[0]][o[1]][o[2]])
        case 4: return appending(path: \.[o[0]][o[1]][o[2]][o[3]])
        case 5: return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]])
        case 6: return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]][o[5]])
        case 7: return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]][o[5]][o[6]])
        case 8: return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]][o[5]][o[6]][o[7]])
        case 9: return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]][o[5]][o[6]][o[7]][o[8]])
        default:
            return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]][o[5]][o[6]][o[7]][o[8]])
                .appending(route: Array(o.dropFirst(9)))
        }
    }
}

extension Optional: Castable where Wrapped == Any {

    public func cast<A>(to: A.Type = A.self) throws -> A {
        guard let a = recursivelyFlatMapped as? A else {
            throw CastingError(value: self, to: A.self)
        }
        return a
    }

    @inlinable public subscript<A>(route: Location..., as type: A.Type = A.self) -> A {
        get throws {
            try self[route].cast()
        }
    }

    public subscript<A, Route>(route: Route, as type: A.Type = A.self) -> A where Route: Collection, Route.Element == Location, Route.Index == Int {
        get throws {
            try self[keyPath: Any?.keyPath(route)].cast()
        }
    }
}

public extension Optional where Wrapped == Any {

    @inlinable subscript(route: Location...) -> Any? {
        get {
            self[route]
        }
        set {
            self[route] = newValue
        }
    }

    subscript<Route>(route: Route) -> Any? where Route: Collection, Route.Element == Location, Route.Index == Int {
        get {
            self[keyPath: Any?.keyPath(route)]
        }
        set {
            self[keyPath: Any?.keyPath(route)] = newValue
        }
    }

    @inlinable subscript(path: KeyPath) -> Any? {
        get {
            self[keyPath: path]
        }
        set {
            self[keyPath: path] = newValue
        }
    }
    
    @inlinable subscript() -> Any? {
        get {
            self
        }
        set {
            self = newValue
        }
    }
    
    subscript(fork: Location) -> Any? {
        get {
            switch fork {
            case let .key(key): return self[key]
            case let .index(index): return self[index]
            }
        }
        set {
            switch fork {
            case let .key(key): return self[key] = newValue
            case let .index(index): return self[index] = newValue
            }
        }
    }
    
    subscript(key: String) -> Any? {
        get {
            (self as? [String: Any])?[key]
        }
        set {
            var o = self as? [String: Any] ?? [:]
            o[key] = newValue
            self = o.isEmpty ? nil : o
        }
    }
    
    subscript(index: Int) -> Any? {
        get {
            guard 0... ~= index, let o = self as? [Any?], o.indices.contains(index) else {
                return nil
            }
            return o[index]
        }
        set {
            guard 0... ~= index else {
                return
            }
            var o = self as? [Any?] ?? []
            o.append(contentsOf: repeatElement(nil, count: max(0, index - o.endIndex + 1)))
            o[index] = newValue
            if o.last ?? nil == nil {
                guard let i = o.dropLast().lastIndex(where: { $0 != nil }).map({ $0 + 1 }) else {
                    self = nil
                    return
                }
                o.removeSubrange(i...)
            }
            self = o
        }
    }
}
