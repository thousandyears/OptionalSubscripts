//
// github.com/screensailor 2021
//

import Combine

final class DictionaryStore™: Hopes {
    
    func test_stream() async throws {

        let o = [String: String].Store()

        let stream = await o.stream("heart").compactMap{ $0 }.prefix(3)
        
        Task {
            var hearts: [String] = []
            
            for await heart in stream {
                hearts.append(heart)
            }
            
            hope(hearts) == ["❤️", "💛", "💚"]
        }

        
        await o.set("heart", to: "❤️")
        await o.set("heart", to: "💛")
        await o.set("heart", to: "💚")


        await o.set("heart", to: nil)
        await hope(that: o.dictionary.isEmpty) == true
    }
    
    func test_publisher() async throws {
        
        let o = [String: String].Store()

        var bag: Set<AnyCancellable> = []
        let promise = expectation()
        
        await o.publisher("heart").filter().prefix(3).collect().sink { (o: [String]) in
            promise.fulfill()
            hope(o) == ["❤️", "💛", "💚"]
        }.store(in: &bag)
        
        await o.set("heart", to: "❤️")
        await o.set("heart", to: "💛")
        await o.set("fart", to: "😱")
        await o.set("heart", to: "💚")

        wait(for: promise, timeout: 1)
        
        await hope(that: o.dictionary) == ["heart": "💚", "fart": "😱"]
    }

    func test_batch() async throws {

        let o = [String: Int].Store()
        
        let stream = await o.stream("x").prefix(2)
        
        Task {
            var xs: [Int?] = []
            
            for await x in stream {
                xs.append(x)
            }

            hope(xs) == [nil, 3]
        }
        
        var batch = [String: Int].Store.BatchUpdates()

        batch.set("x", to: 1)
        batch.set("y", to: 1)
        batch.set("x", to: 2)
        batch.set("y", to: 2)
        batch.set("x", to: 3)
        batch.set("y", to: 3)

        try hope(batch.get("x")) == 3

        await o.batch(batch)

        await hope(that: o.dictionary) == ["x": 3, "y": 3]
    }

    func test_transaction() async throws {

        let o = [String: Int].Store()
        
        let promise = expectation()
        var bag: Set<AnyCancellable> = []
        
        await o.publisher("x").prefix{ $0 != 3 }.collect().sink { o in
            hope(o) == [nil]
            promise.fulfill()
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
                        throw [String: Int].Store.Error.nilAt(key: "x")
                    }
                } catch {}
                
                await o.transaction { store in
                    
                    await o.set("x", to: 3)
                    await o.set("y", to: 3)
                }
            }
        }
        
        await hope(that: o.dictionary) == ["x": 3, "y": 3]
        
        wait(for: promise, timeout: 1)
    }
    
    func test_transaction_level() async throws {
        
        let o = [String: Int].Store()

        await o.transaction { store in
            
            await hope(that: o.transactionLevel) == 1

            await o.transaction { store in

                await hope(that: o.transactionLevel) == 2

                do {
                    try await o.transaction { store in
                        
                        await hope(that: o.transactionLevel) == 3
                        
                        throw [String: Int].Store.Error.nilAt(key: "x")
                    }
                } catch {}
                
                await o.transaction { store in
                    
                    await hope(that: o.transactionLevel) == 3
                }
            }
        }
    }
}
