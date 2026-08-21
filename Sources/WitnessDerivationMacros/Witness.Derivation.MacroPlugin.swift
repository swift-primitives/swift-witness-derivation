import SwiftCompilerPlugin
import SwiftSyntaxMacros

@main
struct WitnessDerivationMacroPlugin: CompilerPlugin {
    let providingMacros: [Macro.Type] = [
        WitnessMacro.self
    ]
}
