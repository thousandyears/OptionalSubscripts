//
// github.com/screensailor 2021
//

import Combine

extension AsyncSequence {
    
    @usableFromInline func publisher() -> AnyPublisher<Element, Never> {
        let o = PassthroughSubject<Element, Never>()
        return o.handleEvents(receiveSubscription: { _ in
            Task {
                for try await element in self {
                    try Task.checkCancellation()
                    o.send(element)
                }
                o.send(completion: .finished)
            }
        }).eraseToAnyPublisher()
    }
}

public extension Optional.Store where Wrapped == Any {

    @inlinable func publisher(_ route: Location...) -> AnyPublisher<Any?, Never> {
        stream(route).publisher()
    }
    
    @inlinable func publisher<Route>(_ route: Route) -> AnyPublisher<Any?, Never> where Route: Collection, Route.Index == Int, Route.Element == Location {
        stream(route).publisher()
    }
}

public extension Dictionary.Store {
    
    @inlinable func publisher(_ key: Key) -> AnyPublisher<Value?, Never> {
        stream(key).publisher()
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
