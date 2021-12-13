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
}
