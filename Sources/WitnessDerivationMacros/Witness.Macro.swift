// Witness.Macro.swift

import Declaration_Derivation_Analysis
import Declaration_Derivation_Diagnostics
public import Declaration_Derivation_Model
import Declaration_SwiftSyntax_Adapter
public import SwiftSyntax
public import SwiftSyntaxMacros
import WitnessDerivation

/// The `@Witness` attached-macro expansion host.
///
/// The host is a thin adapter over the shared derivation core and the
/// witness emitters: it normalizes the attached declaration through
/// `Declaration.SwiftSyntaxAdapter`, validates the IR through
/// `Declaration.Derivation.Analyzer` and renders the witness client, its
/// forwarding initializer and the provenance member through
/// `Witness.Derivation.Emitter`. It receives the attached declaration only
/// and performs no input or output of any other kind.
///
/// The type is top-level because the compiler plugin resolves macro
/// implementations by the exact `module.type` reflection name; a type
/// nested in a namespace of another module cannot satisfy the
/// `WitnessDerivationMacros.WitnessMacro` coordinate `#externalMacro`
/// declares.
public struct WitnessMacro: MemberMacro {
}

extension WitnessMacro {
    /// The generation contract this expansion host emits under.
    public static let contract = Witness.GenerationContract(
        revision: Witness.GenerationContract.Revision("1"),
        schemaVersion: .version1,
        packageVersionPin: Witness.GenerationContract.PackageVersionPin(
            "swift-primitives/swift-witness-derivation@main"
        )
    )

    /// Expands the attached declaration into its derived members.
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
