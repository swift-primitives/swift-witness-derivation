// Live Expansion Tests.swift

import Testing
import Witness_Derivation
import WitnessDerivation

// MARK: - Consumer-integration control
//
// This suite depends on nothing but the targets behind the "Witness
// Derivation" library product, so expansion here proves the product carries
// its own compiler plugin. An expansion test that also depends on
// WitnessDerivationMacros — or one that supplies the macro mapping itself
// through `macroSpecs:` — cannot detect an unreachable plugin.

@Witness
private struct Point {
    let x: Int
    let y: Int = 0
}

@Witness
private enum Direction: Equatable {
    case north
    case south
}

@Witness
private actor Counter {
    var count: Int = 0
}

// MARK: - Tests over the expanded interfaces

extension Witness {
    @Suite struct Test {

        /// Self-firing control: the @Witness front expands through the real
        /// compiler-plugin path, and the derived client stores closures with
        /// preserved defaults.
        @Test func `structure client stores closures and preserves defaults`() {
            let witness = Point.Witness(x: { 7 })
            #expect(witness.x() == 7)
            #expect(witness.y() == 0)
        }

        /// The forwarding initializer forwards every closure to a live
        /// instance.
        @Test func `structure client forwards to a live instance`() {
            let witness = Point.Witness(forwarding: Point(x: 3))
            #expect(witness.x() == 3)
            #expect(witness.y() == 0)
        }

        /// Enumeration clients forward to case constructors.
        @Test func `enumeration client forwards to case constructors`() {
            let witness = Direction.Witness(forwarding: Direction.self)
            #expect(witness.north() == .north)
            #expect(witness.south() == .south)
        }

        /// Actor clients derive asynchronous closures that await across the
        /// actor's isolation.
        @Test func `actor client awaits across isolation`() async {
            let witness = Counter.Witness(forwarding: Counter())
            #expect(await witness.count() == 0)
        }

        /// Every expansion carries the generation contract's provenance.
        @Test func `expansions carry provenance`() {
            let expected =
                "witness-contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-witness-derivation@main"
            #expect(Point.witnessDerivationProvenance == expected)
            #expect(Direction.witnessDerivationProvenance == expected)
            #expect(Counter.witnessDerivationProvenance == expected)
        }
    }
}
