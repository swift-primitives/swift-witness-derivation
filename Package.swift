// swift-tools-version: 6.3.3

import PackageDescription

let package = Package(
    name: "swift-witness-derivation",
    platforms: [
        .macOS(.v26),
        .iOS(.v26),
        .tvOS(.v26),
        .watchOS(.v26),
        .visionOS(.v26)
    ],
    products: [
        // MARK: - Namespace (per [MOD-017])
        .library(
            name: "Witness Derivation",
            targets: ["Witness Derivation"]
        ),
    ],
    targets: [
        // MARK: - Namespace (per [MOD-017])
        // TX-D0 bootstrap scaffold; the D1 transaction owns the semantic
        // content (the witness derivation with its attached-macro front).
        .target(
            name: "Witness Derivation",
            dependencies: []
        ),
    ]
)
