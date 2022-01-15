//
// github.com/screensailor 2021
//

@testable import OptionalSubscripts

final class OptionalStore™: Hopes {
    
    typealias Route = Optional<Any>.Route
    
    func test_stream() async throws {
        
        let o = Any?.Store()
        let route = ["way", "to", "my", "heart"] as Route
        
        await o.set(route, to: "?")
        
    forloop:
        for await heart in await o.stream(route) {
            switch heart as? String {
                case "?":  await o.set(route, to: "❤️")
                case "❤️": await o.set(route, to: "💛")
                case "💛": await o.set(route, to: "💚")
                case "💚": break forloop
                default:
                    hope.less("Unexpected: '\(heart as Any)'")
                    break forloop
            }
        }
    }
    
    func test_publisher() async throws {
        
        let o = Any?.Store()
        let route = ["way", "to", "my", "heart"] as Route
        
        await o.set(route, to: "?")
        
        var bag: Set<AnyCancellable> = []
        let promise = expectation()
        
        await o.publisher(for: route).filter(String.self).sink { heart in
            Task {
                switch heart {
                    case "?":  await o.set(route, to: "❤️")
                    case "❤️": await o.set(route, to: "💛")
                    case "💛": await o.set(route, to: "💚")
                    case "💚": promise.fulfill()
                    default:
                        hope.less("Unexpected: '\(heart as Any)'")
                        promise.fulfill()
                }
            }
        }.store(in: &bag)
        
        await waitForExpectations(timeout: 1)
    }
    
    func test_update_upstream() async throws {
        
        let o = Any?.Store()
        
        await o.set("a", 2, "c", to: "?")
        
    forloop:
        for await heart in await o.stream("a", 2, "c") {
            switch heart as? String {
                case "?":  await o.set("a", 2, to: ["c": "❤️"])
                case "❤️": await o.set("a", 2, to: ["c": "💛"])
                case "💛": await o.set("a", 2, to: ["c": "💚"])
                case "💚": break forloop
                default:
                    hope.less("Unexpected: '\(heart as Any)'")
                    break forloop
            }
        }
    }
    
    func test_update_downstream() async throws {
        
        let o = Any?.Store()
        
        await o.set("a", 2, "c", to: "?")
        
    forloop:
        for await heart in await o.stream("a", 2) {
            switch heart as? [String: String] {
                case ["c": "?"]:  await o.set("a", 2, "c", to: "❤️")
                case ["c": "❤️"]: await o.set("a", 2, "c", to: "💛")
                case ["c": "💛"]: await o.set("a", 2, "c", to: "💚")
                case ["c": "💚"]: break forloop
                default:
                    hope.less("Unexpected: '\(heart as Any)'")
                    break forloop
            }
        }
    }
}

extension OptionalStore™ {
    
    func test_10_000_subscriptions() async throws {
        
        let routes = Any?.RandomRoutes(
            keys: "abcde".map(String.init),
            indices: Array(1...3),
            keyBias: 0.8,
            length: 5...20,
            seed: 4
        ).generate(count: 10_000)
        
        let o = Any?.Store()
        let o2 = Any?.Store()
        
        let promise = expectation()
        
        for route in routes {
            Task {
                for await o in await o.stream(route, bufferingPolicy: .unbounded).filter(String.self) {
                    await o2.set(route, to: o)
                    if route == routes.last {
                        promise.fulfill()
                    }
                }
            }
        }
        
        for route in routes {
            await o.set(route, to: "✅")
        }
        
        await waitForExpectations(timeout: 1)
        
        let original = try await o.data.json().string()
        let copy = try await o2.data.json().string()
        
        hope(copy) == original
    }

    func test_thread_safety() async throws {
        
        let ƒ: (String) -> [Optional<Any>.Route] = { alphabet in
            Any?.RandomRoutes(
                keys: alphabet.map(String.init),
                indices: [],
                keyBias: 1,
                length: 2...7,
                seed: 7
            ).generate(count: 1_000)
        }
        
        let high = ƒ("AB")
        let low = ƒ("ab")
        
        let o = Any?.Store()
        var results: [Data] = []
        
        for _ in 1...10 {
            
            let promise = (
                high: expectation(),
                low: expectation()
            )
            
            Task.detached {
                for route in high {
                    await o.set(route, to: "✅")
                }
                promise.high.fulfill()
            }
            
            Task.detached {
                for route in low {
                    await o.set(route, to: "✅")
                }
                promise.low.fulfill()
            }
            
            await waitForExpectations(timeout: 1)
            
            try await results.append(o.data.json())
        }
        
        hope.true(results.dropFirst().allSatisfy{ $0 == results.first! })
    }
    
