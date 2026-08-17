// swift-tools-version: 6.3.3

import CompilerPluginSupport
import PackageDescription

let package = Package(
    name: "swift-witness-derivation",
    platforms: [
        .macOS("27"),
        .iOS("27"),
        .tvOS("27"),
        .watchOS("27"),
        .visionOS("27")
    ],
    products: [
        // MARK: - Namespace (per [MOD-017])
        .library(
            name: "Witness Derivation",
            targets: ["Witness Derivation Core", "Witness Derivation"]
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
        // MARK: - Namespace and attached-macro front (per [MOD-017])
        // The @Witness declaration lives here rather than in WitnessDerivation
        // because a target that declares an external macro must depend on the
        // compiler plugin that implements it, and WitnessDerivationMacros
        // already depends on WitnessDerivation — putting the declaration in
        // the core would close a dependency cycle. This target is part of the
        // "Witness Derivation" library product, so a consumer of that product
        // receives both the derivation core and a writable @Witness.
        .target(
            name: "Witness Derivation",
            dependencies: [
                "Witness Derivation Core",
                "WitnessDerivationMacros",
            ]
        ),
        // MARK: - Witness derivation core (model, contract, emitters) and the @Witness macro front
        // TX-D3: witness client and forwarding derivation over the shared
        // declaration-derivation core; syntax-free and Foundation-free.
        .target(
            name: "Witness Derivation Core",
            dependencies: [
                .product(name: "Declaration Derivation Model", package: "swift-declaration-derivation"),
                .product(name: "Declaration Derivation Diagnostics", package: "swift-declaration-derivation"),
            ]
        ),
        // MARK: - Attached-macro expansion host (thin adapter over the shared core; build-time only, excluded from Embedded)
        .macro(
            name: "WitnessDerivationMacros",
            dependencies: [
                "Witness Derivation Core",
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
        // MARK: - Consumer-integration control (product surface only)
        // This target depends on nothing but the targets behind the "Witness
        // Derivation" library product — no macro-implementation target — so it
        // compiles against exactly what an external consumer receives. A test
        // target that also depends on WitnessDerivationMacros cannot detect a
        // missing plugin edge on the product.
        .testTarget(
            name: "Witness Derivation Consumer Tests",
            dependencies: [
                "Witness Derivation Core",
                "Witness Derivation",
            ]
        ),
        .testTarget(
            name: "Witness Derivation Tests",
            dependencies: [
                "Witness Derivation Core",
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
                "Witness Derivation Core",
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
