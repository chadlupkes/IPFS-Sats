# 3.2 The Metadata Bundle: Timestamping, Identity, and Governance

While content addressing (Section 3.1) ensures that data is immutably identified by its cryptographic hash, the Metadata Bundle transforms a simple file into a complete digital asset with provenance, economic infrastructure, and governance. The Metadata Wrapper, stored as a separate DAG node, wraps the raw content CID with all the information necessary to establish ownership, enable verification, automate payments, manage licensing, and track derivative works. The Metadata Bundle is the key innovation that elevates content addressing from a storage primitive to a foundational layer for the Rights to Verify and Fork.

**The Metadata Bundle** is the complete package: the content CID combined with its Metadata Wrapper. The **Metadata Wrapper** is the structured data component — the seven-component object that describes, timestamps, and governs the content. The **Bundle Hash** is the cryptographic fingerprint of the complete bundle:

$$\text{Bundle Hash} = \text{Hash}(\text{Content CID} + \text{Metadata Wrapper})$$

**The Complete Metadata Wrapper Structure**

Every piece of content uploaded to IPFS-Sats generates a Metadata Wrapper encoded in dag-cbor (Concise Binary Object Representation), a schema-less format that efficiently stores structured data with native support for CID links. The Metadata Wrapper includes seven core components:

```json
{
  // 1. CONTENT REFERENCE
  "content_cid": "QmOriginalContent...",

  // 2. TIMESTAMP PROOF
  "timestamp_proof": {
    "creation_time": 1735094400,
    "anchor_details": {
      "bitcoin_block": 875432,
      "tx_id": "a1b2c3d4e5f6...",
      "op_return_data": "0xHASH..."
    },
    "provenance_chain": {
      "bundle_hash": "0xABCDEF...",
      "parent_bundle_hash": "0x012345...",
      "is_fork": false
    }
  },

  // 3. IPFS-SATS PROTOCOL DATA
  "ipfs_sats_metadata": {
    "version": "2.0",
    "wallet_address": "lnbc...",
    "dao_cid": "QmDAOconfig...",
    "smart_contract_hash": "sha256:abc123..."
  },

  // 4. CREATOR IDENTITY & SIGNATURE
  "creator": {
    "did": "did:key:z6Mk...",
    "signature": "ed25519:...",
    "public_key": "base58:..."
  },

  // 5. PROVENANCE & FORK TRACKING
  "parent_cid": null,
  "derivative_type": null,
  "royalty_terms": {},

  // 6. LICENSING & TERMS
  "license": {
    "type": "custom",
    "terms_cid": "QmLicenseTerms...",
    "commercial_use": true,
    "attribution_required": true,
    "derivative_royalty": 10
  },

  // 7. DESCRIPTIVE METADATA
  "title": "My Creative Work",
  "description": "A groundbreaking innovation",
  "tags": ["music", "electronic", "2025"],
  "media_type": "audio/mpeg",
  "language": "en"
}
```

Let's examine each component in detail.

---

## 3.2.1 Content Reference 🔗

```json
"content_cid": "QmOriginalContent..."
```

This is the **Content CID** — a direct, immutable link to the raw data file. By separating this immutable content hash from the Metadata Wrapper, IPFS-Sats preserves **content immutability**. The raw file's CID never changes, enabling universal deduplication and cryptographic verification.

### Why Separate?

Separating the immutable Content CID from the Metadata Wrapper allows for dynamic governance without sacrificing content integrity:

- **Content remains immutable.** The CID never changes, ensuring verifiable authenticity even if ownership or licenses are updated.
- **Metadata is flexible.** Ownership, licensing terms, and revenue splits can be updated by the DAO (Key 2 authority) without re-uploading the content.
- **Derivative works must generate new CIDs.** While new Metadata Bundles can be generated for derivative works (e.g., translations, remixes, or alternative licenses), each must reference a unique, derivative Content CID that includes the new work and links to the original CID. This preserves the original creator's economic claim (Key 1).
- **Content can be verified independently** of the IPFS-Sats application layer.
- **Existing content can be wrapped retroactively** with IPFS-Sats governance and economic logic by creating a new Metadata Bundle referencing an existing content CID.

