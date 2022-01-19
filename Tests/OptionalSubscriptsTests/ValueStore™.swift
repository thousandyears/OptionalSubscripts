//
// github.com/screensailor 2022
//

final class ValueActor™: Hopes {
    
    func test() async throws {
        
        let o = ValueStore("❤️")
        
        let promise = expectation()
        var bag: Set<AnyCancellable> = []
        
        await o.stream(bufferingPolicy: .unbounded).publisher().prefix(3).collect().sink { o in
            hope(o) == ["❤️", "💛", "💚"]
            promise.fulfill()
        }.store(in: &bag)
        
        await o.set(to: "💛")
        await o.set(to: "💚")

        await waitForExpectations(timeout: 1)
    }
}
