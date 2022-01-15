//
// github.com/screensailor 2022
//

public actor ValueStore<Value> {
    
    public var value: Value
    
    private(set) var count: UInt = 0
    private var continuations: [UInt: AsyncStream<Value>.Continuation] = [:]
    
    public init(_ initialValue: Value) {
        value = initialValue
    }
}

public extension ValueStore {
    
    func set(to newValue: Value) {
        value = newValue
        continuations.values.forEach { $0.yield(newValue) }
    }
    
    func `inout`(_ ƒ: (inout Value) -> ()) {
        ƒ(&value)
    }
    
    func stream(bufferingPolicy: AsyncStream<Value>.Continuation.BufferingPolicy = .bufferingNewest(1)) -> AsyncStream<Value> {
        AsyncStream(bufferingPolicy: bufferingPolicy) { continuation in
            insert(continuation)
        }
    }
}

private extension ValueStore {
    
    func insert(_ continuation: AsyncStream<Value>.Continuation) {
        continuation.yield(value)
        let id = count + 1
        count = id
        continuations[id] = continuation
        continuation.onTermination = { @Sendable [weak self] termination in
            guard let self = self else { return }
            Task {
                await self.remove(continuation: id)
            }
        }
    }
    
    func remove(continuation id: UInt) {
        continuations.removeValue(forKey: id)
    }
}