### Traversal and Retrieval Access

Users can initiate content retrieval via path resolution: `/ipfs/QmMetadata.../content_cid`.

However, the host node's protocol logic enforces economic rules on retrieval:

- **The Content CID is not directly accessible:** While the CID path exists, the underlying file on the host node is protected by the IPFS-Sats protocol.
- **Authorization Token Required:** The host node demands a specific authorization token — generated during the initial Metadata Bundle traversal — to ensure the transaction is recorded and the micropayment payout from the Lightning Yield Wallet (LYW) is correctly triggered by Key 3.
- **Conclusion:** Without performing the authorized traversal to obtain the token, the file remains inaccessible, ensuring the host is always compensated for their service.

---

## 3.2.2 Bitcoin Blockchain Timestamping via Lightning Channel Anchoring ⏱️

**Economically Incentivized Temporal Proof**

IPFS-Sats achieves **trustless content timestamping** without incurring marginal cost for each file. This is accomplished by leveraging the economic necessity of the Lightning Network operation required to fund the user's Lightning Yield Wallet (LYW).

The timestamping operation is piggybacked onto a standard on-chain Bitcoin transaction, such as a channel funding or closing transaction. This provides **cryptographic proof of existence** at a specific Bitcoin block height at zero marginal cost, as the transaction fee is already being paid for the LYW funding process.

---

### The Anchoring Mechanism: OP_RETURN Embedding

When a creator initializes or tops up their LYW, the channel funding transaction is constructed to include an **OP_RETURN** output containing the Bundle Hash, anchoring it permanently to the Bitcoin blockchain.

**Data Hashing**

The Bundle Hash embedded in the chain is the hash of the Content CID and the Metadata Wrapper:

$$\text{Bundle Hash} = \text{Hash}(\text{Content CID} + \text{Metadata Wrapper})$$

This ensures that any subsequent alteration to either the content or the Metadata Wrapper renders the original on-chain timestamp invalid.

**Channel Funding Transaction Structure**

| Output | Purpose | Data |
|---|---|---|
| **Output 1** | Lightning Channel Funding | Destination Address |
| **Output 2** | Change | Remaining funds back to creator |
| **Output 3** | OP_RETURN (Timestamp) | 32-byte Bundle Hash |

The OP_RETURN opcode provides a globally verifiable, immutable record and ensures the output is provably unspendable, preventing UTXO set bloat.

**Verification Process**

Anyone can verify the content's existence time by following this trustless process:

1. **Retrieve the Metadata Bundle:** Obtain the Metadata Wrapper via its CID.
2. **Extract Data:** Extract the Content CID and the Bitcoin transaction ID (`tx_id`) from the Metadata Wrapper.
3. **Reconstruct Hash:** Recompute the Bundle Hash locally using Hash(Content CID + Metadata Wrapper).
4. **Query Blockchain:** Use the `tx_id` to retrieve the original transaction from any Bitcoin full node.
5. **Compare Proof:** Extract the 32-byte hash from the OP_RETURN output and compare it against the locally recomputed Bundle Hash.
6. **Confirm Time:** If the hashes match, the content's existence is verified to be no later than the timestamp of the Bitcoin block containing the confirmed transaction.

| Timestamping Method | Marginal Cost | Finality | Trust Model |
|---|---|---|---|
| **IPFS-Sats (Channel Anchor)** | ~$0 | 10–60 min | Trustless |
| Separate Blockchain TX | $1–$50 | 10–60 min | Trustless |
| OpenTimestamps Batch | $0.001–$0.01 | 10–60 min | Third-party Oracle |

---

### Application-Level Hash Chain for Continuous Provenance

Bitcoin anchoring only occurs periodically (when the LYW needs a top-up). To provide a continuous, verifiable history for intermediate works, updates, and derivative content, IPFS-Sats introduces an **Application-Level Hash Chain**.

