# Optional Subscripts

All equality expressions below return `true`:
```swift
import OptionalSubscripts

var 📦: Any?

📦 = nil
📦 = []
📦 = [:]

📦[] = "👋"
try 📦[] == "👋"

📦["one"] = 1
try 📦["one"] == 1

📦["one", 2] = 2
try 📦["one", 2] == 2

📦["one", 10] = nil
try 📦["one"] as [Int?] == [nil, nil, 2]

📦["one", 2] = ["three": 4]
try 📦["one", 2, "three"] == 4
try 📦[\.["one"][2]["three"]] == 4
        
📦["one", 2] = nil
📦["one"] == nil

📦["one", "two"] = nil
📦[] == nil

```

... including an `Any?.Store` actor with routed streams, publishers, batch updates and atomic transactions:
```swift
let o = Any?.Store()

let stream = await o.stream("me", 2, "you").filter(String.self).prefix(3)

Task {
    var hearts: [String] = []
    
    for await o in stream {
        hearts.append(o)
    }
    
    hearts == ["❤️", "💛", "💚"]
}

await o.set("me", 2, "you", to: "❤️")
await o.set("me", 2, to: ["you": "💛"])
await o.set("me", to: [nil, nil, ["you": "💚"]])

```

... and `Any?.Pond` actor that turns a chunky data source (like a document-oriented database) into routed data streams of arbitrary granularity:

```swift 
let db = SomeDatabase() // conforms to Geyser protocol
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
    default:   assertionFailure()
    }
}

hearts == "❤️💛💚🤍"

await pond.gushSources["v/1.0/way/to"]?.referenceCount == nil
await pond.gushSources["v/2.0/way/to"]?.referenceCount == 1

```

... where:
```swift
protocol Geyser {

    associatedtype GushID: Hashable
    
    associatedtype Gushes: AsyncSequence where Gushes.Element == Any?
    
    associatedtype GushToRouteMapping: AsyncSequence where GushToRouteMapping.Element == (id: GushID, route: Optional<Any>.Route)?

    func stream(_ gush: GushID) async -> Gushes
    
    func source<Route>(of route: Route) async -> GushToRouteMapping where Route: Collection, Route.Index == Int, Route.Element == Optional<Any>.Location
}
```
