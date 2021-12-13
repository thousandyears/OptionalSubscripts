//
//  Created by Milos Rankovic on 12/12/2021.
//

public protocol Castable {
    func cast<A>(to: A.Type) throws -> A
}

public extension Castable {
    
    @inlinable func cast(to: Self.Type = Self.self) throws -> Self {
        self
    }

    func cast<A>(to: A.Type = A.self) throws -> A {
        guard let a = self as? A else {
            throw CastingError(value: self, to: A.self)
        }
        return a
    }

    @inlinable func `as`<A>(_: A.Type = A.self) throws -> A {
        try cast(to: A.self)
    }
}

public struct CastingError: Error {
    
    public let value: Any?
    public let from: Any.Type
    public let to: Any.Type
    
    public init<A>(value: Any?, to: A.Type) {
        self.value = value
        self.from = type(of: value)
        self.to = A.self
    }
}

extension CastingError: CustomStringConvertible {

    public var description: String {
        "\(CastingError.self)(from: \(from), to: \(to), value: \(value as Any))"
    }
}
