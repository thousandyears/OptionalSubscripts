//
//  Created by Milos Rankovic on 12/12/2021.
//

@_exported import Hope
@_exported import OptionalSubscripts
import Foundation

final class High: Hopes {
    
    func test() throws {
        
        let o: Shrub = [
            "one": [nil, nil, ["three": 4]]
        ]
        
        try hope(o.one[2].three.as()) == 4
    }
}

@dynamicMemberLookup
struct Shrub {
    
    var o: Any?
    
    init(_ o: Any?) {
        self.o = o
    }
    
    subscript(dynamicMember key: String) -> Shrub {
        Shrub(o[key])
    }
    
    subscript(index: Int) -> Shrub {
        Shrub(o[index])
    }
}

extension Shrub: Castable {
    
    func cast<A>(to: A.Type) throws -> A {
        try o.cast()
    }
}

extension Shrub: ExpressibleByDictionaryLiteral {
    
    init(dictionaryLiteral elements: (String, Any)...) {
        self.init(Dictionary(uniqueKeysWithValues: elements))
    }
}
