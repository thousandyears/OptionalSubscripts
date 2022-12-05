//
// github.com/screensailor 2021
//

public extension Dictionary {
    
    actor Store {
        
        public typealias BatchUpdates = [(Key, Value?)]
        public typealias TransactionLevel = UInt

        public var dictionary: Dictionary
        
        typealias ID = UInt
        typealias Subject = [ID: AsyncStream<Value?>.Continuation]

        var count: UInt = 0
        var subscriptions: [Key: Subject] = [:]

        public private(set) var transactionLevel: TransactionLevel = 0
        public private(set) var transactionUpdates: [TransactionLevel: BatchUpdates] = [:]

        public init(_ dictionary: Dictionary = [:]) { self.dictionary = dictionary }
    }
}

public extension Dictionary.Store {
    
    typealias BufferingPolicy = AsyncStream<Value?>.Continuation.BufferingPolicy

    func stream(_ key: Key, bufferingPolicy: BufferingPolicy = .bufferingNewest(1)) -> AsyncStream<Value?> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            self.insert(continuation, for: key)
        }
    }

    private func insert(_ continuation: AsyncStream<Value?>.Continuation, for key: Key) {
        continuation.yield(dictionary[key])
        count += 1
        let id = count
        subscriptions[key, default: [:]][id] = continuation
        continuation.onTermination = { @Sendable [weak self] termination in
            guard let self = self else { return }
            Task {
                await self.remove(continuation: id, for: key)
            }
        }
    }

    private func remove(continuation id: ID, for key: Key) {
        subscriptions[key]?[id] = nil
        if subscriptions[key]?.isEmpty == true {
            subscriptions[key] = nil
        }
    }
}

public extension Dictionary.Store {
    
    var isInTransaction: Bool {
        transactionLevel > 0
    }

    func transaction(_ updates: (Dictionary.Store) async throws -> ()) async rethrows {
        transactionLevel += 1
        do {
            try await updates(self)
            let levelUpdates = transactionUpdates.removeValue(forKey: transactionLevel) ?? []
            transactionLevel -= 1
            if transactionLevel > 0 {
                transactionUpdates[transactionLevel, default: []].append(contentsOf: levelUpdates)
            } else {
                batch(levelUpdates)
            }
        }
        catch {
            transactionUpdates.removeValue(forKey: transactionLevel)
            transactionLevel -= 1
            throw error
        }
    }
    
    func batch(_ updates: BatchUpdates) {
        var array: [Key] = []
        var set: Set<Key> = []
        for (key, value) in updates {
            dictionary[key] = value
            if set.insert(key).inserted {
                array.append(key)
            }
        }
        for key in array {
            let value = dictionary[key]
            subscriptions[key]?.values.forEach { $0.yield(value) }
        }
    }
}

public extension Dictionary.Store {
    
    func get(_ key: Key) throws -> Value {
        guard let o = dictionary[key] else {
            throw Error.nilAt(key: key)
        }
        return o
    }

    func set(_ key: Key, to value: Value?) {
        guard transactionLevel == 0 else {
            return transactionUpdates[transactionLevel, default: []].append((key, value))
        }
        dictionary[key] = value
        subscriptions[key]?.values.forEach { $0.yield(value) }
    }
}

public extension Dictionary.Store {
    
    @inlinable subscript<A>(_ key: Key, as a: A.Type = A.self) -> A {
        get throws {
            try get(key)
        }
    }

    func get<A>(_ key: Key, as a: A.Type = A.self) throws -> A {
        guard let any = dictionary[key] else {
            throw Error.nilAt(key: key)
        }
        guard let a = any as? A else {
            throw Error.casting(key: key, from: type(of: any), to: A.self)
        }
        return a
    }
}

public extension Dictionary.Store {

    func contains(_ key: Key) -> Bool {
        dictionary[key] != nil
    }
}

public extension Dictionary.Store {
    
    enum Error: Swift.Error {
        case nilAt(key: Key)
        case casting(key: Key, from: Any.Type, to: Any.Type)
    }
}
