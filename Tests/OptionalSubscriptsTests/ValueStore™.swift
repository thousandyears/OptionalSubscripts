//
// github.com/screensailor 2022
//

final class ValueActor™: Hopes {
    
    func test() async throws {
        
        let o = ValueStore("❤️")
        
        let stream = await o.stream().prefix(3)
        
        var all: [String] = []
        
        for await x in stream {
            if all.isEmpty {
                Task.detached {
                    await o.set(to: "💛")
                    await o.set(to: "💚")
                }
            }
            all.append(x)
        }
        
        hope(all) == ["❤️", "💛", "💚"]
    }
}