    func test_batch() async throws {
        
        let routes = Any?.RandomRoutes(
            keys: "abc".map(String.init),
            indices: Array(1...2),
            keyBias: 0.8,
            length: 3...12,
            seed: 4
        ).generate(count: 10_000)
        
        let o = Any?.Store()
        let o2 = Any?.Store()
        
        let count = ValueStore((o: 0, o2: 0))
        let bb = ValueStore(Any?.none)
        
        let bbRoute: Route = ["b", "b"]
        
        Task {
            for await _ in await o.stream(bbRoute, bufferingPolicy: .unbounded) {
                await count.inout{ count in
                    count.o += 1
                }
            }
        }
        
        Task {
            for await o in await o2.stream(bbRoute, bufferingPolicy: .unbounded) {
                await count.inout{ count in
                    count.o2 += 1
                }
                await bb.set(to: o)
            }
        }
        
        let promise = expectation()
        
        Task {
            
            var updates = BatchUpdates()
            
            for route in routes {
                await o.set(route, to: "✅")
                updates.append((route, "✅"))
            }
            
            await o2.batch(updates)
            
            promise.fulfill()
        }
        
        await waitForExpectations(timeout: 1)
        
        let unbatched = try await o.data.json(.sortedKeys)
        let batched = try await o2.data.json(.sortedKeys)
        hope(unbatched) == batched
        
        let bbUnbatched = try await o.data[bbRoute].json(.sortedKeys)
        let bbBatched = try await bb.value.json(.sortedKeys)
        
        hope(bbBatched) == bbUnbatched
        await hope(that: count.value.o2) == 2  // initial nil, followed by the batch update
        await hope(that: count.value.o) == 678 // not batched
    }
    
    func test_batch_with_publisher() async throws {
        
        let routes = Any?.RandomRoutes(
            keys: "abc".map(String.init),
            indices: Array(1...2),
            keyBias: 0.8,
            length: 3...12,
            seed: 4
        ).generate(count: 10_000)
        
        let o = Any?.Store()
        let o2 = Any?.Store()
        
        var bag: Set<AnyCancellable> = []
        var count = (o: 0, o2: 0)
        var bb: Any?
        
        let bbRoute: Route = ["b", "b"]
        
        await o.publisher(for: bbRoute, bufferingPolicy: .unbounded).sink { o in
            count.o += 1
        }.store(in: &bag)
        
        await o2.publisher(for: bbRoute, bufferingPolicy: .unbounded).print("✅ publisher").sink { o in
            count.o2 += 1
            bb = o
        }.store(in: &bag)
        
        let promise = expectation()
        
        Task {
            
            var updates = BatchUpdates()
            
            for route in routes {
                updates.append((route, "✅"))
                await o.set(route, to: "✅")
                await Task.yield()
            }
            
            await o2.batch(updates)
            
            await Task.yield()
            
            promise.fulfill()
        }
        
        await waitForExpectations(timeout: 1)

        let unbatched = try await o.data.json(.sortedKeys)
        let batched = try await o2.data.json(.sortedKeys)
        hope(unbatched) == batched
        
        let bbUnbatched = try await o.data[bbRoute].json(.sortedKeys)
        let bbBatched = try bb.json(.sortedKeys)
        
        hope(bbBatched) == bbUnbatched
        hope(count.o2) == 2  // initial nil, followed by the batch update
        hope(count.o) == 678 // not batched
    }

    func test_transaction() async throws {
        
        let o = Any?.Store()
        
        let promise = expectation()
        var bag: Set<AnyCancellable> = []
        
        await o.publisher(for: "x", bufferingPolicy: .unbounded).filter(Int?.self).prefix(2).collect().sink { o in
            hope(o) == [nil, 3]
            promise.fulfill()
        }.store(in: &bag)
        
        await o.transaction { o in
            
            await o.set("x", to: 1)
            await o.set("y", to: 1)
            
            await o.transaction { o in
                
                await o.set("x", to: 2)
                await o.set("y", to: 2)
                
                do {
                    try await o.transaction { o in
                        
                        await o.set("z", to: 3)
                        throw Any?.Store.Error.nilAt(route: ["x"])
                    }
                } catch {}
                
                await o.transaction { o in
                    
                    await o.set("x", to: 3)
                    await o.set("y", to: 3)
                }
            }
        }
        
        try await hope(that: o[]) == ["x": 3, "y": 3]
        
        await waitForExpectations(timeout: 1)
    }
    
    func test_transaction_level() async throws {
        
        let o = Any?.Store()
        
        await o.transaction { o in
            
            await hope(that: o.transactionLevel) == 1
            
            await o.transaction { o in
                
                await hope(that: o.transactionLevel) == 2
                
                do {
                    try await o.transaction { o in
                        
                        await hope(that: o.transactionLevel) == 3
                        
                        throw Any?.Store.Error.nilAt(route: ["x"])
                    }
                } catch {}
                
                await o.transaction { o in
                    
                    await hope(that: o.transactionLevel) == 3
                }
            }
        }
    }
}
