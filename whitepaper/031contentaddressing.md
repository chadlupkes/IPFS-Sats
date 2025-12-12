# PART II: CORE PROTOCOL (How It Works)
# 3. Technical Architecture
## 3.1 Content Addressing (IPFS)

IPFS-Sats builds on the InterPlanetary File System's core innovation: content addressing, where data is identified by what it is rather than where it is stored. This fundamental shift from location-based URLs (like https://example.com/file.pdf) to content-based identifiers enables cryptographic verification, deduplication, and censorship-resistant distribution. Understanding how Content Identifiers (CIDs) are created is essential to grasping how IPFS-Sats provides trustless proof of authenticity and immutable timestamps.

### 3.1.1 What is a Content Identifier (CID)?

A CID is a unique, self-describing identifier derived from the cryptographic hash of content. It serves as both the address for retrieving data and proof of its integrity. If even a single bit of the content changes, the hash—and therefore the CID—changes completely. This property makes CIDs tamper-evident: you cannot alter content without creating a new identifier.

**Key Properties:**
- Deterministic: The same content always produces the same CID, regardless of who creates it or when
- Content-addressed: The identifier is derived from the data itself, not its storage location
- Cryptographically secure: Uses hash functions (typically SHA-256) that are computationally infeasible to reverse or forge
- Self-describing: CIDs include metadata about the hash function and encoding used, ensuring future compatibility

### 3.1.2 How CIDs Are Created

The process of creating a CID involves several steps that transform raw content into a universally verifiable identifier:

**Step 1: Content Chunking**

Large files are broken into smaller blocks (typically 256KB each) to enable efficient storage, deduplication, and parallel retrieval. Each block is processed independently.

Example: 1MB file → Split into 4 blocks of 256KB each
- Block 1: [bytes 0-262143]
- Block 2: [bytes 262144-524287]
- Block 3: [bytes 524288-786431]
- Block 4: [bytes 786432-1048575]

**Step 2: Hashing**

Each block is run through a cryptographic hash function (default: SHA-256) to produce a fixed-length digest. This hash uniquely represents the block's content.

Block 1 content → SHA-256 → 32-byte hash: a7f3c9d2e...

**Step 3: CID Construction**

The hash is combined with metadata to create a self-describing CID:
- Multibase prefix: Indicates the encoding (e.g., base32, base58)
- Version: CIDv0 (legacy) or CIDv1 (current standard)
- Codec: Data format (e.g., dag-pb for files, dag-cbor for structured data)
- Multihash: Hash function identifier + hash digest

Example CIDv1:

bafybeigdyrzt5sfp7udm7hu76uh7y26nf3efuylqabf3oclgtqy55fbzdi

Breaking it down:
- "bafy": base32 encoding prefix
- "beig...": version, codec, and hash data

**Step 4: DAG Construction**

For multi-block content, IPFS builds a Merkle DAG (Directed Acyclic Graph) where:
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
- Efficient updates: Changing one block only affects its path to the root, not the entire file
- Deduplication: Identical blocks anywhere in the network share the same CID
- Partial retrieval: Download only needed blocks, not the entire file

### 3.1.3 IPFS-Sats Metadata Wrapper

In IPFS-Sats, the raw content CID is wrapped in a metadata object that adds critical context while preserving the original content's immutability. This metadata object is itself a DAG node with its own CID.

Metadata Structure (encoded as dag-cbor):
```
{
  "content_cid": "QmOriginalContent...",  // Link to actual content

  "timestamp_proof": {
    "creation_time": 1735094400,            // Unix timestamp of creation
    "anchor_details": {
      "bitcoin_block": 875432,              // Bitcoin block height of the ON-CHAIN anchor
      "tx_id": "a1b2c3d4e5f6...",           // Transaction ID containing the final hash (channel settlement)
      "op_return_data": "0xHASH...",        // The full Bundle Hash embedded in the OP_RETURN (80-byte limit)
      "bundle_hash": "0xABCDEF..."          // SHA-256 hash of the current Content CID + entire Metadata Bundle
    },
    "provenance_chain": {
      "parent_bundle_hash": "0x012345...", // Mandatory hash of the PREVIOUS content's Bundle Hash (creates the chain)
      "is_fork": false                      // Flag indicating this asset is a derivative
    }
  },

  "ipfs_sats_metadata": {
    "version": "2.0",
    "wallet_address": "lnbc...",            // Lightning wallet for payments
    "dao_cid": "QmDAOconfig...",            // Governance structure (Link to the Content DAO config)
    "smart_contract_hash": "sha256:abc..."
  },
  "creator": {
    "did": "did:key:z6Mk...",               // Decentralized identifier
    "signature": "ed25519:..."              // Cryptographic signature over the entire Bundle Hash
  },
  
  "license": "QmLicenseTerms..."            // Licensing terms (Link to the actual license document/CID)
}
```

