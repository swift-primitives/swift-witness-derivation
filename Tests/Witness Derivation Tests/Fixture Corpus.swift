import Declaration_Derivation_Model
import SwiftParser
import SwiftSyntax
import Witness_Derivation_Core

enum FixtureCorpus {
}

extension FixtureCorpus {

    static let zeroMemberStructure = "struct Empty {}"

    static let singleMemberStructure = """
        struct Single {
            let value: Int
        }
        """

    static let defaultPreservingStructure = """
        struct Point {
            let x: Int
            let y: Int = 0
            var label: String = "origin"
        }
        """

    static let enumeration = """
        enum Direction {
            case north
            case south
        }
        """

    static let zeroCaseEnumeration = "enum Nothing {}"

    static let actor = """
        actor Counter {
            var count: Int = 0
        }
        """

    static let malformedStructure = """
        struct Bad {
            let x = 1
        }
        """

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

    static let contract = Witness.GenerationContract(
        revision: Witness.GenerationContract.Revision("1"),
        schemaVersion: .version1,
        packageVersionPin: Witness.GenerationContract.PackageVersionPin(
            "swift-primitives/swift-witness-derivation@main"
        )
    )

    static func declaration(_ source: String) -> DeclSyntax {
        let file = Parser.parse(source: source)
        guard let declaration = file.statements.first?.item.as(DeclSyntax.self) else {
            fatalError("fixture does not parse to a declaration")
        }
        return declaration
    }
}
