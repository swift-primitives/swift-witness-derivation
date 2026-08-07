// Witness.MacroFront.swift

/// The attached-macro front of witness derivation.
///
/// `@Witness` derives, as members of the attached declaration, a nested
/// `Witness` client — closure storage for every normalized member, a
/// label- and default-preserving memberwise initializer, and a forwarding
/// initializer that forwards every closure to a live instance — plus the
/// provenance member the generation contract mandates. Expansion occurs at
/// build time in the consumer through the `WitnessDerivationMacros`
/// compiler plugin; no generated source is placed under version control.
@attached(member, names: named(Witness), named(witnessDerivationProvenance))
public macro Witness() =
    #externalMacro(module: "WitnessDerivationMacros", type: "WitnessMacro")
