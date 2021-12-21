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
        
        loop:
        for await heart in pond.stream("way", "to", "my", "heart").filter(String?.self) {
            
            hearts += heart ?? ""
            
            switch heart {
            case nil   where hearts.isEmpty:
                       await db.store.set("v/1.0/way/to", "my", "heart", to: "❤️")
            case "❤️": await db.store.set("v/1.0/way/to", "my", "heart", to: "💛")
            case "💛": await db.store.set("v/1.0/way/to", "my", "heart", to: "💚")
            case "💚": await db.setVersion(to: "v/2.0/")
            case "🤍": break loop
            default:   hope.less("Unexpected: \(heart as Any)")
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
        
        let promise = (
            red: expectation(),
            blue: expectation()
        )
        
        let red = Task {
            for await heart in pond.stream("way", "to", "red", "heart").filter(String?.self) {
                hope(heart) == "❤️"
                promise.red.fulfill()
            }
        }
        
        let blue = Task {
            for await heart in pond.stream("way", "to", "blue", "heart").filter(String?.self) {
                hope(heart) == "💙"
                promise.blue.fulfill()
            }
        }

        wait(for: promise.red, promise.blue, timeout: 1)
        
        await hope(that: pond.gushSources["v/1.0/way/to"]?.referenceCount) == 2
        
        red.cancel()
        await Task.yield()
        
        await hope(that: pond.gushSources["v/1.0/way/to"]?.referenceCount) == 1
        
        blue.cancel()
        await Task.yield()
        
        await hope(that: pond.gushSources["v/1.0/way/to"]?.referenceCount) == nil
    }
    
    func test_live_mapping_update() async throws {
        
        let db = Database()
        let pond = Any?.Pond(source: db)
        
        let routes = Any?.RandomRoutes(
            keys: ["a", "b", "c"],
            indices: [],
            keyBias: 1,
            length: 4...9,
            seed: 7
        ).generate(count: 1_000)

        let versions = (1...3).map({ (number: $0, promise: expectation()) })
        
        actor Result {
            
            var values: [Optional<Any>.Route: String] = [:]
            
            func set(_ route: Optional<Any>.Route, to value: String?) {
                values[route] = value
            }
        }
        
        let result = Result()
        
        for route in routes {
            Task.detached {
                for await value in pond.stream(route) {
                    await result.set(route, to: value as? String)
                }
            }
        }

        for (version, promise) in versions {
            Task.detached {
                for route in routes {
                    let route = [.key("v/\(version).0/\(route.prefix(2).joined(separator: "/"))")] + route.dropFirst(2)
                    await db.store.set(route, to: "✅ v\(version)")
                }
                try await Task.sleep(seconds: 0.1) // TODO: remove
                promise.fulfill()
            }
        }
        
        wait(for: versions.map(\.promise), timeout: 1)

        for route in routes {
            let v1 = [.key("v/1.0/\(route.prefix(2).joined(separator: "/"))")] + route.dropFirst(2)
            let v3 = [.key("v/3.0/\(route.prefix(2).joined(separator: "/"))")] + route.dropFirst(2)
            let l = await db.store.data[v1] as? String == "✅ v1"
            let r = await db.store.data[v3] as? String == "✅ v3"
            hope(l) == r
        }
        
        let v1 = await result.values
        hope.true(v1.map(\.value).allSatisfy{ $0 == "✅ v1" })
        
        await db.setVersion(to: "v/3.0/")
        
        try await Task.sleep(seconds: 0.1) // TODO: remove
        
        let v3 = await result.values
        hope.true(v3.map(\.value).allSatisfy{ $0 == "✅ v3" })
        
        hope(v1.keys) == v3.keys
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
