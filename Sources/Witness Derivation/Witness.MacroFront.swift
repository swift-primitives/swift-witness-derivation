@attached(member, names: named(Witness), named(witnessDerivationProvenance))
public macro Witness() =
    #externalMacro(module: "WitnessDerivationMacros", type: "WitnessMacro")
