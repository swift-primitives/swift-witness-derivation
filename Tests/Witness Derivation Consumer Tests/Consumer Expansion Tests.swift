import Testing
import Witness_Derivation
import Witness_Derivation_Core

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

extension Witness {
    @Suite struct Test {

        @Test func `structure client stores closures and preserves defaults`() {
            let witness = Point.Witness(x: { 7 })
            #expect(witness.x() == 7)
            #expect(witness.y() == 0)
        }

        @Test func `structure client forwards to a live instance`() {
            let witness = Point.Witness(forwarding: Point(x: 3))
            #expect(witness.x() == 3)
            #expect(witness.y() == 0)
        }

        @Test func `enumeration client forwards to case constructors`() {
            let witness = Direction.Witness(forwarding: Direction.self)
            #expect(witness.north() == .north)
            #expect(witness.south() == .south)
        }

        @Test func `actor client awaits across isolation`() async {
            let witness = Counter.Witness(forwarding: Counter())
            #expect(await witness.count() == 0)
        }

        @Test func `expansions carry provenance`() {
            let expected =
                "witness-contract-revision=1;ir-schema=v1;package-version-pin=swift-primitives/swift-witness-derivation@main"
            #expect(Point.witnessDerivationProvenance == expected)
            #expect(Direction.witnessDerivationProvenance == expected)
            #expect(Counter.witnessDerivationProvenance == expected)
        }
    }
}
