// Witness.Derivation.Emitter.swift

public import Declaration_Derivation_Diagnostics
public import Declaration_Derivation_Model

extension Witness.Derivation {
    /// The deterministic witness-client emitter.
    ///
    /// Emission is a pure function of the analyzed IR and the witness
    /// generation contract: the same input renders byte-identically on
    /// every run. The emitter derives the witness client — a nested
    /// `Witness` structure with closure storage for every normalized
    /// member and a label- and default-preserving memberwise initializer —
    /// composes the forwarding initializer of
    /// `Witness.Derivation.ForwarderEmitter`, and appends the provenance
    /// member the contract mandates. Handwritten declarations outside the
    /// generation contract are never touched.
    public struct Emitter: Sendable {
        /// The generation contract emission renders under.
        public let contract: Witness.GenerationContract

        /// Creates an emitter for the given generation contract.
        public init(contract: Witness.GenerationContract) {
            self.contract = contract
        }
    }
}

extension Witness.Derivation.Emitter {

    /// The derived member declarations for an analyzed IR, in stable
    /// order, each rendered as canonical Swift source.
    public func memberDeclarations(
        for intermediateRepresentation: Declaration.IR
    ) throws(Declaration.Derivation.Diagnostic) -> [String] {
        let node = intermediateRepresentation.node
        guard contract.covers(node) else {
            throw Declaration.Derivation.Diagnostic(
                code: .unsupportedDeclarationKind,
                subject: node.name,
                detail: "the witness generation contract does not cover this declaration"
            )
        }
        return [
            try witnessClientDeclaration(for: node),
            provenanceMember(),
        ]
    }

    /// The closure type stored for a member of a node: synchronous for
    /// structures and enumerations, asynchronous for actors (whose stored
    /// state is isolation-protected).
    public static func closureType(
        producing typeText: String,
        of kind: Declaration.Node.Kind
    ) -> String {
        switch kind {
        case .structure, .enumeration:
            "@Sendable () -> \(typeText)"

        case .actor:
            "@Sendable () async -> \(typeText)"
        }
    }

    // MARK: - Derived members

    private func witnessClientDeclaration(
        for node: Declaration.Node
    ) throws(Declaration.Derivation.Diagnostic) -> String {
        var lines: [String] = ["public struct Witness: Sendable {"]
        let storage = try closureStorage(for: node)
        for line in storage {
            lines.append("    \(line)")
        }
        if !storage.isEmpty {
            lines.append("")
        }
        for line in try memberwiseInitializer(for: node) {
            lines.append("    \(line)")
        }
        lines.append("")
        let forwarderEmitter = Witness.Derivation.ForwarderEmitter()
        for line in try forwarderEmitter.forwardingInitializer(for: node) {
            lines.append("    \(line)")
        }
        lines.append("}")
        return lines.joined(separator: "\n")
    }

    private func closureStorage(
        for node: Declaration.Node
    ) throws(Declaration.Derivation.Diagnostic) -> [String] {
        var lines: [String] = []
        for member in node.members {
            lines.append(
                "public var \(member.name.text): \(try Self.storedClosureType(for: member, of: node))"
            )
        }
        return lines
    }

    private func memberwiseInitializer(
        for node: Declaration.Node
    ) throws(Declaration.Derivation.Diagnostic) -> [String] {
        var parameters: [String] = []
        var assignments: [String] = []
        for member in node.members {
            let closureType = try Self.storedClosureType(for: member, of: node)
            var parameter = ""
            if let label = member.label, label.text != member.name.text {
                parameter += "\(label.text) "
            }
            parameter += "\(member.name.text): @escaping \(closureType)"
            if let defaultValue = member.defaultValue {
                parameter += " = { \(defaultValue.text) }"
            }
            parameters.append(parameter)
            assignments.append("    self.\(member.name.text) = \(member.name.text)")
        }
        if parameters.isEmpty {
            return ["public init() {}"]
        }
        var lines: [String] = ["public init("]
        lines.append(parameters.map { "    \($0)" }.joined(separator: ",\n"))
        lines.append(") {")
        lines.append(contentsOf: assignments)
        lines.append("}")
        return lines.joined(separator: "\n").split(
            separator: "\n",
            omittingEmptySubsequences: false
        ).map(String.init)
    }

    private func provenanceMember() -> String {
        "public static var witnessDerivationProvenance: String { \"\(contract.provenance)\" }"
    }

    /// The stored closure type of a normalized member: for structures and
    /// actors a producer of the member's declared type, for enumerations a
    /// producer of the enclosing enumeration itself.
    static func storedClosureType(
        for member: Declaration.Node.Member,
        of node: Declaration.Node
    ) throws(Declaration.Derivation.Diagnostic) -> String {
        switch node.kind {
        case .structure, .actor:
            guard let typeReference = member.typeReference else {
                throw Declaration.Derivation.Diagnostic(
                    code: .malformedDeclaration,
                    subject: node.name,
                    detail: "stored member '\(member.name.text)' carries no type reference"
                )
            }
            return closureType(producing: typeReference.text, of: node.kind)

        case .enumeration:
            return closureType(producing: node.name.text, of: node.kind)
        }
    }
}
