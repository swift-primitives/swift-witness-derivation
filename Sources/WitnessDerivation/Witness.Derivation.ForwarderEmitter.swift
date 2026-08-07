// Witness.Derivation.ForwarderEmitter.swift

public import DeclarationDerivationDiagnostics
public import DeclarationDerivationModel

extension Witness.Derivation {
    /// The deterministic forwarder emitter.
    ///
    /// The forwarder emitter derives the witness client's forwarding
    /// initializer: for a structure or actor, an initializer that forwards
    /// every closure to the corresponding member of a live instance
    /// (awaiting across the actor's isolation); for an enumeration, an
    /// initializer that forwards every closure to the corresponding case
    /// constructor. Emission is a pure function of the analyzed IR and
    /// renders byte-identically on every run.
    public struct ForwarderEmitter: Sendable {
        public init() {}
    }
}

extension Witness.Derivation.ForwarderEmitter {

    /// The forwarding initializer of the witness client, rendered as
    /// canonical Swift source lines.
    public func forwardingInitializer(
        for node: Declaration.Node
    ) throws(Declaration.Derivation.Diagnostic) -> [String] {
        switch node.kind {
        case .structure, .actor:
            try instanceForwardingInitializer(for: node)
        case .enumeration:
            caseForwardingInitializer(for: node)
        }
    }

    // MARK: - Forwarders

    private func instanceForwardingInitializer(
        for node: Declaration.Node
    ) throws(Declaration.Derivation.Diagnostic) -> [String] {
        if node.members.isEmpty {
            return ["public init(forwarding instance: \(node.name.text)) {}"]
        }
        var lines: [String] = ["public init(forwarding instance: \(node.name.text)) {"]
        for member in node.members {
            guard member.typeReference != nil else {
                throw Declaration.Derivation.Diagnostic(
                    code: .malformedDeclaration,
                    subject: node.name,
                    detail: "stored member '\(member.name.text)' carries no type reference"
                )
            }
            let name = member.name.text
            switch node.kind {
            case .actor:
                // Actors are Sendable, so the closure may capture the
                // instance and await across its isolation.
                lines.append("    self.\(name) = { await instance.\(name) }")
            case .structure, .enumeration:
                // A structure need not be Sendable; capture the forwarded
                // member value instead of the instance so the @Sendable
                // closure captures only the value it produces.
                lines.append("    self.\(name) = { [\(name) = instance.\(name)] in \(name) }")
            }
        }
        lines.append("}")
        return lines
    }

    private func caseForwardingInitializer(for node: Declaration.Node) -> [String] {
        if node.members.isEmpty {
            return ["public init(forwarding _: \(node.name.text).Type) {}"]
        }
        var lines: [String] = ["public init(forwarding _: \(node.name.text).Type) {"]
        for member in node.members {
            lines.append("    self.\(member.name.text) = { .\(member.name.text) }")
        }
        lines.append("}")
        return lines
    }
}
