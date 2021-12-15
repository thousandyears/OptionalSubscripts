//
// github.com/screensailor 2021
//

extension Collection {
    
    var unlessEmpty: Self? {
        isEmpty ? nil : self
    }

    var lineage: UnfoldSequence<SubSequence, (SubSequence?, Bool)> {
        sequence(first: dropLast()){ $0.dropLast().unlessEmpty }
    }
}

public extension BidirectionalCollection {

    func get<Key: Hashable, Value>(_ key: Key) throws -> Value where Element == (Key, Value?)  {
        guard let o = last(where: { $0.0 == key })?.1 else {
            throw [Key: Value].Store.Error.nilAt(key: key)
        }
        return o
    }
}

public extension RangeReplaceableCollection where Self: BidirectionalCollection {

    mutating func set<Key: Hashable, Value>(_ key: Key, to value: Value?) where Element == (Key, Value?) {
        append((key, value))
    }
}
