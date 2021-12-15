//
// github.com/screensailor 2021
//

import Combine

public extension Optional.Store where Wrapped == Any {

    @inlinable func publisher(_ route: Location...) -> AnyPublisher<Any?, Never> {
        publisher(route)
    }
    
    func publisher<Route>(_ route: Route) -> AnyPublisher<Any?, Never> where Route: Collection, Route.Index == Int, Route.Element == Location {
        let stream = self.stream(route)
        let o = PassthroughSubject<Any?, Never>()
        return o.handleEvents(receiveSubscription: { _ in
            Task {
                for await element in stream {
                    try Task.checkCancellation()
                    o.send(element)
                }
                o.send(completion: .finished)
            }
        }).eraseToAnyPublisher()
    }
}

public extension Dictionary.Store {
    
    func publisher(_ key: Key) -> AnyPublisher<Value?, Never> {
        let stream = self.stream(key)
        let o = PassthroughSubject<Value?, Never>()
        return o.handleEvents(receiveSubscription: { _ in
            Task {
                for await element in stream {
                    try Task.checkCancellation()
                    o.send(element)
                }
                o.send(completion: .finished)
            }
        }).eraseToAnyPublisher()
    }
}

public extension Publisher {
    
    @inlinable func filter<A>(_: A.Type = A.self) -> Publishers.CompactMap<Self, A> {
        compactMap{ $0 as? A }
    }
    
    @inlinable func cast<A>(to: A.Type = A.self) -> Publishers.TryMap<Self, A> {
        tryMap { o in
            guard let a = o as? A else {
                throw CastingError(value: self, to: A.self)
            }
            return a
        }
    }
}
