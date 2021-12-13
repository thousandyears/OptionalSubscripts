# Optional Subscripts

All equality expressions below return `true`:
```swift
import OptionalSubscripts

var o: Any?

o = nil
o = []
o = [:]

o[] = "👋"
try o[] == "👋"

o["one"] = 1
try o["one"] == 1

o["one", 2] = 2
try o["one", 2] == 2

o["one", 10] = nil
try o["one"] as [Int?] == [nil, nil, 2]

o["one", 2] = ["three": 4]
try o["one", 2, "three"] == 4

o["one", 2] = nil
o["one"] == nil

o["one", "two"] = nil
o[] == nil

```
