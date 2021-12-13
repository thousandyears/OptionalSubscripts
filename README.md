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

📦["one", 2] = nil
📦["one"] == nil

📦["one", "two"] = nil
📦[] == nil

```
