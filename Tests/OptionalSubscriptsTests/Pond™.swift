//
// github.com/screensailor 2021
//

@testable import OptionalSubscripts

import Combine

final class Pond™: Hopes {
    
    typealias Route = Optional<Any>.Route
    
    func test_versioning() async throws {
        
        let db = Database()
        let pond = Any?.Pond(source: db)
        
        await db.store.set("v/2.0/way/to", "my", "heart", to: "🤍")
        
        var hearts = ""
        
    forloop:
        for await heart in pond.stream("way", "to", "my", "heart").filter(String?.self) {
            hearts += heart ?? ""
            switch heart
            {
            case nil where hearts.isEmpty:
                       await db.store.set("v/1.0/way/to", "my", "heart", to: "❤️")
            case "❤️": await db.store.set("v/1.0/way/to", "my", "heart", to: "💛")
            case "💛": await db.store.set("v/1.0/way/to", "my", "heart", to: "💚")
            case "💚": await db.setVersion(to: "v/2.0/")
            case "🤍": await db.store.set("v/1.0/way/to", "my", "heart", to: "😱")
                break forloop

            default:
                hope.less("Unexpected: \(heart as Any)")
            }
        }

        hope(hearts) == "❤️💛💚🤍"
        
        await hope(that: pond.gushSources["v/1.0/way/to"]?.referenceCount) == nil
        await hope(that: pond.gushSources["v/2.0/way/to"]?.referenceCount) == 1
    }
    
    func test_reference_counting() async throws {

        let db = Database()
        let pond = Any?.Pond(source: db)

        await db.store.set("v/1.0/way/to", to: [
            "red": ["heart": "❤️"],
            "blue": ["heart": "💙"]
        ])

        let redPromise = expectation()
        let bluePromise = expectation()
        
        let red = Task {
            for await heart in pond.stream("way", "to", "red", "heart").filter(String?.self) {
                hope(heart) == "❤️"
                redPromise.fulfill()
            }
        }
        
        let blue = Task {
            for await heart in pond.stream("way", "to", "blue", "heart").filter(String?.self) {
                hope(heart) == "💙"
                bluePromise.fulfill()
            }
        }

        wait(for: redPromise, bluePromise, timeout: 1)
        
        await hope(that: pond.gushSources["v/1.0/way/to"]?.referenceCount) == 2
        
        red.cancel()
        await Task.yield()
        
        await hope(that: pond.gushSources["v/1.0/way/to"]?.referenceCount) == 1
        
        blue.cancel()
        await Task.yield()
        
        await hope(that: pond.gushSources["v/1.0/way/to"]?.referenceCount) == nil
    }
}

extension Pond™ {
    
    actor Database: Geyser {
        
        typealias Gushes = AsyncStream<Any?>
        typealias GushToRouteMapping = AsyncStream<(id: String, route: Route)?>
        
        @Published var version = "v/1.0/"
        
        var gushRouteCount = 2
        
        var store = Any?.Store()
        
        func setVersion(to version: String) {
            self.version = version
        }
        
        func stream(_ gush: String) async -> Gushes {
            await store.stream(.key(gush))
        }
        
        func source<Route>(of route: Route) async -> GushToRouteMapping where Route: Collection, Route.Index == Int, Route.Element == Optional<Any>.Location {
            AsyncStream { continuation in
                guard route.count >= gushRouteCount else {
                    continuation.yield(nil)
                    return
                }
                let ƒ = $version.sink{ version in
                    let route = route.prefix(self.gushRouteCount)
                    let gush = version + route.map(\.description).joined(separator: "/")
                    continuation.yield((gush, Array(route)))
                }
                continuation.onTermination = { @Sendable _ in
                    ƒ.cancel()
                }
            }
        }
    }
}
