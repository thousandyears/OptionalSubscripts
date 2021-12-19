//
// github.com/screensailor 2021
//

public protocol Geyser {

    associatedtype GushID: Hashable
    
    associatedtype Gushes: AsyncSequence where Gushes.Element == Any?
    
    associatedtype GushToRouteMapping: AsyncSequence where GushToRouteMapping.Element == (id: GushID, route: Optional<Any>.Route)?

    func stream(_ gush: GushID) async -> Gushes
    
    func source<Route>(of route: Route) async -> GushToRouteMapping where Route: Collection, Route.Index == Int, Route.Element == Optional<Any>.Location
}