**Hash-Chain Linking**

Each new Metadata Bundle contains the Bundle Hash of its predecessor in the `parent_bundle_hash` field:

- Original Content (M₁): `parent_bundle_hash = null`. Anchored on-chain.
- Derivative Work (M₂): `parent_bundle_hash = Hash(Content CID₁ + Metadata Wrapper₁)`
- Subsequent Work (M₃): `parent_bundle_hash = Hash(Content CID₂ + Metadata Wrapper₂)`

When M₃ is eventually anchored in a new Bitcoin transaction, the entire chain (M₁ → M₂ → M₃) is timestamped simultaneously.

**Provenance and Temporal Ordering**

1. **Temporal Ordering:** Since the Bundle Hash of the parent cannot be predicted, the child bundle must have been created *after* the parent. This establishes a strict, verifiable sequence of creation.
2. **Tamper-Evidence:** Changing any detail in an upstream bundle changes its Bundle Hash, immediately breaking all downstream links and exposing the alteration.
3. **Efficiency and Scalability:** Thousands of derivative works can be created between on-chain anchoring events, keeping the protocol efficient and scalable.

**Flexibility for High-Value Content**

For content requiring immediate, undisputed blockchain finality (e.g., patents, high-stakes legal contracts), creators can pay for a **dedicated anchor** Bitcoin transaction, bypassing the standard periodic channel-funding schedule.

---

### Updated Metadata Wrapper Structure

The complete Metadata Wrapper integrates the hybrid timestamping approach:

```json
{
  "content_cid": "QmOriginalContent...",

  "parent_bundle_hash": "a1b2c3d4e5f6..." ,

  "bitcoin_anchor": {
    "tx_id": "abc123def456...",
    "block_height": 875432,
    "op_return_hash": "d4e5f6...",
    "anchor_type": "channel_funding"
  },

  "ipfs_sats_metadata": { },
  "creator": { },
  "license": { },
  "title": "..."
}
```

---

## 3.2.3 IPFS-Sats Protocol Metadata

The Metadata Wrapper for every piece of content includes the essential, protocol-specific configuration data required for the IPFS-Sats economic and governance layers, housed within the `ipfs_sats_metadata` object.

### Protocol Data Structure

```json
{
  "version": "2.0",
  "wallet_address": "lnbc1...",
  "channel_id": "xyz789...",
  "dao_cid": "QmDAOconfig...",
  "smart_contract_hash": "sha256:abc..."
}
```

### Field Definitions

**`version`**
Specifies the protocol version for client compatibility, ensuring clients can handle changes in the protocol's structure or required transaction formats as the system evolves.

**`wallet_address`**
The Lightning Network payment destination tied to the creator's Lightning Yield Wallet (LYW). This is the content's economic interface — the point where value flows to creators from Zaps, retrieval payments, and automated royalties.

**`channel_id`**
The identifier of the specific Lightning Network channel used to anchor the content's Bundle Hash and fund the LYW. This field links the Metadata Bundle to its on-chain temporal proof.

**`dao_cid`**
A link to a separate DAG node that defines the content's DAO governance structure (Section 6). Storing governance as a separate CID allows the DAO configuration to be updated and shared across multiple related content pieces (e.g., all tracks on an album).

**`smart_contract_hash`**
The SHA-256 hash of the core smart contract code managing the content's economics — yield and royalty distribution, host payment verification, and licensing enforcement. This hash allows users and auditors to verify that the executed contract logic has not been tampered with.

---

## 3.2.4 Creator Identity & Signature 🔑

The **Creator Identity & Signature** object establishes provable authorship and ensures the integrity of the Metadata Wrapper. IPFS-Sats is **identity system agnostic**, supporting any cryptographic standard capable of generating a verifiable signature.

### Creator Identity Structure

```json
{
  "identity_type": "did:key",
  "identifier": "did:key:z6MkhaXgBZDvotDkL5...",
  "signature": "ed25519:A8B3C9D2E1F4...",
  "public_key": "base58:5Hd7YFqz...",
  "signature_algorithm": "ed25519"
}
```

