# 3.2 The Metadata Bundle: Timestamping, Identity, and Governance

While content addressing (Section 3.1) ensures that data is immutably identified by its cryptographic hash, the Metadata Bundle transforms a simple file into a complete digital asset with provenance, economic infrastructure, and governance. The Metadata Wrapper, stored as a separate DAG node, wraps the raw content CID with all the information necessary to establish ownership, enable verification, automate payments, manage licensing, and track derivative works. The Metadata Bundle is the key innovation that elevates content addressing from a storage primitive to a foundational layer for the Rights to Verify and Fork.

**The Metadata Bundle** is the complete package: the content CID combined with its Metadata Wrapper. The **Metadata Wrapper** is the structured data component — the seven-component object that describes, timestamps, and governs the content. The **Bundle Hash** is the cryptographic fingerprint of the complete bundle:

$$\text{Bundle Hash} = \text{Hash}(\text{Content CID} + \text{Metadata Wrapper})$$

**The Complete Metadata Wrapper Structure**

Every piece of content in IPFS-Sats has a Metadata Wrapper encoded in dag-cbor (Concise Binary Object Representation), a schema-less format that efficiently stores structured data with native support for CID links. The Metadata Wrapper includes seven core components:

```json
{
  // 1. CONTENT REFERENCE
  "content_cid": "QmOriginalContent...",

  // 2. TIMESTAMP PROOF
  "timestamp_proof": {
    "creation_time": 1735094400,
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
- **Metadata is flexible.** Ownership, licensing terms, and revenue splits can be updated by the DAO (Key 2 authority) without re-publishing the content.
- **Derivative works must generate new CIDs.** While new Metadata Bundles can be generated for derivative works (e.g., translations, remixes, or alternative licenses), each must reference a unique, derivative Content CID that includes the new work and links to the original CID. This preserves the original creator's economic claim (Key 1).
- **Content can be verified independently** of the IPFS-Sats application layer.
- **Existing content can be wrapped retroactively** with IPFS-Sats governance and economic logic by creating a new Metadata Bundle referencing an existing content CID.

### Traversal and Retrieval Access

Users can initiate content retrieval via path resolution: `/ipfs/QmMetadata.../content_cid`.

The host node's protocol logic enforces economic rules on retrieval:

- **The Content CID is not directly accessible:** The underlying file on the host node is protected by the IPFS-Sats protocol.
- **Authorization Token Required:** The host node demands a specific authorization token — generated during the initial Metadata Bundle traversal — to ensure the transaction is recorded and the micropayment payout from the Lightning Yield Wallet (LYW) is correctly triggered by Key 3.
- **Conclusion:** Without performing the authorized traversal to obtain the token, the file remains inaccessible, ensuring the host is always compensated for their service.

---

## 3.2.2 Bitcoin Blockchain Timestamping via Lightning Channel Anchoring ⏱️

**Economically Incentivized Temporal Proof**

IPFS-Sats achieves trustless content timestamping through a two-stage process that separates the act of proving existence from the act of making that proof conveniently queryable. Understanding this separation is essential to understanding the protocol's trust model.

---

### Stage 1: The Bundle Hash — The Root of Trust

The Bundle Hash is the authoritative proof of a content's existence at a point in time. It is computed before any network activity occurs:

$$\text{Bundle Hash} = \text{Hash}(\text{Content CID} + \text{Metadata Wrapper})$$

All fields of the Metadata Wrapper that are knowable at creation time are included in this computation:
- Creator identity and signature
- LYW wallet address
- DAO config CID
- License terms
- Descriptive metadata
- Parent Bundle Hash (if derivative)
- Protocol version

Critically, no Bitcoin transaction details are included — they do not exist yet at the time the Bundle Hash is computed. The Bundle Hash is stable and final before a single byte has touched the network.

**The Anchoring Mechanism: OP_RETURN Embedding**

The timestamping operation piggybacks onto a standard on-chain Bitcoin transaction associated with the creator's Lightning Yield Wallet — a channel opening, closing, or other channel operation the LYW is performing for its own economic reasons. The marginal cost is zero because the transaction fee is already being paid.

The channel transaction is constructed to include an **OP_RETURN** output containing the 32-byte Bundle Hash:

| Output | Purpose | Data |
|---|---|---|
| **Output 1** | Lightning Channel Funding | Destination Address |
| **Output 2** | Change | Remaining funds back to creator |
| **Output 3** | OP_RETURN (Timestamp) | 32-byte Bundle Hash |

The LYW `wallet_address` field in the Metadata Wrapper is what ties the content to the channel operation — the wallet that committed the Bundle Hash to Bitcoin is the same wallet managing the content's economics. This link is verifiable without any additional data structure.

Once the block is confirmed, the content's existence is proven to be no later than that block's timestamp. This proof is permanent and requires no further action to remain valid. Everything that follows is a convenience layer built on top of this root of trust.

**The Two-Stage Timing**

There is no requirement to rush the channel operation. The Bundle Hash can wait for the next naturally occurring LYW transaction. What matters is that when a channel operation does occur, the Bundle Hash travels with it at zero marginal cost. Creators who require immediate, undisputed finality for high-value content (e.g., patents, legal contracts) retain the option to pay for a **dedicated anchor** transaction on demand.

---

### Stage 2: The Anchor Record — The Convenience Layer

After the channel transaction is confirmed, the application knows three things it did not know before:

- The transaction ID (`tx_id`) containing the Bundle Hash
- The block height where it was confirmed
- The wallet address of the LYW that performed the operation

These fields, combined with the Metadata Bundle CID and Bundle Hash, form the **Anchor Record** — a record written into the **Records Database**, the distributed application-layer database maintained within the Host Discovery Layer. The Records Database holds three tables: Host Registry Records (Section 10.7), Anchor Records (Section 10.8) and Content Flag Records (Section 10.9). The Anchor Record table's function is: given a Metadata Bundle CID, return the Bitcoin transaction that proves its existence.

**Anchor Record schema (required fields):**

```json
{
  "metadata_bundle_cid": "QmBundle...",
  "bundle_hash":         "0xABCDEF...",
  "wallet_address":      "lnbc...",
  "tx_id":               "a1b2c3d4e5f6...",
  "block_height":        875432,
  "published_by":        "node_id...",
  "signature":           "..."
}
```

The `wallet_address` is the critical linking field — it matches the `wallet_address` in the Metadata Wrapper's `ipfs_sats_metadata`, proving that the node publishing the Anchor Record is the same LYW managing the content's economics. The signature is verifiable against that wallet's public key. Additional fields such as `op_return_data` and `anchor_type` are optional extensions that applications may include.

The Records Database provides the economic incentive for Anchor Record persistence. Nodes participate in the discovery layer because doing so earns them revenue through SatSwap exchanges — that incentive covers all tables in the database without requiring a separate economic wrapper per record.

**The trust hierarchy is clear:**
- The Bundle Hash on-chain is the authoritative proof — immutable, globally verifiable, requiring no intermediary
- The Anchor Record is the lookup mechanism — makes the proof conveniently queryable without requiring every verifier to scan the blockchain

The Anchor Record is eventually consistent. It settles at its own pace, driven by economic conditions rather than protocol urgency. The proof exists the moment the block is confirmed. The Anchor Record simply makes that proof accessible.

**Verification Process**

Anyone can verify a content's existence time:

1. Retrieve the Metadata Wrapper using the Metadata Bundle CID
2. Compute the Bundle Hash locally: `Hash(Content CID + Metadata Wrapper)`
3. Query the Records Database by Metadata Bundle CID to retrieve the Anchor Record
4. Use the `tx_id` from the Anchor Record to retrieve the transaction from any Bitcoin full node
5. Extract the 32-byte hash from the OP_RETURN output and compare against the locally computed Bundle Hash
6. If hashes match, content existed no later than the timestamp of the confirmed block

If no Anchor Record exists in the Records Database for a given Metadata Bundle CID, the channel operation has not yet occurred. This is a valid intermediate state — the Metadata Bundle exists and is queryable, but has not yet been committed to Bitcoin.

| Timestamping Method | Marginal Cost | Finality | Trust Model |
|---|---|---|---|
| **IPFS-Sats (Channel Anchor)** | ~$0 | 10–60 min | Trustless |
| Separate Blockchain TX | $1–$50 | 10–60 min | Trustless |
| OpenTimestamps Batch | $0.001–$0.01 | 10–60 min | Third-party Oracle |

---

### Application-Level Hash Chain for Continuous Provenance

Bitcoin anchoring only occurs when a LYW channel operation naturally occurs. To provide a continuous, verifiable history for intermediate works, updates, and derivative content between anchoring events, IPFS-Sats uses an **Application-Level Hash Chain**.

Each new Metadata Bundle contains the Bundle Hash of its predecessor in the `parent_bundle_hash` field:

- Original Content (M₁): `parent_bundle_hash = null`. Anchored on-chain when next channel operation occurs.
- Derivative Work (M₂): `parent_bundle_hash = Hash(Content CID₁ + Metadata Wrapper₁)`
- Subsequent Work (M₃): `parent_bundle_hash = Hash(Content CID₂ + Metadata Wrapper₂)`

When M₃ is eventually anchored, the entire chain (M₁ → M₂ → M₃) is timestamped simultaneously.

**Benefits of the hash chain:**

1. **Temporal Ordering:** The Bundle Hash of the parent cannot be predicted, so the child bundle must have been created after the parent — establishing a strict, verifiable sequence of creation.
2. **Tamper-Evidence:** Changing any detail in an upstream bundle changes its Bundle Hash, immediately breaking all downstream links and exposing the alteration.
3. **Efficiency:** Thousands of derivative works can be created between on-chain anchoring events without any on-chain cost.

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
The Lightning Network payment destination tied to the creator's Lightning Yield Wallet (LYW). This is the content's economic interface — the point where value flows to creators from Zaps, retrieval payments, and automated royalties. This is also the wallet that will perform the channel operation embedding the Bundle Hash in Bitcoin, establishing the link between the content and its on-chain timestamp.

**`channel_id`**
The identifier of the specific Lightning Network channel associated with this LYW. Links the Metadata Bundle to its economic infrastructure.

**`dao_cid`**
A link to a separate DAG node defining the content's DAO governance structure (Section 6). Storing governance as a separate CID allows the DAO configuration to be updated and shared across multiple related content pieces.

**`smart_contract_hash`**
The SHA-256 hash of the core smart contract code managing the content's economics — yield and royalty distribution, host payment verification, and licensing enforcement. Allows users and auditors to verify the executed contract logic has not been tampered with.

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

- **Public Identifier:** A unique, publicly shareable string
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
| **G3 (Mashup, Carol)** | Parent: Bob | Receives 900 sats. Triggers distribution upstream. |
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
- `expiry_date` allows licenses to automatically transition at a specific date, validated by the smart contract before processing payments.

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
- **Extended Fields (`additional`):** An arbitrary object for domain-specific data, ensuring the protocol handles rich metadata for any asset type.
- **Thumbnail/Preview:** `thumbnail_cid` links to a small preview file enabling rich display in content catalogs without requiring full file download.

---

## 3.2.8 Metadata Bundle Lifecycle

The Metadata Bundle comes into existence through a precise sequence that separates local computation from network publication, and separates the stable core record from the eventually consistent anchor proof. Understanding this sequence is essential to understanding why the Bundle Hash is trustworthy and why the Metadata Bundle CID is permanently stable.

### Creation and Publication Sequence

**Step 1: Content hashing (local)**
The content is hashed locally by the application. No network activity occurs. The Content CID is generated deterministically from the content itself. The content is then made available to the network — pinned locally and served to peers who request it by CID.

**Step 2: Metadata Wrapper assembly (local)**
All knowable fields are assembled into the Metadata Wrapper:
- Content CID reference
- Creator identity and signature
- LYW wallet address and DAO config CID
- License terms
- Descriptive metadata
- Parent Bundle Hash (if this is a derivative work)
- Protocol version and smart contract hash

No Bitcoin transaction details are included at this stage — they do not yet exist and cannot be included without creating a circular dependency.

**Step 3: Bundle Hash computation (local)**
The Bundle Hash is computed: `Hash(Content CID + Metadata Wrapper)`. This hash is final and stable. The Metadata Wrapper is serialized using dag-cbor, generating the **Metadata Bundle CID** — the primary identifier for all future interactions. The Metadata Bundle is published to the network. The CID will never change.

**Step 4: Bitcoin anchoring (asynchronous)**
The Bundle Hash waits for the next natural Lightning channel operation on the creator's LYW — a channel open, close, or other on-chain transaction the wallet is performing for its own economic reasons. When that operation occurs, the Bundle Hash is embedded in the OP_RETURN output at zero marginal cost. There is no urgency — the Bundle Hash can wait indefinitely for the right moment. Creators requiring immediate finality may initiate a dedicated anchor transaction at their own cost.

**Step 5: Anchor Record written to Records Database (after confirmation)**
Once the channel transaction is confirmed, the application writes the **Anchor Record** to the Records Database — the distributed application-layer database maintained within the Host Discovery Layer:

```json
{
  "metadata_bundle_cid": "QmBundle...",
  "bundle_hash":         "0xABCDEF...",
  "wallet_address":      "lnbc...",
  "tx_id":               "a1b2c3d4e5f6...",
  "block_height":        875432,
  "published_by":        "node_id...",
  "signature":           "..."
}
```

The Anchor Record is the lookup mechanism that makes the on-chain proof conveniently queryable — not the proof itself. The proof is the Bundle Hash in the Bitcoin block. The Records Database provides the economic incentive for persistence through the same participation incentive that sustains the Host Registry Record table.

### The Two Cost Profiles

This sequence introduces two distinct cost events with different urgency profiles:

| Event | Cost | Timing | Urgency |
|---|---|---|---|
| **Bundle Hash anchoring** | ~$0 marginal (piggybacks on LYW channel operation) | Next natural channel operation | None — wait for economically justified transaction |
| **Anchor Record write** | Records Database participation cost | After channel confirmation | None — eventually consistent, proof already exists on-chain |

The protocol imposes no deadline on either event. Both are driven by economic conditions, not protocol requirements.

### Metadata Immutability vs. Updates (IPNS)

Publishing a new Metadata Wrapper creates a new Metadata Bundle CID, potentially breaking existing references. IPFS-Sats uses **IPNS** to provide a mutable pointer to the latest version:

1. The creator generates an IPNS name (often derived from their Decentralized Identifier)
2. The IPNS name initially points to the first Metadata Bundle CID
3. When a protocol-level update occurs (e.g., a DAO vote changes a royalty split), a new Metadata Bundle CID is generated
4. The creator signs an update pointing the same IPNS name to the new CID

**Best Practice:**
- **Immutable References** (legal documents, long-term archives) should use the raw Metadata Bundle CID
- **Dynamic References** (client applications, websites) should use the IPNS name to always resolve to the latest version

---

## 3.2.9 Verification, Trust, and Anti-Plagiarism Guardrails 🛡️

The IPFS-Sats Metadata Bundle is designed to eliminate the need for centralized trust through a self-securing, multilayered verification system.

### Layered Cryptographic Trust

| Layer | Proof Element | Verification Check |
|---|---|---|
| **1. Content Integrity** | Content CID | Hash(Content) = Content CID — proves the file is unaltered |
| **2. Temporal Proof** | Bitcoin OP_RETURN via Anchor Record | Block height contains Bundle Hash — proves when the content existed |
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
