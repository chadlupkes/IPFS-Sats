# 3.1 Content Addressing

IPFS-Sats is built on a foundational cryptographic primitive: content addressing, where data is identified by what it is rather than where it is stored. This shift from location-based identifiers (like `https://example.com/file.pdf`) to content-based identifiers enables cryptographic verification, deduplication, and censorship-resistant distribution independent of any single storage provider or network topology.

The core unit of this primitive is the **Content Identifier (CID)** — a self-describing, cryptographically derived identifier that serves simultaneously as an address for retrieving data and as proof of its integrity. Understanding how CIDs are created and verified is essential to understanding how IPFS-Sats provides trustless proof of authenticity and immutable timestamps.

IPFS (InterPlanetary File System) is the reference implementation of a complete technology stack built on content addressing. It provides the chunking, hashing, DAG construction, and retrieval mechanisms that turn raw content hashing into a functional storage and distribution system, and it is the natural starting point for IPFS-Sats implementations. Any system that produces CID-compatible identifiers and participates in the SatSwap exchange and discovery layers is a conforming participant in the protocol, regardless of the underlying storage implementation.

---

## 3.1.1 What Is a Content Identifier (CID)?

A CID is a unique, self-describing identifier derived from the cryptographic hash of content. It serves as both the address for retrieving data and proof of its integrity. If even a single bit of the content changes, the hash — and therefore the CID — changes completely. This property makes CIDs tamper-evident: content cannot be altered without producing a different identifier.

**Key Properties:**
- **Deterministic:** The same content always produces the same CID, regardless of who creates it or when
- **Content-addressed:** The identifier is derived from the data itself, not its storage location
- **Cryptographically secure:** Uses hash functions (typically SHA-256) that are computationally infeasible to reverse or forge
- **Self-describing:** CIDs include metadata about the hash function and encoding used, ensuring forward compatibility

---

## 3.1.2 How CIDs Are Created

The process of creating a CID involves several steps that transform raw content into a universally verifiable identifier. The steps described here follow the IPFS reference implementation; conforming alternative implementations must produce equivalent results.

**Step 1: Content Chunking**

Large files are broken into smaller blocks (typically 256KB each) to enable efficient storage, deduplication, and parallel retrieval. Each block is processed independently.

```
Example: 1MB file → Split into 4 blocks of 256KB each
- Block 1: [bytes 0-262143]
- Block 2: [bytes 262144-524287]
- Block 3: [bytes 524288-786431]
- Block 4: [bytes 786432-1048575]
```

**Step 2: Hashing**

Each block is run through a cryptographic hash function (default: SHA-256) to produce a fixed-length digest. This hash uniquely represents the block's content.

```
Block 1 content → SHA-256 → 32-byte hash: a7f3c9d2e...
```

**Step 3: CID Construction**

The hash is combined with metadata to create a self-describing CID:
- **Multibase prefix:** Indicates the encoding (e.g., base32, base58)
- **Version:** CIDv0 (legacy) or CIDv1 (current standard)
- **Codec:** Data format (e.g., dag-pb for files, dag-cbor for structured data)
- **Multihash:** Hash function identifier + hash digest

```
Example CIDv1:
bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi

Breaking it down:
- "bafy": base32 encoding prefix
- "beig...": version, codec, and hash data
```

**Step 4: DAG Construction**

For multi-block content, a Merkle DAG (Directed Acyclic Graph) is constructed where:
- Leaf nodes contain the actual data blocks
- Parent nodes contain links (CIDs) to child nodes
- The root node's CID represents the entire file

```
Root CID: QmRootFile...
    ├─ QmBlock1... (256KB)
    ├─ QmBlock2... (256KB)
    ├─ QmBlock3... (256KB)
    └─ QmBlock4... (256KB)
```

This structure enables:
- **Efficient updates:** Changing one block only affects its path to the root, not the entire file
- **Deduplication:** Identical blocks anywhere in the network share the same CID
- **Partial retrieval:** Download only needed blocks, not the entire file — the foundation of the swarm delivery model (Section 3.6)

---

## 3.1.3 From Content CID to Metadata Bundle

A content CID alone identifies data. It says nothing about who created it, when it existed, what rights apply to it, or how value should flow to its creator. To transform a raw file into a complete digital asset — one that carries proof of existence, creator identity, licensing terms, governance rules, and economic infrastructure — the content CID is combined with a **Metadata Wrapper** to form a **Metadata Bundle**.

The Metadata Bundle is the complete package: the content CID plus the Metadata Wrapper. The Metadata Wrapper is the structured data that describes, timestamps, and governs the content. Together they form the unit that users verify, that applications index, that Lightning payments reference, and that the per-content DAO governs.

The full structure of the Metadata Wrapper — its seven components, the Bundle Hash, the provenance chain, and the Bitcoin timestamping mechanism — is specified in Section 3.2.

---

## 3.1.4 Verification Flow

When a user wants to verify content authenticity:

```
1. Scan QR code → Get Metadata Bundle CID: QmMetadata...

2. Retrieve Metadata Wrapper from the bundle
   - Verify hash(Metadata Wrapper) = QmMetadata... ✓

3. Extract content_cid: QmOriginalContent...
   - Retrieve actual content
   - Verify hash(content) = QmOriginalContent... ✓

4. Verify timestamp via Bitcoin block reference
   - Check block 875432 exists ✓
   - Content existed no later than block timestamp ✓

5. Verify creator signature
   - Check signature matches creator DID ✓
```

All verification is cryptographic and trustless — no central authority required.

---

## 3.1.5 Anti-Plagiarism Through Content Addressing

Content addressing creates a natural defense against theft. Because the CID is derived deterministically from the content, two parties uploading the same content will always produce the same content CID — but their Metadata Bundles, and the Bitcoin block heights embedded in them, will differ.

```
Scenario: Alice uploads original work
- Content CID: QmSong... (deterministic hash)
- Metadata Bundle CID: QmAliceBundle... (includes Bitcoin block 875432)

Later: Bob tries to claim it
- Content CID: QmSong... (same — it's the same content)
- Metadata Bundle CID: QmBobBundle... (includes Bitcoin block 875890)

Anyone can detect the theft:
- Query: "Show all Metadata Bundles claiming QmSong..."
- Result: Two bundles found
- Compare timestamps: Alice's block 875432 < Bob's block 875890
```

Alice is proven as the original creator. Bob cannot monetize the content because:
- Value flows through Metadata Bundle CIDs, which link to wallets
- Users will pay the earlier, legitimate Metadata Bundle CID
- Bob's later timestamp proves he did not create it
- The cryptographic priority is globally verifiable without legal intervention

---

## 3.1.6 Reference Implementations and Technical Resources

The content addressing primitive described in this section is implemented by IPFS using the following specifications. Implementers building on IPFS should consult these resources for technical details on CID generation, DAG structures, and IPLD encoding:

- IPFS Documentation: https://docs.ipfs.tech
- CID Specification: https://github.com/multiformats/cid
- IPLD (InterPlanetary Linked Data): https://ipld.io
- Multiformats: https://multiformats.io

IPFS-Sats does not reinvent content addressing. The protocol depends on the cryptographic properties of CIDs — determinism, tamper-evidence, and self-description — not on any specific implementation of the storage and retrieval layer. Implementations that produce CID-compatible identifiers and conform to the SatSwap exchange specification (Section 10.6) and Host Registry Record schema (Section 10.7) are full participants in the protocol.
