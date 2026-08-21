import Declaration_Derivation_Analysis
import Declaration_Derivation_Diagnostics
public import Declaration_Derivation_Model
import Declaration_SwiftSyntax_Adapter
public import SwiftSyntax
public import SwiftSyntaxMacros
import Witness_Derivation_Core

public struct WitnessMacro: MemberMacro {
}

extension WitnessMacro {

    public static let contract = Witness.GenerationContract(
        revision: Witness.GenerationContract.Revision("1"),
        schemaVersion: .version1,
        packageVersionPin: Witness.GenerationContract.PackageVersionPin(
            "swift-primitives/swift-witness-derivation@main"
        )
    )

    public static func expansion(
        of node: AttributeSyntax,
        providingMembersOf declaration: some DeclGroupSyntax,
        conformingTo protocols: [TypeSyntax],
        in context: some MacroExpansionContext
    ) throws(Declaration.Derivation.Diagnostic) -> [DeclSyntax] {
        let adapter = Declaration.SwiftSyntaxAdapter()
        let intermediateRepresentation = try adapter.intermediateRepresentation(
            from: declaration
        )
        let analyzed = try Declaration.Derivation.Analyzer().analyze(
            intermediateRepresentation
        )
        let emitter = Witness.Derivation.Emitter(contract: Self.contract)
        return try emitter.memberDeclarations(for: analyzed).map { member in
            DeclSyntax("\(raw: member)")
        }
    }
}
