// Emitter Tests.swift

import DeclarationDerivationAnalysis
import DeclarationDerivationDiagnostics
import DeclarationDerivationModel
import DeclarationSwiftSyntaxAdapter
import Testing
import WitnessDerivation

extension Witness.Derivation.Emitter {
    @Suite struct Test {

        let emitter = Witness.Derivation.Emitter(contract: FixtureCorpus.contract)

        /// Positive control: the structure fixture derives closure storage,
        /// the memberwise witness initializer, the forwarding initializer
        /// and the provenance member.
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

        /// Label preservation: an explicit member label survives into the
        /// witness initializer's parameter list.
        @Test func `explicit labels are preserved`() throws {
            let members = try emitter.memberDeclarations(
                for: Declaration.IR(node: FixtureCorpus.labeledNode)
            )
            #expect(members[0].contains("of magnitude: @escaping @Sendable () -> Int = { 1 }"))
        }

        /// Actor members derive asynchronous closure storage and awaiting
        /// forwarders.
        @Test func `actor members derive asynchronous closures`() throws {
            let adapter = Declaration.SwiftSyntaxAdapter()
            let intermediateRepresentation = try adapter.intermediateRepresentation(
                from: FixtureCorpus.declaration(FixtureCorpus.actor)
            )
            let members = try emitter.memberDeclarations(for: intermediateRepresentation)
            #expect(members[0].contains("public var count: @Sendable () async -> Int"))
            #expect(members[0].contains("self.count = { await instance.count }"))
        }

        /// Enumeration cases derive case-constructor forwarders.
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

        /// Edge case: zero-member declarations derive an empty client with
        /// both initializers.
        @Test func `zero-member structure derives an empty client`() throws {
            let adapter = Declaration.SwiftSyntaxAdapter()
            let intermediateRepresentation = try adapter.intermediateRepresentation(
                from: FixtureCorpus.declaration(FixtureCorpus.zeroMemberStructure)
            )
            let members = try emitter.memberDeclarations(for: intermediateRepresentation)
            #expect(members[0].contains("public init() {}"))
            #expect(members[0].contains("public init(forwarding instance: Empty) {}"))
        }

        /// Negative control: an ownership-ambiguous node is rejected by the
        /// shared analyzer with the stable diagnostic.
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

        /// Near miss: the contract covers exactly the kinds of IR schema
        /// v1; handwritten declarations outside it are never emitted for.
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
