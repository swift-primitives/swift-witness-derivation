// Fixture Corpus.swift

import DeclarationDerivationModel
import SwiftParser
import SwiftSyntax
import WitnessDerivation

/// The TX-D3 fixture corpus: the declaration forms witness derivation must
/// cover under IR schema v1, plus the malformed and ownership-ambiguous
/// negatives.
enum FixtureCorpus {
}

extension FixtureCorpus {
    /// Zero-member structure.
    static let zeroMemberStructure = "struct Empty {}"

    /// Single-member structure.
    static let singleMemberStructure = """
        struct Single {
            let value: Int
        }
        """

    /// Default-preserving structure with several members.
    static let defaultPreservingStructure = """
        struct Point {
            let x: Int
            let y: Int = 0
            var label: String = "origin"
        }
        """

    /// Enumeration with payload-free cases.
    static let enumeration = """
        enum Direction {
            case north
            case south
        }
        """

    /// Zero-case enumeration.
    static let zeroCaseEnumeration = "enum Nothing {}"

    /// Actor with stored state.
    static let actor = """
        actor Counter {
            var count: Int = 0
        }
        """

    /// Malformed: stored property without an explicit type annotation.
    static let malformedStructure = """
        struct Bad {
            let x = 1
        }
        """

    /// Ownership-ambiguous: two members would own the same derived closure.
    static let ambiguousNode = Declaration.Node(
        kind: .structure,
        name: Declaration.Node.Name("Twice"),
        members: [
            Declaration.Node.Member(
                name: Declaration.Node.Name("value"),
                typeReference: Declaration.Node.Member.TypeReference("Int")
            ),
            Declaration.Node.Member(
                name: Declaration.Node.Name("value"),
                typeReference: Declaration.Node.Member.TypeReference("Int")
            ),
        ]
    )

    /// Label-preserving node: the adapter never produces explicit labels in
    /// IR schema v1, but the model carries them and the emitter must
    /// preserve them.
    static let labeledNode = Declaration.Node(
        kind: .structure,
        name: Declaration.Node.Name("Measure"),
        members: [
            Declaration.Node.Member(
                name: Declaration.Node.Name("magnitude"),
                typeReference: Declaration.Node.Member.TypeReference("Int"),
                label: Declaration.Node.Member.Label("of"),
                defaultValue: Declaration.Node.Member.DefaultValue("1")
            )
        ]
    )

    /// The contract every model-level test emits under.
    static let contract = Witness.GenerationContract(
        revision: Witness.GenerationContract.Revision("1"),
        schemaVersion: .version1,
        packageVersionPin: Witness.GenerationContract.PackageVersionPin(
            "swift-primitives/swift-witness-derivation@main"
        )
    )

    /// The first declaration parsed from a fixture source.
    static func declaration(_ source: String) -> DeclSyntax {
        let file = Parser.parse(source: source)
        guard let declaration = file.statements.first?.item.as(DeclSyntax.self) else {
            fatalError("fixture does not parse to a declaration")
        }
        return declaration
    }
}