### Universal Verification Requirements

Regardless of identity scheme, all entries must provide:

- **Public Identifier:** A unique, publicly-shareable string
- **Signature:** Cryptographic proof that the holder of the private key signed the current state of the Metadata Wrapper (minus the signature field itself)
- **Verification Algorithm:** Explicitly specified method required to perform the signature check
- **Public Key:** The key material needed to verify the signature against the Bundle Hash

### Supported Identity Types

| Identity Type | Scheme Example | Core Use Case |
|---|---|---|
| **W3C DID** | `did:key:z6Mkha...` | Institutions, Interoperability |
| **Nostr** | `npub1sg6plzptd...` | Social Media, Lightning-Native |
| **Bitcoin** | `bc1qxy2kgdygjr...` | Financial Applications, Simplicity |
| **Ethereum** | `0x71C7656EC7ab...` | Web3, NFT Ecosystems |
| **PGP/GPG** | Key Fingerprint | Developers, Security-Conscious Users |
| **Custom/Future** | `quantum-resistant-id...` | Future-Proofing, Post-Quantum |

### Why Agnosticism Matters

- **Accessibility:** Users face no identity lock-in — a developer can use an existing key while a Web3 artist uses their Ethereum wallet.
- **Future-Proofing:** The core protocol is decoupled from specific cryptographic implementations. New signature schemes are supported by adding a new `identity_type` handler.
- **Unified Identity:** For optimal economic functionality, creators are encouraged to use the same cryptographic key for both their content signature and their Lightning Wallet Address, creating a single auditable link between the signing key and the revenue recipient.

### Identity Verification Flow

```javascript
function verifyCreatorSignature(metadata) {
  const { identity_type, identifier, signature, public_key } = metadata.creator;
  const dataToVerify = prepareVerificationData(metadata);

  switch(identity_type) {
    case "did:key":
      return verifyDID(identifier, signature, dataToVerify);
    case "nostr":
      return verifyNostr(identifier, signature, dataToVerify);
    case "bitcoin":
      return verifyBitcoinSignature(identifier, signature, dataToVerify);
    case "custom":
      const verifier = await ipfs.get(metadata.creator.verification_method);
      return executeCustomVerifier(verifier, identifier, signature, dataToVerify);
    default:
      throw new Error(`Unsupported identity type: ${identity_type}`);
  }
}
```

---

## 3.2.5 Provenance & Fork Tracking 🌳

This section details the mechanism for creating a cryptographically verifiable genealogy of derivative works, linking content forks back to their origin while automating royalty distributions.

### Provenance Data Structure

```json
{
  "parent_cid": "QmParentMetadata...",
  "derivative_type": "remix",
  "royalty_terms": {
    "parent_percentage": 10,
    "attribution_required": true,
    "approval_needed": false
  }
}
```

### Fork Genealogy and Cascading Royalties

When content is built upon, the new Metadata Bundle creates a **provenance tree** by linking back to the previous Metadata Bundle CID via the `parent_cid` field, secured by the Application-Level Hash Chain (Section 3.2.2).

This enables **cascading royalties** automatically enforced by smart contract logic when a payment is received:

| Generation | Relationship | Royalty Action (Example: 1000 sats received) |
|---|---|---|
| **G3 (Mashup, Carol)** | Parent: Bob | Receives 900 sats. Triggers distribution to parent. |
| **G2 (Remix, Bob)** | Parent: Alice | Receives 10% of 1000 sats (100 sats). Triggers distribution upstream. |
| **G1 (Original, Alice)** | Parent: Null | Receives 10% of Bob's 100 sats (10 sats). |

### Derivative Types and Governance

The `derivative_type` field provides context for the parent-child relationship, aiding categorization and legal interpretation. Types include `"fork"`, `"remix"`, `"translation"`, `"compilation"`, and `"adaptation"`.

### Conditional Approval

