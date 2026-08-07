// swift-tools-version: 6.3.3

import CompilerPluginSupport
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
            targets: ["WitnessDerivation"]
        ),
        .library(
            name: "Witness Derivation Macros",
            targets: ["WitnessDerivationMacros"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/swift-primitives/swift-declaration-derivation.git", branch: "main"),
        .package(url: "https://github.com/swiftlang/swift-syntax.git", "602.0.0"..<"603.0.0"),
    ],
    targets: [
        // MARK: - Witness derivation core (model, contract, emitters) and the @Witness macro front
        // TX-D3: witness client and forwarding derivation over the shared
        // declaration-derivation core; syntax-free and Foundation-free.
        .target(
            name: "WitnessDerivation",
            dependencies: [
                .product(name: "Declaration Derivation Model", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Diagnostics", package: "swift-declaration-derivation"),
            ]
        ),
        // MARK: - Attached-macro expansion host (thin adapter over the shared core; build-time only, excluded from Embedded)
        .macro(
            name: "WitnessDerivationMacros",
            dependencies: [
                "WitnessDerivation",
                .product(name: "Declaration Derivation Model", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Diagnostics", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Analysis", package: "swift-declaration-derivation"),
                .product(name: "Declaration SwiftSyntax Adapter", package: "swift-declaration-derivation"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax"),
                .product(name: "SwiftDiagnostics", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "Witness Derivation Tests",
            dependencies: [
                "WitnessDerivation",
                "WitnessDerivationMacros",
                .product(name: "Declaration Derivation Model", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Diagnostics", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Analysis", package: "swift-declaration-derivation"),
                .product(name: "Declaration SwiftSyntax Adapter", package: "swift-declaration-derivation"),
                .product(name: "SwiftParser", package: "swift-syntax"),
            ]
        ),
        .testTarget(
            name: "Witness Derivation Macros Tests",
            dependencies: [
                "WitnessDerivation",
                "WitnessDerivationMacros",
                .product(name: "Declaration Derivation Model", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Diagnostics", package: "swift-declaration-derivation"),
                .product(name: "SwiftSyntax", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacroExpansion", package: "swift-syntax"),
                .product(name: "SwiftSyntaxMacrosGenericTestSupport", package: "swift-syntax"),
            ]
        ),
    ],
    swiftLanguageModes: [.v6]
)

for target in package.targets where ![.system, .binary, .plugin, .macro].contains(target.type) {
    let ecosystem: [SwiftSetting] = [
        .strictMemorySafety(),
        .enableUpcomingFeature("ExistentialAny"),
        .enableUpcomingFeature("InternalImportsByDefault"),
        .enableUpcomingFeature("MemberImportVisibility"),
        .enableUpcomingFeature("NonisolatedNonsendingByDefault"),
        .enableExperimentalFeature("LifetimeDependence"),
        .enableExperimentalFeature("Lifetimes"),
        .enableExperimentalFeature("SuppressedAssociatedTypes"),
        .enableUpcomingFeature("InferIsolatedConformances"),
        .enableUpcomingFeature("LifetimeDependence"),
    ]

    let package: [SwiftSetting] = []

    target.swiftSettings = (target.swiftSettings ?? []) + ecosystem + package
}
