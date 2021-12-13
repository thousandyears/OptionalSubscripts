//
//  Created by Milos Rankovic on 12/12/2021.
//

import OptionalSubscripts

final class OptionalAny™: Hopes {

    func test_subscript() throws {

        var o: Any?

        o = nil
        o = []
        o = [:]

        o[] = "👋"
        try hope(o[]) == "👋"

        o["one"] = 1
        try hope(o["one"]) == 1

        o["one", 2] = 2
        try hope(o["one", 2]) == 2

        o["one", 3] = nil
        try hope(o["one"]) == [nil, nil, 2] // did not append

        o["one", 2] = ["three": 4]
        try hope(o["one", 2, "three"]) == 4
        try hope(o[\.["one"][2]["three"]]) == 4

        o["one", 2] = nil
        hope.true(o["one"] == nil)

        o["one", "two"] = nil
        hope.true(o[] == nil)
    }
}

extension OptionalAny™ {
    
    static let routes = Optional<Any>.RandomRoutes(
        keys: "abcde".map(String.init),
        indices: Array(1...3),
        keyBias: 0.8,
        length: 5...20,
        seed: 4
    )
    
    func test_Any_path_performance() throws {
        
        let routes = Self.routes.generate(count: 10_000)
        
        measure {
            for route in routes {
                _ = Any?.keyPath(route)
            }
        }
    }
    
    func test_set_performance() throws {
        
        let routes = Self.routes.generate(count: 10_000)

        var o = Any?.none
        
        measure {
            for route in routes {
                o[route] = "✅"
            }
        }
    }

    func test_set_performance_with_keyPaths() throws {
        
        let routes = Self.routes.generate(count: 10_000).map(Any?.keyPath)

        var o = Any?.none
        
        measure {
            for route in routes {
                o[route] = "✅"
            }
        }
    }

    func test_get_performance() throws {
        
        let routes = Self.routes.generate(count: 10_000)


        var o = Any?.none
        
        for route in routes {
            o[route] = "✅"
        }
        
        var p = Any?.none
        
        measure {
            for route in routes {
                p = o[route]
            }
        }
        
        try hope(p.as()) == "✅"
    }

    func test_get_performance_with_keyPaths() throws {
        
        let routes = Self.routes.generate(count: 10_000).map(Any?.keyPath)

        var o = Any?.none
        
        for route in routes {
            o[route] = "✅"
        }
        
        var p = Any?.none
        
        measure {
            for route in routes {
                p = o[route]
            }
        }
        
        try hope(p.as()) == "✅"
    }
}
