//
// github.com/screensailor 2021
//

public extension AsyncSequence {
    
    @inlinable func filter<A>(_: A.Type = A.self) -> AsyncCompactMapSequence<Self, A> {
        compactMap{ $0 as? A }
    }
    
    @inlinable func cast<A>(to: A.Type = A.self) -> AsyncThrowingMapSequence<Self, A> {
        map { o in
            guard let a = o as? A else {
                throw CastingError(value: self, to: A.self)
            }
            return a
        }
    }
}
