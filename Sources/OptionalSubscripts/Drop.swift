//
// github.com/screensailor 2021
//

public struct Drop<Route, Success, Failure> where Route: Hashable, Failure: Error {
    
    public let origin: Route
    public let destination: Route
    public let result: Result<Success, Failure>
    
    public init(origin: Route, destination: Route, result: Result<Success, Failure>) {
        self.origin = origin
        self.destination = destination
        self.result = result
    }
}

public extension Drop {
    
    subscript<A>(route: Route, as type: A.Type = A.self) -> Drop<Route, A, Failure> {
        get {
            fatalError("TODO")
        }
        set {
            fatalError("TODO")
        }
    }
}

public extension Drop {
    
    @inlinable func map<A>(_ transform: (Success) -> A) -> Drop<Route, A, Failure> {
        Drop<Route, A, Failure>(
            origin: origin,
            destination: destination,
            result: result.map(transform)
        )
    }
}
