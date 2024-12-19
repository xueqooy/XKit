// swift-tools-version:5.8
import PackageDescription

let package = Package(
    name: "XKit",
    platforms: [
        .iOS(.v13),
    ],
    products: [
        .library(
            name: "XKit",
            targets: ["XKit"]
        ),
    ],
    targets: [
        .target(
            name: "XKit",
            path: "XKit"
        ),
    ],
    swiftLanguageVersions: [.v5]
)
