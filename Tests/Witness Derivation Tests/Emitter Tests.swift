import Declaration_Derivation_Analysis
import Declaration_Derivation_Diagnostics
import Declaration_Derivation_Model
import Declaration_SwiftSyntax_Adapter
import Testing
import Witness_Derivation_Core

extension Witness.Derivation.Emitter {
    @Suite struct Test {

        let emitter = Witness.Derivation.Emitter(contract: FixtureCorpus.contract)

        @Test func `structure derives client, forwarders and provenance`() throws {
            let adapter = Declaration.SwiftSyntaxAdapter()
            let intermediateRepresentation = try adapter.intermediateRepresentation(
                from: FixtureCorpus.declaration(FixtureCorpus.defaultPreservingStructure)
            )
            let members = try emitter.memberDeclarations(for: intermediateRepresentation)
            #expect(members.count == 2)
            let client = members[0]
            #expect(client.contains("public struct Witness: Sendable {"))
            #expect(client.contains("public var x: @Sendable () -> Int"))
            #expect(client.contains("y: @escaping @Sendable () -> Int = { 0 }"))
            #expect(client.contains("label: @escaping @Sendable () -> String = { \"origin\" }"))
            #expect(client.contains("public init(forwarding instance: Point) {"))
            #expect(client.contains("self.x = { [x = instance.x] in x }"))
            #expect(members[1].contains("witnessDerivationProvenance"))
            #expect(members[1].contains(FixtureCorpus.contract.provenance))
        }

        @Test func `explicit labels are preserved`() throws {
            let members = try emitter.memberDeclarations(
                for: Declaration.IR(node: FixtureCorpus.labeledNode)
            )
            #expect(members[0].contains("of magnitude: @escaping @Sendable () -> Int = { 1 }"))
        }

        @Test func `actor members derive asynchronous closures`() throws {
            let adapter = Declaration.SwiftSyntaxAdapter()
            let intermediateRepresentation = try adapter.intermediateRepresentation(
                from: FixtureCorpus.declaration(FixtureCorpus.actor)
            )
            let members = try emitter.memberDeclarations(for: intermediateRepresentation)
            #expect(members[0].contains("public var count: @Sendable () async -> Int"))
            #expect(members[0].contains("self.count = { await instance.count }"))
        }

        @Test func `enumeration cases derive case forwarders`() throws {
            let adapter = Declaration.SwiftSyntaxAdapter()
            let intermediateRepresentation = try adapter.intermediateRepresentation(
                from: FixtureCorpus.declaration(FixtureCorpus.enumeration)
            )
            let members = try emitter.memberDeclarations(for: intermediateRepresentation)
            #expect(members[0].contains("public var north: @Sendable () -> Direction"))
            #expect(members[0].contains("public init(forwarding _: Direction.Type) {"))
            #expect(members[0].contains("self.north = { .north }"))
        }

        @Test func `zero-member structure derives an empty client`() throws {
            let adapter = Declaration.SwiftSyntaxAdapter()
            let intermediateRepresentation = try adapter.intermediateRepresentation(
                from: FixtureCorpus.declaration(FixtureCorpus.zeroMemberStructure)
            )
            let members = try emitter.memberDeclarations(for: intermediateRepresentation)
            #expect(members[0].contains("public init() {}"))
            #expect(members[0].contains("public init(forwarding instance: Empty) {}"))
        }

        @Test func `ambiguous ownership yields the stable diagnostic`() {
            let analyzer = Declaration.Derivation.Analyzer()

            func diagnostic() -> Declaration.Derivation.Diagnostic? {
                do throws(Declaration.Derivation.Diagnostic) {
                    _ = try analyzer.analyze(
                        Declaration.IR(node: FixtureCorpus.ambiguousNode)
                    )
                    return nil
                } catch {
                    return error
                }
            }

            let first = diagnostic()
            let second = diagnostic()
            #expect(first != nil)
            #expect(first == second)
            #expect(first?.code == .ambiguousOwnership)
        }

        @Test func `contract covers exactly the schema kinds`() {
            for kind in Declaration.Node.Kind.allCases {
                let node = Declaration.Node(
                    kind: kind,
                    name: Declaration.Node.Name("Anything"),
                    members: []
                )
                #expect(FixtureCorpus.contract.covers(node))
            }
        }
    }
}
