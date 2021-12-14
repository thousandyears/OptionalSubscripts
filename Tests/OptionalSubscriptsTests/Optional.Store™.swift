//
// github.com/screensailor 2021
//

import Combine

final class Store™: Hopes {
    
    func test_stream() async throws {
        
        let o = Any?.Store()
        let route: Optional<Any>.Route = ["a", "b", "c"]
        
        let stream = await o.stream(route).filter(String.self).prefix(3)

        Task {
            var all: [String] = []
            
            for await o in stream {
                all.append(o)
            }
            
            hope(all) == ["❤️", "💛", "💚"]
        }
        
        await o.set(route, to: "❤️")
        await o.set(route, to: "💛")
        await o.set(route, to: "💚")
    }
    
    func test_publisher() async throws {
        
        let o = Any?.Store()
        
        var bag: Set<AnyCancellable> = []
        let promise = expectation()
        
        await o.publisher("a", "b", "c").filter().prefix(3).collect().sink { (o: [String]) in
            promise.fulfill()
            hope(o) == ["❤️", "💛", "💚"]
        }.store(in: &bag)
        
        await o.set("a", "b", "c", to: "❤️")
        await o.set("a", "b", "c", to: "💛")
        await o.set("a", "b", "x", to: "😱")
        await o.set("a", "b", "c", to: "💚")

        wait(for: promise, timeout: 1)
        
        try await hope(that: o["a", "b"]) == ["c": "💚", "x": "😱"]
    }
    
    func test_update_upstream() async throws {
        
        let o = Any?.Store()
        
        var bag: Set<AnyCancellable> = []
        let promise = expectation()
        
        await o.publisher("a", 2, "c").filter(String.self).prefix(3).collect().sink { o in
            promise.fulfill()
            hope(o) == ["❤️", "💛", "💚"]
        }.store(in: &bag)
        
        await o.set("a", 2, to: ["c": "❤️"])
        await o.set("a", 2, to: ["c": "💛"])
        await o.set("a", 2, to: ["c": "💚"])

        wait(for: promise, timeout: 1)
    }
    
    func test_update_downstream() async throws {
        
        let o = Any?.Store()
        
        var bag: Set<AnyCancellable> = []
        let promise = expectation()
        
        await o.publisher("a", 2).filter([String: String].self).prefix(3).collect().sink { o in
            promise.fulfill()
            hope(o) == [
                ["c": "❤️"],
                ["c": "💛"],
                ["c": "💚"]
            ]
        }.store(in: &bag)
        
        await o.set("a", 2, "c", to: "❤️")
        await o.set("a", 2, "c", to: "💛")
        await o.set("a", 2, "c", to: "💚")

        wait(for: promise, timeout: 1)
    }
}

extension Store™ {
    
    static let routes = Any?.RandomRoutes(
        keys: "abcde".map(String.init),
        indices: Array(1...3),
        keyBias: 0.8,
        length: 5...20,
        seed: 4
    )
    
    func test_1000_subscriptions() async throws {
        
        let routes = Self.routes.generate(count: 1_000)

        let o = Any?.Store()
        let o2 = Any?.Store()
        
        var bag: Set<AnyCancellable> = []
        let promise = expectation()
        var count = 0
        
        for route in routes {
            await o.publisher(route).filter(String.self).handleEvents(receiveCancel: {
                count += 1
                if count == routes.count {
                    promise.fulfill()
                }
            }).sink{ o in
                Task {
                    await o2.set(route, to: o)
                }
            }.store(in: &bag)
        }

        for route in routes {
            await o.set(route, to: "✅")
        }
        
        bag.removeAll()
        
        wait(for: promise, timeout: 1)
        
        let original = try await o.data.json(options: .sortedKeys).string()
        let copy = try await o2.data.json(options: .sortedKeys).string()
        
        hope(copy) == original
    }
    
    func test_batch() async throws {
        
        let g = Any?.RandomRoutes(
            keys: "abc".map(String.init),
            indices: Array(1...2),
            keyBias: 0.8,
            length: 1...4,
            seed: 4
        )

        let routes = g.generate(count: 1_000)

        let o = Any?.Store()
        let o2 = Any?.Store()
        
        let route: Optional<Any>.Route = ["b", "b"]
        
        var bag: Set<AnyCancellable> = []
        var count = (o: 0, o2: 0)
        var result: Any?
        
        await o.publisher(route).sink { o in
            count.o += 1
        }.store(in: &bag)
        
        await o2.publisher(route).sink { o in
            count.o2 += 1
            result = o
        }.store(in: &bag)

        var updates = o.batch

        for route in routes {
            await o.set(route, to: "✅")
            updates.append((route, "✅"))
        }
        
        await o2.batch(updates)
        
        do {
            let original = try await o.data.json(options: .sortedKeys).string()
            let copy = try await o2.data.json(options: .sortedKeys).string()
            
            hope(copy) == original
        }
        
        do {
            let original = try await o.data[route].json(options: .sortedKeys).string()
            let copy = try result.json(options: .sortedKeys).string()

            hope(copy) == original
            hope(count.o2) == 2  // initial nil, followed by the batch update
            hope(count.o) == 113 // not batched
        }
    }
    
    func test_transaction() async throws {
        
        let o = Any?.Store()
        
        let promise = expectation()
        var bag: Set<AnyCancellable> = []
        var x: [Int?] = []
        
        await o.publisher("x").filter(Int?.self).sink { o in
            x.append(o)
            if o == 3 {
                promise.fulfill()
            }
        }.store(in: &bag)

        await o.transaction { store in
            
            await o.set("x", to: 1)
            await o.set("y", to: 1)

            await o.transaction { store in
                
                await o.set("x", to: 2)
                await o.set("y", to: 2)

                do {
                    try await o.transaction { store in
                        
                        await o.set("z", to: 3)
                        throw Any?.Store.Error.nilAt(route: ["x"])
                    }
                } catch {}
                
                await o.transaction { store in
                    
                    await o.set("x", to: 3)
                    await o.set("y", to: 3)
                }
            }
        }
        
        try await hope(that: o[]) == ["x": 3, "y": 3]
        
        wait(for: promise, timeout: 1)
        
        hope(x) == [nil, 3]
    }
    
    func test_transaction_level() async throws {
        
        let o = Any?.Store()
        
        await o.transaction { store in
            
            await hope(that: o.transactionLevel) == 1

            await o.transaction { store in

                await hope(that: o.transactionLevel) == 2

                do {
                    try await o.transaction { store in
                        
                        await hope(that: o.transactionLevel) == 3
                        
                        throw Any?.Store.Error.nilAt(route: ["x"])
                    }
                } catch {}
                
                await o.transaction { store in
                    
                    await hope(that: o.transactionLevel) == 3
                }
            }
        }
    }
}
