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

Including an `Any?.Store` actor with routed streams, publishers, batch updates and atomic transactions:
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

```swift 


```
