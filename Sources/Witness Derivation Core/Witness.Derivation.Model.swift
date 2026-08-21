public import Declaration_Derivation_Model

public enum Witness {}

extension Witness {

    public enum Derivation {}
}

extension Witness {

    public struct GenerationContract: Hashable, Sendable {

        public let revision: Revision

        public let schemaVersion: Declaration.IR.SchemaVersion

        public let packageVersionPin: PackageVersionPin

        public init(
            revision: Revision,
            schemaVersion: Declaration.IR.SchemaVersion,
            packageVersionPin: PackageVersionPin
        ) {
            self.revision = revision
            self.schemaVersion = schemaVersion
            self.packageVersionPin = packageVersionPin
        }
    }
}

extension Witness.GenerationContract {

    public struct Revision: Hashable, Sendable {

        public let text: String

        public init(_ text: String) {
            self.text = text
        }
    }

    public struct PackageVersionPin: Hashable, Sendable {

        public let text: String

        public init(_ text: String) {
            self.text = text
        }
    }

    public func covers(_ node: Declaration.Node) -> Bool {
        Declaration.Node.Kind.allCases.contains(node.kind)
    }

    public var provenance: String {
        "witness-contract-revision=\(revision.text);ir-schema=\(schemaVersion.identifier);package-version-pin=\(packageVersionPin.text)"
    }
}