If `approval_needed: true`, the fork remains unlisted until the parent creator's DAO votes to approve the proposal. The pending Metadata Bundle includes an `approval_status` object referencing the DAO Proposal CID:

```javascript
"approval_status": {
  "pending": true,
  "dao_proposal_cid": "QmProposal...",
  "votes": { "for": 3, "against": 1 }
}
```

---

## 3.2.6 Licensing & Terms ⚖️

The **Licensing & Terms** object defines the permissions and restrictions governing the use and derivation of the content, encoded in a machine-readable structure that enables automated enforcement, clear user display, and programmatic querying.

### Licensing Data Structure

```json
{
  "type": "custom",
  "terms_cid": "QmLicenseTerms...",
  "commercial_use": true,
  "attribution_required": true,
  "derivative_royalty": 10,
  "geographic_restrictions": [],
  "expiry_date": null
}
```

### Machine-Readable Licensing

- **Standard License Types:** For common licenses (e.g., MIT, CC-BY-SA, Public Domain), the `"type"` field references the well-known standard. Full legal text is stored at the `terms_cid`.
- **Automated Enforcement:** Fields like `commercial_use` and `derivative_royalty` are read directly by the smart contract to determine valid usage and automate royalty splits upon payment.

### Custom and Conditional Terms

**Tiered Commercial Licensing:**

```javascript
"license": {
  "type": "custom",
  "terms_cid": "QmCustomLicense...",
  "tiers": [
    { "use_case": "personal", "cost": 0, "attribution": true },
    { "use_case": "small_business", "cost": 10000, "revenue_limit": 100000 }
  ]
}
```

**Geographic and Time Restrictions:**

- `geographic_restrictions` specifies jurisdictions where the license applies or is prohibited. Nodes in restricted regions can still retrieve the content (maintaining censorship resistance), but the Metadata Wrapper explicitly indicates the legal constraints on its use.
- `expiry_date` allows licenses to automatically transition (e.g., from paid commercial use to public domain) at a specific date, validated by the smart contract before processing payments.

---

## 3.2.7 Descriptive Metadata 🔍

The **Descriptive Metadata** section provides human-readable and machine-indexable context for discoverability, searchability, and display across decentralized applications.

### Descriptive Data Structure

```json
{
  "title": "Symphony in D Minor",
  "description": "A haunting orchestral piece exploring themes of loss and redemption",
  "tags": ["classical", "orchestral", "symphony", "emotional"],
  "media_type": "audio/mpeg",
  "language": "en",
  "duration": 1847,
  "file_size": 45678901,
  "thumbnail_cid": "QmThumbnail...",
  "additional": {
    "composer": "Jane Doe",
    "performed_by": "City Orchestra",
    "recording_date": "2025-11-15",
    "instruments": ["violin", "cello", "piano", "flute"]
  }
}
```

### Fields for Discoverability

- **Standard Fields:** `title`, `description`, `tags`, `media_type`, and `language` allow decentralized search engines to index and categorize content without centralized services.
- **Extended Fields (`additional`):** An arbitrary object for domain-specific data (e.g., composer for music, resolution for video, dependencies for software), ensuring the protocol handles rich metadata for any asset type.
- **Thumbnail/Preview:** `thumbnail_cid` links to a small preview file enabling rich display in content catalogs and search results without requiring full file download.

---

## 3.2.8 Metadata Bundle Lifecycle

The complete Metadata Bundle is composed of the Content CID and the seven-component Metadata Wrapper. Its creation follows a precise sequence:

### Metadata Bundle Creation Flow

1. **Raw Content Upload:** The file is uploaded to the storage layer, generating the `content_cid`.
2. **External Data Fetch:** Current Bitcoin block height is queried, and the creator generates a digital signature using their cryptographic key.
3. **Wrapper Construction:** The complete Metadata Wrapper (protocol data, identity, descriptive fields) is assembled.
4. **Serialization:** The Wrapper is serialized using dag-cbor for efficient binary encoding and deterministic hashing.
5. **Wrapper Upload:** The serialized Wrapper is uploaded, generating the **Metadata Bundle CID** — the primary identifier for all interactions.
6. **Usage:** The Metadata Bundle CID is used for sharing, indexing, legal referencing, and triggering Lightning payments.

