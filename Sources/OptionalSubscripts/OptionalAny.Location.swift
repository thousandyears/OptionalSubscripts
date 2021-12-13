//
//  Created by Milos Rankovic on 12/12/2021.
//

public extension Optional where Wrapped == Any {
    
    typealias Route = [Location]

    enum Location {
        case index(Int)
        case key(String)
    }
}

public extension Optional.Location where Wrapped == Any {

    @inlinable var key: String? {
        switch self {
        case .index: return nil
        case .key(let o): return o
        }
    }

    @inlinable var index: Int? {
        switch self {
        case .index(let o): return o
        case .key: return nil
        }
    }
}

extension Optional.Location: CodingKey where Wrapped == Any {

    @inlinable public var stringValue: String { description }
    @inlinable public init?(stringValue: String) { self = .key(stringValue) }

    @inlinable public var intValue: Int? { index }
    @inlinable public init?(intValue: Int) { self = .index(intValue) }
}

extension Optional.Location: ExpressibleByStringLiteral, ExpressibleByExtendedGraphemeClusterLiteral, ExpressibleByUnicodeScalarLiteral where Wrapped == Any {
    
    @inlinable public init(stringLiteral value: String) {
        self = .key(value)
    }
    
    @inlinable public init(extendedGraphemeClusterLiteral value: String) {
        self = .key(value)
    }
    
    @inlinable public init(unicodeScalarLiteral value: String) {
        self = .key(value)
    }
}

extension Optional.Location: ExpressibleByIntegerLiteral where Wrapped == Any {
    
    @inlinable public init(integerLiteral value: IntegerLiteralType) {
        self = .index(value)
    }
}

extension Optional.Location: Comparable where Wrapped == Any {
    
    public static func < (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs) {
        case (.index, .key): return true
        case (.key, .index): return false
        case let (.index(l), .index(r)): return l < r
        case let (.key(l), .key(r)): return l < r
        }
    }
}

extension Optional.Location: Equatable where Wrapped == Any {

    @inlinable public static func == (lhs: Self, rhs: Self) -> Bool {
        switch (lhs, rhs)
        {
        case let (.index(l), .index(r)): return l == r
        case let (.key(l), .key(r)): return l == r
        default: return false
        }
    }
}

extension Optional.Location: Hashable where Wrapped == Any {

    @inlinable public func hash(into hasher: inout Hasher) {
        switch self {
        case let .index(o): hasher.combine(o)
        case let .key(o): hasher.combine(o)
        }
    }
}

extension Optional.Location: CustomStringConvertible, CustomDebugStringConvertible where Wrapped == Any {

    @inlinable public var description: String {
        switch self {
        case let .key(o): return o
        case let .index(o): return String(describing: o)
        }
    }

    @inlinable public var debugDescription: String {
        description
    }
}

public extension Sequence where Element == Optional<Any>.Location {

    @inlinable func joined(separator: String = ".") -> String {
        lazy.map(\.description).joined(separator: separator)
    }
}

#if canImport(GameplayKit)
import GameplayKit

public extension Optional where Wrapped == Any {
    
    struct RandomRoutes {
        
        public var keys: [String]
        public var indices: [Int]
        public var keyBias: Float
        public var length: ClosedRange<Int>
        public var seed: Int
        
        public init(
            keys: [String],
            indices: [Int],
            keyBias bias: Float = 0.5,
            length: ClosedRange<Int>,
            seed: Int = 0
        ) {
            self.keys = keys
            self.indices = indices
            self.keyBias = bias
            self.length = length
            self.seed = seed
        }
        
        public func generate(count: Int) -> [Route] {
            let random = GKARC4RandomSource(seed: "seed \(seed)".data(using: .utf8)!)
            return (0..<max(0, count)).map{ _ in generate(random) }
        }
        
        private func generate(_ random: GKARC4RandomSource) -> Route {
            let lower = max(0, length.lowerBound)
            let upper = max(lower, length.upperBound)
            let count = random.nextInt(upperBound: upper - lower + 1) + lower
            return (0 ..< count).compactMap{ _ -> Location? in
                random.nextUniform() < keyBias
                ? random.randomElement(in: keys).map{ .key($0) }
                : random.randomElement(in: indices).map{ .index($0) }
            }
        }
    }
}

private extension GKARC4RandomSource {
    
    func randomElement<C: Collection>(in a: C) -> C.Element? where C.Index == Int {
        guard !a.isEmpty else { return nil }
        return a[nextInt(upperBound: a.count)]
    }
}
#endif
