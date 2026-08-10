// Determinism Tests.swift

import Declaration_Derivation_Analysis
import Declaration_Derivation_Diagnostics
import Declaration_Derivation_Model
import Declaration_SwiftSyntax_Adapter
import Testing
import Witness_Derivation_Core

extension Witness.Derivation {
    @Suite struct Test {
        /// Positive control: deriving the fixture corpus twice yields
        /// byte-identical member declarations and provenance.
        @Test(
            arguments: [
                FixtureCorpus.zeroMemberStructure,
                FixtureCorpus.singleMemberStructure,
                FixtureCorpus.defaultPreservingStructure,
                FixtureCorpus.enumeration,
                FixtureCorpus.zeroCaseEnumeration,
                FixtureCorpus.actor,
            ]
        )
        func `deriving a fixture twice is byte-identical`(source: String) throws {
            let adapter = Declaration.SwiftSyntaxAdapter()
            let analyzer = Declaration.Derivation.Analyzer()
            let emitter = Witness.Derivation.Emitter(contract: FixtureCorpus.contract)

            func derive() throws(Declaration.Derivation.Diagnostic) -> [String] {
                let intermediateRepresentation = try adapter.intermediateRepresentation(
                    from: FixtureCorpus.declaration(source)
                )
                let analyzed = try analyzer.analyze(intermediateRepresentation)
                return try emitter.memberDeclarations(for: analyzed)
            }

            let first = try derive()
            let second = try derive()
            #expect(first == second)
            #expect(
                first.joined(separator: "\n").utf8.elementsEqual(
                    second.joined(separator: "\n").utf8
                )
            )
        }

        /// Negative control: a malformed declaration fails with the same
        /// stable diagnostic on every run.
        @Test func `malformed declaration yields the stable diagnostic twice`() {
            let adapter = Declaration.SwiftSyntaxAdapter()

            func diagnostic() -> Declaration.Derivation.Diagnostic? {
                do throws(Declaration.Derivation.Diagnostic) {
                    _ = try adapter.intermediateRepresentation(
                        from: FixtureCorpus.declaration(FixtureCorpus.malformedStructure)
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
            #expect(first?.code == .malformedDeclaration)
        }
    }
}
