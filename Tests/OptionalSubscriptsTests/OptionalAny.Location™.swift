//
//  Created by Milos Rankovic on 12/12/2021.
//

final class Location™: Hopes {
    
    func test() throws {
        
        var o: Optional<Any>.Location
        
        o = 5

        hope(o.index) == 5

        o = "👋"

        hope(o.key) == "👋"
    }
    
    func test_comparable() throws {
        
        var l: Optional<Any>.Location
        var r: Optional<Any>.Location

        (l, r) = (5, "5")
        hope.true(l < r)

        (l, r) = ("5", 5)
        hope.false(l < r)

        (l, r) = (4, 5)
        hope.true(l < r)

        (l, r) = ("4", "5")
        hope.true(l < r)
    }
}
