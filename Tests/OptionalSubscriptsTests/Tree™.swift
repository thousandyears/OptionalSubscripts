//
// github.com/screensailor 2021
//

@testable import OptionalSubscripts

final class Tree™: Hopes {
    
    typealias Store = Optional<Any>.Store
    
    func test() throws {
        
        var o = Tree<Store.Location, Int>()
        
        hope(o[]) == nil

        o[] = 0
        hope(o[]) == 0
        
        o[1] = 1
        hope(o[1]) == 1
        
        o[1, 2, 3] = 3
        hope(o[1, 2, 3]) == 3
        
        o[1, "2", 3] = 3
        hope(o[1, "2", 3]) == 3
        
        o[1] = Int?.none
        hope(o[1, 2, 3]) == 3
        hope(o[1, "2", 3]) == 3

        o[1] = Tree?.none
        hope(o[1, 2, 3]) == nil
        hope(o[1, "2", 3]) == nil

        o[1, 2] = Tree(
            value: nil,
            branches: [
                1: Tree(value: 1),
                2: Tree(value: 2),
                "a": Tree(value: 3),
                "b": Tree(value: 4),
            ]
        )
        hope(o[1, 2, 1]) == 1
        hope(o[1, 2, 2]) == 2
        hope(o[1, 2, "a"]) == 3
        hope(o[1, 2, "b"]) == 4

        o[1, 2] = Tree(
            value: nil,
            branches: [
                "a": Tree(value: 3),
                "b": Tree(value: 5)
            ]
        )
        hope(o[1, 2, "a"]) == 3
        hope(o[1, 2, "b"]) == 5
    }
}

extension Tree™ {
    
    static let routes = Optional<Any>.RandomRoutes(
        keys: "abcde".map(String.init),
        indices: Array(1...3),
        keyBias: 0.8,
        length: 5...20,
        seed: 4
    )

    func test_set_performance() throws {
        
        let routes = Self.routes.generate(count: 10_000)

        var o = Tree<Store.Location, String>()
        
        measure {
            for route in routes {
                o[route] = "✅"
            }
        }
        
        hope(o.branches.count) == 8
    }
}

extension Tree™ {
    
    func test_traverse() throws {
        
        var tree = Tree<Int, Int>()
        
        var traversal: [[Int]: Int] = [:]
        
        for x in 1...5 {
            for y in 1...5 {
                for z in 1...5 {
                    tree[x, y, z] = x * y * z
                    traversal[[x, y, z]] = x * y * z
                }
            }
        }
        
        tree.traverse { route, value in
            if traversal[route] == value {
                traversal.removeValue(forKey: route)
            }
        }
        
        hope(traversal.count) == 0
    }
}
