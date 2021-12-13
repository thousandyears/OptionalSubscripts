// swift-tools-version:5.5

import PackageDescription

let package = Package(
    name: "OptionalSubscripts",
    platforms: [.macOS(.v11), .iOS(.v14)],
    products: [
        .library(name: "OptionalSubscripts", targets: ["OptionalSubscripts"]),
    ],
    dependencies: [
        .package(url: "https://github.com/screensailor/Hope.git", .branch("trunk")),
    ],
    targets: [
        .target(name: "OptionalSubscripts"),
        .testTarget(name: "OptionalSubscriptsTests", dependencies: ["OptionalSubscripts", "Hope"]),
    ]
)
