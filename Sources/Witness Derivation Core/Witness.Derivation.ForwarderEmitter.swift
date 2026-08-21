public import Declaration_Derivation_Diagnostics
public import Declaration_Derivation_Model

extension Witness.Derivation {

    public struct ForwarderEmitter: Sendable {

        public init() {}
    }
}

extension Witness.Derivation.ForwarderEmitter {

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

                lines.append("    self.\(name) = { await instance.\(name) }")

            case .structure, .enumeration:

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