**Why Separate Metadata?**

This separation preserves IPFS's core principle: content immutability. The original content CID never changes, ensuring:
- Files can be deduplicated across the network (same content = same CID)
- Verification works universally (hash of content always matches)
- Content can be referenced by any system, not just IPFS-Sats

Meanwhile, the metadata CID becomes the "product passport" that users interact with:
- QR codes point to the metadata CID
- Lightning payments reference the metadata CID
- Search/discovery indexes the metadata CID
- Legal timestamps are proven via the metadata CID

**1. The Core Hashed Element: The Bundle Hash**

The Bundle Hash is the cryptographic fingerprint of the entire asset. It is created by hashing the Content CID (the file) and the Metadata Wrapper (the proof and rules) together.

$$\text{Bundle Hash} = \text{Hash}(\text{Content CID} + \text{Metadata Wrapper})$$

**2. The Provenance Chain (Application Layer)**

The wrapper contains a mandatory field that links the current asset to its predecessor, creating a fast, low-cost chain of evidence between expensive on-chain anchors.

- parent_bundle_hash: A mandatory field in the timestamp_proof object that records the Bundle Hash of the immediate preceding asset (parent, previous version, or last file published by the creator).
  - This establishes a hash-chain for chronological ordering and integrity that operates at the application layer.
  - Any file can be traced backward through this chain, and any attempt to tamper with the contents will result in a mismatched hash, breaking the chain.

**3. The Temporal Anchor (On-Chain Proof)**

Periodically, the latest Bundle Hash in a creator's chain is anchored to the Bitcoin blockchain. This process provides the immutable, unforgeable timestamp for the entire sequence of assets leading up to that point.
- Mechanism: The latest Bundle Hash is embedded into the OP_RETURN output of a Bitcoin transaction, typically one associated with opening or closing a Lightning Network channel (or sweeping the Lightning Yield Wallet).
- Verification: The timestamp_proof records the tx_id and bitcoin_block. This allows any full Bitcoin node to confirm the existence of the Bundle Hash at the time the block was mined. This is the trustless temporal proof for the content.

### 3.1.4 Verification Flow

When a user wants to verify content authenticity:
```
1. Scan QR code → Get metadata CID: QmMetadata...

2. Retrieve metadata object from IPFS
   - Verify hash(metadata) = QmMetadata... ✓

3. Extract content_cid: QmOriginalContent...
   - Retrieve actual content
   - Verify hash(content) = QmOriginalContent... ✓

4. Verify timestamp via Bitcoin block reference
   - Check block 875432 exists ✓
   - Content existed no later than block timestamp ✓

5. Verify creator signature
   - Check signature matches creator DID ✓
```

All verification is cryptographic and trustless—no central authority needed.

### 3.1.5 Anti-Plagiarism Through Content Addressing

Content addressing creates a natural defense against theft:

Scenario: Alice uploads original work
 - Content CID: QmSong... (deterministic hash)
 - Metadata CID: QmAliceMetadata... (includes Bitcoin block 875432)

Later: Bob tries to steal it
- Content CID: QmSong... (same! it's the same content)
- Metadata CID: QmBobMetadata... (includes Bitcoin block 875890)

Anyone can detect the theft:
- Query: "Show all metadata claiming QmSong..."
- Result: Two metadata objects found
- Compare timestamps: Alice's block 875432 < Bob's block 875890

Alice proven as original creator

Bob cannot monetize the stolen content because:
- Value flows through metadata CIDs (which link to wallets)
- Users will pay the earlier/legitimate metadata CID
- Bob's later timestamp proves he didn't create it
- Legal systems recognize Alice's cryptographic priority

### 3.1.6 Technical Resources

IPFS-Sats builds on well-established protocols maintained by Protocol Labs. For deeper technical details on CID generation, DAG structures, and IPLD specifications, see:
- IPFS Documentation: https://docs.ipfs.tech
- CID Specification: https://github.com/multiformats/cid
- IPLD (InterPlanetary Linked Data): https://ipld.io
- Multiformats: https://multiformats.io

IPFS-Sats does not reinvent content addressing—it leverages IPFS's proven cryptographic foundation and adds an economic and governance layer through metadata objects. This approach ensures compatibility with the existing IPFS ecosystem while enabling the Rights to Verify and Fork.
