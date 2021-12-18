//
// github.com/screensailor 2021
//

extension Task where Success == Never, Failure == Never {
    
    @inlinable static func sleep(seconds duration: Double) async throws {
        try await sleep(nanoseconds: UInt64(1_000_000_000 * duration))
    }
}
