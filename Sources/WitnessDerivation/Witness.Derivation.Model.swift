// Witness.Derivation.Model.swift

public import DeclarationDerivationModel

/// Namespace for witness derivation.
///
/// `Witness` owns the witness-derivation vocabulary built on the shared
/// declaration-derivation core: the derivation namespace
/// (`Witness.Derivation`), the witness generation contract
/// (`Witness.GenerationContract`) and the deterministic emitters. The
/// attached-macro front is the `@Witness` macro declared alongside this
/// namespace.
public enum Witness {}

extension Witness {
    /// Namespace for the witness-derivation machinery: the client emitter,
    /// the forwarder emitter and the attached-macro expansion path.
    public enum Derivation {}
}

extension Witness {
    /// The contract between the witness generator and its consumers.
    ///
    /// The contract answers two questions deterministically: which
    /// declarations witness generation owns output for (so handwritten
    /// declarations outside the contract are never touched) and which
    /// provenance every generated expansion must carry (witness contract
    /// revision, declaration IR schema version and the exact package
    /// version pin of the generator).
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
    /// The revision of the witness generation contract itself.
    public struct Revision: Hashable, Sendable {
        public let text: String

        public init(_ text: String) {
            self.text = text
        }
    }

    /// The exact package version pin of the generator that produced an
    /// output. Consumers admit expansion-behavior exceptions only when
    /// their resolved pin matches the receipt's pin.
    public struct PackageVersionPin: Hashable, Sendable {
        public let text: String

        public init(_ text: String) {
            self.text = text
        }
    }

    /// Whether the contract covers a node — that is, whether witness
    /// generation owns output for it under declaration IR schema v1.
    public func covers(_ node: Declaration.Node) -> Bool {
        Declaration.Node.Kind.allCases.contains(node.kind)
    }

    /// The provenance record every generated expansion carries: witness
    /// contract revision, IR schema version and package pin.
    public var provenance: String {
        "witness-contract-revision=\(revision.text);ir-schema=\(schemaVersion.identifier);package-version-pin=\(packageVersionPin.text)"
    }
}