### Metadata Immutability vs. Updates (IPNS)

Changing any field in the Metadata Wrapper creates an entirely new Metadata Bundle CID, potentially breaking existing links.

**Solution: InterPlanetary Name System (IPNS)**

IPFS-Sats uses IPNS to provide a mutable pointer to the latest version of the Metadata Bundle:

1. The creator generates an IPNS name (often derived from their Decentralized Identifier).
2. This IPNS name initially points to the first Metadata Bundle CID (e.g., `/ipns/k51qzi...` → `QmBundle_v1`).
3. When a protocol-level update occurs (e.g., a DAO vote changes a royalty split), a new Metadata Bundle CID is generated (`QmBundle_v2`).
4. The creator signs an update pointing the same IPNS name to `QmBundle_v2`.

**Best Practice:**
- **Immutable References** (legal documents, long-term archives) should use the raw Metadata Bundle CID.
- **Dynamic References** (client applications, websites) should use the IPNS name to always resolve to the latest version.

---

## 3.2.9 Verification, Trust, and Anti-Plagiarism Guardrails 🛡️

The IPFS-Sats Metadata Bundle is designed to eliminate the need for centralized trust through a self-securing, multilayered verification system.

### Layered Cryptographic Trust

| Layer | Proof Element | Verification Check |
|---|---|---|
| **1. Content Integrity** | Content CID | Hash(Content) = Content CID — proves the file is unaltered |
| **2. Temporal Proof** | Bitcoin OP_RETURN | Block height exists and contains Bundle Hash — proves when the content existed |
| **3. Creator Identity** | DID Signature | Signature verifies against Creator's Public Key — proves who created it |
| **4. Provenance Chain** | Parent Bundle Hash | Links to a prior Metadata Bundle — proves history and derivative relationship |
| **5. Economic Validity** | Wallet Address | Lightning Wallet responds and DAO governance is auditable — proves economic functionality |

### Anti-Plagiarism and Attribution

The combination of Content CID (Layer 1) and Temporal Proof (Layer 2) makes plagiarism detectable and financially non-viable.

| Element | Alice (Original) | Bob (Theft Attempt) | Result |
|---|---|---|---|
| **Content CID** | QmSong... | QmSong... | **Match** — files are identical |
| **Metadata Bundle CID** | QmAliceBundle... | QmBobBundle... | **Mismatch** |
| **Bitcoin Block** | 875432 | 876890 | **Alice's is earlier** |
| **Wallet** | lnbc_alice... | lnbc_bob... | **Payment directed to Alice** |

Bob's theft fails because:
- He cannot forge an earlier OP_RETURN timestamp on the immutable Bitcoin blockchain
- He cannot forge Alice's signature
- Payment systems are directed to the wallet associated with the earlier Bundle Hash
- His own Metadata Bundle proves he came later

Legitimate forks succeed because:
- Explicit `parent_cid` attribution links back to the original
- Automated royalty payments flow to the parent wallet
- The `derivative_type` field provides clear legal context

### The Metadata Bundle as Complete Digital Asset Record

| Component | Function | Proof |
|---|---|---|
| **Content CID** | Content Identification | Cryptographic proof of **What** |
| **Bitcoin Anchor** | Temporal Proof | Cryptographic proof of **When** |
| **DID Signature** | Identity Proof | Cryptographic proof of **Who** |
| **Lightning Wallet** | Economic Infrastructure | Infrastructure for **Monetization** |
| **DAO / License** | Governance and Rights | Structure for **Ownership & Usage** |
| **Parent Bundle Hash** | Provenance Chain | Record for **Derivative Works** |

The Metadata Bundle is not merely a storage record — it is foundational infrastructure for digital rights, enabling the Right to Verify through cryptographic timestamps and the Right to Fork through automated royalties, while remaining compatible with the open, decentralized ethos of content-addressed networks.
