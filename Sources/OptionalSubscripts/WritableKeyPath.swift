//
// github.com/screensailor 2021
//

public extension WritableKeyPath where Root == Any?, Value == Any? {
    
    func appending<Route>(route o: Route) -> WritableKeyPath where Route: Collection, Route.Index == Int, Route.Element == Optional<Any>.Location {
        /*
         The performance of repeatedly calling `appending(path:)` is currently (Dec 2021) rather poor.
         This implementation is an optimisation workaround over something like:
         
         var o = \Any?.self
         
         for location in route {
             switch location {
             case let .key(key): o = o.appending(path: \.[key])
             case let .index(index): o = o.appending(path: \.[index])
             }
         }
         
         Note that Working with index offsets so that Array.init can be avoided did not yield better performance.
        */
        switch o.count {
        case 0: return self
        case 1: return appending(path: \.[o[0]])
        case 2: return appending(path: \.[o[0]][o[1]])
        case 3: return appending(path: \.[o[0]][o[1]][o[2]])
        case 4: return appending(path: \.[o[0]][o[1]][o[2]][o[3]])
        case 5: return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]])
        case 6: return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]][o[5]])
        case 7: return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]][o[5]][o[6]])
        case 8: return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]][o[5]][o[6]][o[7]])
        case 9: return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]][o[5]][o[6]][o[7]][o[8]])
        default:
            return appending(path: \.[o[0]][o[1]][o[2]][o[3]][o[4]][o[5]][o[6]][o[7]][o[8]])
                .appending(route: Array(o.dropFirst(9)))
        }
    }
}
