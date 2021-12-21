//
// github.com/screensailor 2021
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

extension Optional: Castable where Wrapped == Any {

    public func cast<A>(to: A.Type = A.self) throws -> A {
        guard let a = recursivelyFlatMapped as? A else {
            throw CastingError(value: self, to: A.self)
        }
        return a
    }
}

public extension Optional where Wrapped == Any {

    @inlinable subscript<A>(route: Location..., as type: A.Type = A.self) -> A {
        get throws {
            try self[route].cast()
        }
    }

    @inlinable subscript<A, Route>(route: Route, as type: A.Type = A.self) -> A where Route: Collection, Route.Index == Int, Route.Element == Location {
        get throws {
            try self[keyPath: Any?.keyPath(route)].cast()
        }
    }
    
    @inlinable subscript<A>(path: KeyPath, as type: A.Type = A.self) -> A {
        get throws {
            try self[keyPath: path].cast()
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

    @inlinable subscript<Route>(route: Route) -> Any? where Route: Collection, Route.Element == Location, Route.Index == Int {
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
    
    @inlinable subscript(fork: Location) -> Any? {
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
            guard let o = self as? [Any?], o.indices ~= index else {
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

#if canImport(Foundation)
import Foundation

public extension Optional where Wrapped == Any {
    
    enum JSONSerializationError: Error {
        case isNil
        case notValidJSONObject(Any)
    }
    
    func json(_ options: JSONSerialization.WritingOptions = [.fragmentsAllowed, .sortedKeys, .prettyPrinted]) throws -> Data {
        guard let o = self else {
            throw JSONSerializationError.isNil
        }
        guard JSONSerialization.isValidJSONObject([o]) else {
            throw JSONSerializationError.notValidJSONObject(o)
        }
        return try JSONSerialization.data(withJSONObject: o, options: options)
    }
}

public extension Data {
    
    func string(_ encoding: String.Encoding = .utf8) -> String {
        String(data: self, encoding: encoding) ?? ""
    }
}
#endif
