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
