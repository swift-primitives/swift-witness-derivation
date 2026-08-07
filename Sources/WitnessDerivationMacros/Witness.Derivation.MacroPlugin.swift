// Witness.Derivation.MacroPlugin.swift

import SwiftCompilerPlugin
import SwiftSyntaxMacros

/// The compiler-plugin entry point of witness derivation.
///
/// `@main` must attach to a top-level type, so the plugin is a top-level
/// name of the macros target; the expansion host it provides is
/// `WitnessMacro`, the implementation of the `@Witness` attached macro.
@main
struct WitnessDerivationMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WitnessMacro.self
    ]
}
