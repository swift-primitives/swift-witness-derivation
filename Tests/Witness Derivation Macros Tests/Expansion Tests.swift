// Expansion Tests.swift

import Declaration_Derivation_Diagnostics
import Declaration_Derivation_Model
import SwiftSyntax
import SwiftSyntaxMacroExpansion
import SwiftSyntaxMacros
import SwiftSyntaxMacrosGenericTestSupport
import Testing
import WitnessDerivation

@testable import WitnessDerivationMacros

// MARK: - Macro registry

private let witnessMacros: [String: MacroSpec] = [
    "Witness": MacroSpec(type: WitnessMacro.self)
]

// MARK: - Swift Testing adapter

/// Bridges the generic macro-test support's framework-agnostic failure
/// handler to Swift Testing issue recording.
private func expectMacroExpansion(
    _ originalSource: String,
    expandedSource: String,
    diagnostics: [DiagnosticSpec] = [],
    fileID: StaticString = #fileID,
    filePath: StaticString = #filePath,
    line: UInt = #line,
    column: UInt = #column
) {
    assertMacroExpansion(
        originalSource,
        expandedSource: expandedSource,
        diagnostics: diagnostics,
        macroSpecs: witnessMacros,
        failureHandler: { failure in
            Issue.record(
                Comment(rawValue: failure.message),
                sourceLocation: SourceLocation(
                    fileID: failure.location.fileID.description,
                    filePath: failure.location.filePath.description,
                    line: Int(failure.location.line),
                    column: Int(failure.location.column)
                )
            )
        },
        fileID: fileID,
        filePath: filePath,
        line: line,
        column: column
    )
}

// MARK: - Expansion fixtures (the expected sources are the API snapshot of the expanded client/forwarder interface)

private let structureFixture = """
    @Witness
    struct Point {
        let x: Int
        let y: Int = 0
    }
    """

private let structureFixtureExpansion = """
    struct Point {
        let x: Int
        let y: Int = 0

        public struct Witness: Sendable {
            public var x: @Sendable () -> Int
            public var y: @Sendable () -> Int

            public init(
                x: @escaping @Sendable () -> Int,
                y: @escaping @Sendable () -> Int = {
                    0
                }
            ) {
                self.x = x
                self.y = y
            }

            public init(forwarding instance: Point) {
                self.x = { [x = instance.x] in
                    x
                }
                self.y = { [y = instance.y] in
                    y
                }
            }
        }

        public static var witnessDerivationProvenance: String {
            "witness-contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-witness-derivation@main"
        }
    }
    """

private let zeroMemberFixture = """
    @Witness
    struct Empty {
    }
    """

private let zeroMemberFixtureExpansion = """
    struct Empty {

        public struct Witness: Sendable {
            public init() {
            }

            public init(forwarding instance: Empty) {
            }
        }

        public static var witnessDerivationProvenance: String {
            "witness-contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-witness-derivation@main"
        }
    }
    """

private let enumerationFixture = """
    @Witness
    enum Direction {
        case north
        case south
    }
    """

private let enumerationFixtureExpansion = """
    enum Direction {
        case north
        case south

        public struct Witness: Sendable {
            public var north: @Sendable () -> Direction
            public var south: @Sendable () -> Direction

            public init(
                north: @escaping @Sendable () -> Direction,
                south: @escaping @Sendable () -> Direction
            ) {
                self.north = north
                self.south = south
            }

            public init(forwarding _: Direction.Type) {
                self.north = {
                    .north
                }
                self.south = {
                    .south
                }
            }
        }

        public static var witnessDerivationProvenance: String {
            "witness-contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-witness-derivation@main"
        }
    }
    """

private let nearMissFixture = """
    @Witness
    struct Kept {
        let value: Int

        func handwritten() -> Int {
            value
        }
    }
    """

private let malformedFixture = """
    @Witness
    struct Bad {
        let x = 1
    }
    """

extension WitnessMacro {
    @Suite struct Test {
        /// Self-firing control: the fixture corpus expands twice with
        /// identical expansions; the expected sources are the API snapshot
        /// of the expanded client/forwarder interface.
        @Test func `fixture corpus expands identically twice`() {
            for _ in 1...2 {
                expectMacroExpansion(structureFixture, expandedSource: structureFixtureExpansion)
                expectMacroExpansion(zeroMemberFixture, expandedSource: zeroMemberFixtureExpansion)
                expectMacroExpansion(enumerationFixture, expandedSource: enumerationFixtureExpansion)
            }
        }

        /// Near miss: handwritten declarations outside the generation
        /// contract are left untouched by the expansion.
        @Test func `handwritten declarations are left untouched`() {
            expectMacroExpansion(
                nearMissFixture,
                expandedSource: """
                    struct Kept {
                        let value: Int

                        func handwritten() -> Int {
                            value
                        }

                        public struct Witness: Sendable {
                            public var value: @Sendable () -> Int

                            public init(
                                value: @escaping @Sendable () -> Int
                            ) {
                                self.value = value
                            }

                            public init(forwarding instance: Kept) {
                                self.value = { [value = instance.value] in
                                    value
                                }
                            }
                        }

                        public static var witnessDerivationProvenance: String {
                            "witness-contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-witness-derivation@main"
                        }
                    }
                    """
            )
        }

        /// Negative control: the malformed fixture expands to nothing and
        /// emits the stable diagnostic.
        @Test func `malformed fixture yields the stable diagnostic`() {
            expectMacroExpansion(
                malformedFixture,
                expandedSource: """
                    struct Bad {
                        let x = 1
                    }
                    """,
                diagnostics: [
                    DiagnosticSpec(
                        message: "declaration.derivation.malformed-declaration [Bad]: stored property 'x' requires an explicit type annotation",
                        line: 1,
                        column: 1
                    )
                ]
            )
        }
    }
}
