## 3.2 The Metadata Bundle: Timestamping, Identity, and Governance

While content addressing (Section 3.1) ensures that data is immutably identified by its cryptographic hash, the metadata bundle transforms a simple file into a complete digital asset with provenance, economic infrastructure, and governance. This metadata object, stored as a separate IPFS DAG node, wraps the raw content CID with all the information necessary to establish ownership, enable verification, automate payments, manage licensing, and track derivative works. The metadata bundle is the key innovation that elevates IPFS from a storage protocol to a foundational layer for the Rights to Verify and Fork.

**The Complete Metadata Structure**

Every piece of content uploaded to IPFS-Sats generates a metadata object encoded in dag-cbor (Concise Binary Object Representation), a schema-less format that efficiently stores structured data with native support for IPFS CID links. This object includes seven core components:

```
{
// 1. CONTENT REFERENCE
  "content_cid": "QmOriginalContent...",
  
// 2. TIMESTAMP PROOF
"timestamp_proof": {
  "creation_time": 1735094400,            // Unix timestamp of creation
  "anchor_details": {
    "bitcoin_block": 875432,              // Bitcoin block height of the ON-CHAIN anchor
    "tx_id": "a1b2c3d4e5f6...",           // Transaction ID containing the final hash (channel settlement)
    "op_return_data": "0xHASH..."         // The full Bundle Hash embedded in the OP_RETURN
  },
  "provenance_chain": {
    "bundle_hash": "0xABCDEF...",         // SHA-256 hash of the current Content CID + entire Metadata Bundle
    "parent_bundle_hash": "0x012345...", // Mandatory hash of the PREVIOUS content's Bundle Hash
    "is_fork": false                      // Flag indicating this is a derivative work
  }
  
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
  "parent_cid": null,  // or QmParentMetadata...
  "derivative_type": null,  // "remix", "translation", "fork"
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

### 3.2.1. Content Reference 🔗

```json
"content_cid": "QmOriginalContent..."
```

This is the **Content CID**—a direct, immutable link to the raw data file stored in the IPFS network. By separating this immutable content hash from the mutable metadata object, IPFS-Sats preserves **content immutability**. The raw file's $\text{CID}$ never changes, enabling universal deduplication and cryptographic verification.

#### Why Separate? (Revised)

Separating the immutable Content $\text{CID}$ from the mutable Content Metadata Object allows for dynamic governance without sacrificing content integrity:

  * **Content remains immutable.** The $\text{CID}$ never changes, ensuring verifiable authenticity, even if ownership or licenses are updated.
  * **Metadata is flexible.** Ownership, licensing terms, and revenue splits can be updated by the DAO ($\text{Key 2}$ authority) without re-uploading the content.
  * **Derivative works must generate new CIDs.** While new **Content Metadata Objects** can be generated for derivative works (e.g., translations, remixes, or alternative licenses), **each must generate a unique, derivative Content $\text{CID}$** that includes the new work and references the original $\text{CID}$ as a component. This prevents plagiarism and preserves the original creator's economic claim ($\text{Key 1}$).
  * **Content can be verified independently** of the IPFS-Sats application layer.
  * **Existing IPFS content can be "wrapped" retroactively** with IPFS-Sats governance and economic logic.

#### Traversal and Retrieval Access

Users can initiate content retrieval via IPFS path resolution: `/ipfs/QmMetadata.../content_cid`.

However, the host node's protocol logic enforces economic rules on retrieval:

  * **The Content CID is inaccessible directly:** While the $\text{CID}$ path exists, the underlying file on the host node is protected by the IPFS-Sats protocol.
  * **Authorization Token Required:** The host node's protocol demands a specific **authorization token**—generated during the initial metadata traversal—to ensure the transaction is recorded and the micropayment payout from the $\text{Lightning Yield Wallet}$ ($\text{LYW}$) is correctly triggered by $\text{Key 3}$.
  * **Conclusion:** Without performing the authorized traversal to obtain the token, the file remains inaccessible, ensuring the host is always compensated for their service.

### 3.2.2 Bitcoin Blockchain Timestamping via Lightning Channel Anchoring ⏱️

**Economically Incentivized Temporal Proof**

IPFS-Sats achieves **trustless content timestamping** without incurring marginal cost for each file. This is accomplished by leveraging the **economic necessity** of the Lightning Network operation required to fund the user's **Lightning Yield Wallet (LYW)**.

The timestamping operation is piggybacked onto a standard on-chain Bitcoin transaction, such as a channel funding or closing transaction. This provides **cryptographic proof of existence** at a specific Bitcoin block height with a marginal cost of zero, as the transaction fee is already being paid for the LYW funding process.

-----

**The Anchoring Mechanism: OP\_RETURN Embedding**

When a creator initializes or tops up their LYW, the channel funding transaction is constructed to include an **OP_RETURN** output. This output contains a $\text{SHA256}$ hash of the content's critical data bundle, anchoring it permanently to the Bitcoin blockchain.

**Data Hashing**

The data embedded in the chain is the hash of a combination of the **Content CID** and the complete **Metadata Bundle**. This ensures that any subsequent alteration to either the content or the associated metadata renders the original on-chain timestamp invalid.

$$
\text{AnchorHash} = \text{SHA256}(\text{Content CID} + \text{JSON}(\text{Metadata Bundle}))
$$

**Channel Funding Transaction Structure**

The on-chain transaction that establishes the Lightning channel includes the content's proof in an unspendable output:

| Output | Purpose | Data |
| :--- | :--- | :--- |
| **Output 1** | Lightning Channel Funding | Destination Address (e.g., $0.001 \text{ BTC}$) |
| **Output 2** | Change | Remaining funds back to the creator |
| **Output 3** | OP_RETURN (Timestamp) | $32\text{-byte } \text{AnchorHash}$ |

The OP_RETURN opcode provides a globally verifiable, immutable record with low overhead (only $\sim 10$ bytes of transaction weight) and ensures the output is provably unspendable, preventing UTXO set bloat.

**Verification Process**

Anyone can verify the content's existence time by following a simple, trustless process:

1.  **Retrieve Metadata:** Obtain the metadata bundle (via its CID).
2.  **Extract Data:** Extract the **Content CID** and the **Bitcoin transaction ID ($tx\_id$)** from the bundle.
3.  **Reconstruct Hash:** Recompute the $\text{AnchorHash}$ locally using the $\text{SHA256}$ function on the extracted data.
4.  **Query Blockchain:** Use the $tx\_id$ to retrieve the original transaction from any Bitcoin full node.
5.  **Compare Proof:** Extract the $32$-byte hash from the $OP\_RETURN$ output and compare it against the locally recomputed $\text{AnchorHash}$.
6.  **Confirm Time:** If the hashes match, the content's existence is verified to be no later than the timestamp of the Bitcoin block containing the confirmed transaction.

| Timestamping Method | Marginal Cost | Finality | Trust Model |
| :--- | :--- | :--- | :--- |
| **IPFS-Sats (Channel Anchor)** | ~ $0 | 10 - 60 min | Trustless |
| Separate Blockchain TX | $1 - $50 | 10 - 60 min | Trustless |
| OpenTimestamps Batch | $0.001 - $0.01 | 10 - 60 min | Third-party Oracle |

-----

**Application-Level Hash Chain for Continuous Provenance**

Bitcoin anchoring only occurs periodically (when the LYW needs a top-up). To provide a continuous, verifiable history for intermediate works, updates, and derivative content, IPFS-Sats introduces an **Application-Level Hash Chain**.

**Hash-Chain Linking**

This application-level chain is built by modifying the **Metadata Bundle** structure to include a cryptographic link to its predecessor. Each new content's metadata bundle contains the **complete hash of its parent's metadata bundle** (which itself includes the parent's content CID).

- Original Content (M_1): parent_bundle_hash = null. Anchored on-chain.
- Derivative Work (M_2): parent_bundle_hash = Hash(M_1).
- Subsequent Work (M_3): parent_bundle_hash = Hash(M_2).


When $M3$ is eventually anchored in a new Bitcoin transaction, the entire chain ($M_1 \to M_2 \to M_3$) is timestamped simultaneously.

**Provenance and Temporal Ordering**

This hash-chain design provides several key benefits:

1.  **Temporal Ordering:** Since the hash of the parent bundle is deterministic and cannot be predicted, the child bundle **must** have been created *after* the parent. This establishes a strict, verifiable sequence of creation.
2.  **Tamper-Evidence:** Changing any detail in an upstream bundle (e.g., $M_1$) changes its hash, which immediately breaks the link to the downstream bundles ($M_2, M_3$), exposing the alteration.
3.  **Efficiency and Scalability:** Thousands of derivative works can be created between expensive on-chain anchoring events, ensuring the protocol remains efficient and scalable.

**Flexibility for High-Value Content**

For content that requires immediate, undisputed blockchain finality (e.g., patents, high-stakes legal contracts), creators retain the option to pay a dedicated fee for an **immediate anchor** Bitcoin transaction, bypassing the standard periodic channel-funding schedule. This flexibility allows the user to choose their cost/security tradeoff.

-----

**Updated Metadata Bundle Structure**

The final metadata bundle integrates the hybrid timestamping approach:

```
{
  "content_cid": "QmOriginalContent...",
  
  // Parent linking for hash-chain
  "parent_bundle_hash": "a1b2c3d4e5f6..." | null,
  "fork_tracking": { ... },
  
  // Bitcoin blockchain anchor (when available)
  "bitcoin_anchor": {
    "tx_id": "abc123def456...", 
    "block_height": 875432, 
    "op_return_hash": "d4e5f6...", 
    "anchor_type": "channel_funding" | "dedicated" // Identifies cost structure
  },
  
  // Lightning Yield Wallet and Creator info
  "ipfs_sats_metadata": { ... },
  "creator": { ... },
  
  // Licensing and descriptive metadata
  "license": { ... },
  "title": "..."
}
```

## 3.2.3 IPFS-Sats Protocol Metadata

The **Metadata Bundle** for every piece of content includes the essential, protocol-specific configuration data required for the IPFS-Sats economic and governance layers. This data is housed within the `ipfs_sats_metadata` object.

This information directs clients on how to interact with the economic layer (payment, royalties) and the governance layer (DAO structure) associated with the content.

### Protocol Data Structure

```json
{
  "version": "2.0",                       // Protocol version for client compatibility
  "wallet_address": "lnbc1...",           // Lightning payment destination (LYW)
  "channel_id": "xyz789...",              // Associated Lightning Channel Anchor
  "dao_cid": "QmDAOconfig...",            // IPFS CID of the DAO configuration
  "smart_contract_hash": "sha256:abc..."  // Hash of the core smart contract logic
}
```

-----

### Field Definitions

  * **Version**
    :   Specifies the **Protocol Version** (e.g., "2.0"). This field ensures **forward compatibility**, allowing IPFS-Sats clients to appropriately handle changes in the protocol's structure, rules, or required transaction formats as the system evolves.

  * **Wallet Address**
    :   The **Lightning Network payment destination** tied to the creator's **Lightning Yield Wallet (LYW)**. This is the content's **economic interface**—the point where value flows to creators. It receives payments from various sources:
    \* **Zaps:** Value-for-value tips from appreciative users.
    \* **Retrieval Payments:** Micropayments for data delivery (when applicable).
    \* **Royalties:** Automated revenue from derivative works.

  * **Channel ID**
    :   The identifier of the specific Lightning Network channel used to anchor the content's timestamp and fund the LYW. This field links the content to its **on-chain temporal proof**.

  * **DAO CID**
    :   A link to a separate **IPFS object** that defines the content's **Decentralized Autonomous Organization (DAO) governance structure** (detailed further in Section 6). This configuration typically includes:
    \* Member list and voting weights.
    \* Quorum and threshold requirements for proposals.
    \* Revenue distribution formulas.

    Storing governance as a separate CID allows the DAO configuration to be **updated** (creating a new DAO CID) and **shared** across multiple related content pieces (e.g., all tracks on an album).

  * **Smart Contract Hash**
    :   The $\text{SHA-256}$ hash fingerprint of the **core smart contract code** responsible for managing the content's economics. This contract manages crucial logic, including:
    \* Yield and royalty distribution.
    \* Host node payment verification.
    \* Licensing enforcement.

    This hash serves as an **immutable fingerprint**, allowing users and auditors to verify that the executed contract logic has not been tampered with. The full contract code is typically retrievable via the DAO configuration.

## 3.2.4 Creator Identity & Signature 🔑

The **Creator Identity & Signature** object is essential for establishing **provable authorship** and ensuring the integrity of the content's metadata. IPFS-Sats is designed to be **Identity System Agnostic**, supporting any cryptographic standard capable of generating a verifiable signature. This maximizes accessibility while enforcing the core requirement of **cryptographic proof**.

### Creator Identity Structure

This structure holds the necessary elements for verification: the identifier, the method used, and the cryptographic proof that the creator authorized the metadata bundle.

```json
{
  "identity_type": "did:key",       // Standard or scheme (e.g., "nostr", "bitcoin")
  "identifier": "did:key:z6MkhaXgBZDvotDkL5...", // The creator's public identifier
  "signature": "ed25519:A8B3C9D2E1F4...",    // Cryptographic proof of authorization
  "public_key": "base58:5Hd7YFqz...",      // Public key for signature verification
  "signature_algorithm": "ed25519"         // Algorithm used (e.g., "secp256k1")
}
```

-----

### Universal Verification Requirements

Regardless of the identity scheme chosen, all entries must adhere to the following principles to enable universal verification by any IPFS-Sats client:

  * **Public Identifier:** A unique, publicly-shareable string (e.g., $\text{npub}$ or $\text{bc1}$ address).
  * **Signature:** Cryptographic proof that the holder of the private key signed the current state of the metadata bundle (minus the signature field itself).
  * **Verification Algorithm:** Explicitly specified method (e.g., $\text{secp256k1}$ or $\text{ed25519}$) required to perform the signature check.
  * **Public Key (or derivable):** The key material needed to verify the signature against the hash of the metadata.

### Flexibility and Supported Identity Types

IPFS-Sats supports a wide range of popular cryptographic standards, allowing creators to use an identity they already control, reducing friction and maximizing adoption.

| Identity Type | Scheme Example | Core Use Case & Rationale |
| :--- | :--- | :--- |
| **W3C DID** | `did:key:z6Mkha...` | **Institutions, Interoperability.** Self-sovereign, multi-method, and aligned with global decentralized identity standards. |
| **Nostr** | `npub1sg6plzptd...` | **Social Media, Lightning-Native.** Uses $\text{secp256k1}$ cryptography, integrating directly with the Nostr social protocol and Bitcoin community. |
| **Bitcoin** | `bc1qxy2kgdygjr...` | **Financial Applications, Simplicity.** Proves control of a Bitcoin private key, often the same key used for the Lightning wallet. |
| **Ethereum** | `0x71C7656EC7ab...` | **Web3, NFT Ecosystems.** Compatible with Ethereum's signing standards ($\text{EIP-191}/\text{EIP-712}$) and smart contract interaction. |
| **PGP/GPG** | Key Fingerprint | **Developers, Security-Conscious Users.** Long-established, reliable standard used for software provenance and email security. |
| **Custom/Future** | `quantum-resistant-id...` | **Future-Proofing.** Allows for the inclusion of new, even post-quantum, algorithms (e.g., **Dilithium**), with verification code referenced via IPFS. |

-----

### Why Agnosticism Matters

This identity-agnostic design provides substantial benefits for the protocol's ecosystem:

  * **Accessibility:** Users do not face **identity lock-in**. A developer can use their established SSH key, while a Web3 artist uses their Ethereum wallet, all within the same IPFS-Sats protocol.
  * **Future-Proofing:** The core protocol is decoupled from specific cryptographic implementations. As quantum-resistant or other advanced signature schemes emerge, IPFS-Sats can support them simply by adding a new `identity_type` handler.
  * **Unified Identity (Binding):** For optimal economic functionality, creators are encouraged to use the same cryptographic key to generate both their **Content Signature** and their **Lightning Wallet Address**, creating a single, auditable link: "The key that signed the content is the key that receives the revenue."

### Identity Verification Flow

Clients verify the creator's identity by dynamically selecting the correct verification library based on the `identity_type` specified in the metadata:

```javascript
function verifyCreatorSignature(metadata) {
  const { identity_type, identifier, signature, public_key, signature_algorithm } = metadata.creator;
  const dataToVerify = prepareVerificationData(metadata); // Hash of the metadata minus the signature field
  
  // Select verification method based on identity type
  switch(identity_type) {
    case "did:key":
      return verifyDID(identifier, signature, dataToVerify);
    case "nostr":
      return verifyNostr(identifier, signature, dataToVerify);
    case "bitcoin":
      return verifyBitcoinSignature(identifier, signature, dataToVerify);
    // ... handles all other supported types
    case "custom":
      // Load and execute custom verification logic from IPFS
      const verifier = await ipfs.get(metadata.creator.verification_method);
      return executeCustomVerifier(verifier, identifier, signature, dataToVerify);
    default:
      throw new Error(`Unsupported identity type: ${identity_type}`);
  }
}
```

## 3.2.5 Provenance & Fork Tracking 🌳

This section details the mechanism for creating a **cryptographically-verifiable genealogy** of derivative works, linking content forks back to their origin while automating royalty distributions.

### Provenance Data Structure

The metadata for any content created as a derivative must include the following structure, which dictates its relationship and economic terms with its parent work.

```json
{
  "parent_cid": "QmParentMetadata...",    // Links to the metadata of the direct parent work
  "derivative_type": "remix",              // Type of derivative ("fork", "remix", "translation", etc.)
  "royalty_terms": {
    "parent_percentage": 10,             // Percentage of revenue flowing to the parent creator
    "attribution_required": true,
    "approval_needed": false             // Does the parent's DAO need to approve publication?
  }
}
```

-----

### Fork Genealogy and Cascading Royalties

When content is built upon, the new metadata object creates a **provenance tree** by linking back to the previous work's metadata CID via the **`parent_cid`** field. This linkage is secured by the **Application-Level Hash Chain** (as discussed in Section 3.2.2).

#### Smart Contract Enforcement

This genealogy enables **cascading royalties**, which are automatically enforced by the core smart contract logic when a payment is received. The smart contract traces the parent links backwards to distribute revenue transparently and instantly.

| Generation | Relationship | Royalty Action (Example: 1000 sats received) |
| :--- | :--- | :--- |
| **G3 (Mashup, Carol)** | Parent: Bob | Receives 900 sats. Triggers distribution to parent. |
| **G2 (Remix, Bob)** | Parent: Alice | Receives $10\%$ of 1000 sats (100 sats). Triggers distribution to Bob's parent. |
| **G1 (Original, Alice)** | Parent: Null | Receives $10\%$ of Bob's 100 sats (10 sats). |

This mechanism ensures all contributors in the supply chain are compensated without needing complex legal agreements or manual payments.

-----

### Derivative Types and Governance

The **`derivative_type`** field provides context for the relationship between the parent and child works, aiding in categorization and legal interpretation (e.g., distinguishing a "commentary" from a "remix").

  * **Categorization:** Types include `"fork"`, `"remix"`, `"translation"`, `"compilation"`, and `"adaptation"`.
  * **Legal Context:** These categories assist users, search engines, and potential legal systems in applying appropriate standards like fair use.

#### Conditional Approval

Creators have the ability to enforce control over their content's derivatives using the **`approval_needed`** flag in the `royalty_terms`.

  * If **`approval_needed: true`**, the fork remains **unlisted** and pending until the **parent creator's DAO** (referenced via the parent's `dao_cid`) votes to approve the proposal.
  * The pending fork's metadata includes an `approval_status` object, referencing the **DAO Proposal CID** and tracking the votes, thus baking the governance status directly into the content's metadata.

<!-- end list -->

```javascript
// Metadata for a pending fork requiring approval:
"approval_status": {
  "pending": true,
  "dao_proposal_cid": "QmProposal...", // Link to the proposal on IPFS
  "votes": { "for": 3, "against": 1 }
}
```

## 3.2.6 Licensing & Terms ⚖️

The **Licensing & Terms** object defines the permissions and restrictions governing the use and derivation of the content. Instead of relying solely on opaque legal text, IPFS-Sats encodes these terms into a **machine-readable structure**. This approach enables automated enforcement, clear user display, and programmatic querying by client applications.

### Licensing Data Structure

The primary licensing structure provides a concise summary of the content's rights.

```json
{
  "type": "custom",                     // Standard (e.g., "MIT", "CC-BY") or "custom"
  "terms_cid": "QmLicenseTerms...",     // IPFS CID of the full, legally-binding license text
  "commercial_use": true,               // Boolean: Does the license allow commercial derivatives?
  "attribution_required": true,         // Boolean: Must the creator be credited?
  "derivative_royalty": 10,             // Default royalty percentage for new derivatives (0-100)
  "geographic_restrictions": [],        // Optional array of jurisdictions (e.g., ["US", "EU"])
  "expiry_date": null                   // Optional UTC timestamp for license expiration
}
```

-----

### Machine-Readable Licensing

The core function of this section is to transform complex legal terms into actionable data points.

  * **Standard License Types:** For common, pre-defined licenses (e.g., **MIT**, **CC-BY-SA**, **Public-Domain**), the `"type"` field references the well-known standard. The full legal text is stored at the **`terms_cid`** for necessary legal reference, providing both clarity and depth.
  * **Automated Enforcement:** Fields like **`commercial_use`** and **`derivative_royalty`** are read directly by the smart contract to determine valid usage and to automate royalty splits upon payment.

### Custom and Conditional Terms

IPFS-Sats allows creators to define highly specific, complex licensing structures using the `"type": "custom"` field.

#### Tiered Commercial Licensing

Creators can define usage tiers based on factors like revenue limits or use case, each with different cost structures.

```javascript
// Example of a custom, tiered license structure:
"license": {
  "type": "custom",
  "terms_cid": "QmCustomLicense...",
  "tiers": [
    {
      "use_case": "personal",
      "cost": 0,
      "attribution": true
    },
    {
      "use_case": "small_business",
      "cost": 10000, // Cost in sats for a license
      "revenue_limit": 100000 // Annual revenue cap
    }
  ]
}
```

#### Geographic and Time Restrictions

These optional fields introduce temporal or jurisdictional limits on the license, which are enforceable at the application and smart contract layers:

  * **Geographic Restrictions:** The **`geographic_restrictions`** array specifies jurisdictions where the license applies (e.g., `restriction_type: "allow"`) or is prohibited (`restriction_type: "deny"`). While IPFS-Sats nodes in restricted regions can still retrieve the content (maintaining censorship resistance), the metadata explicitly indicates the legal constraints on its use.
  * **Time-Limited Licenses:** The **`expiry_date`** field allows for licenses to automatically transition (e.g., from paid commercial use to public domain) at a specific date. The smart contract validates the current time against this field before processing any related payment or royalty.

## 3.2.7 Descriptive Metadata 🔍

The **Descriptive Metadata** section provides human-readable and machine-indexable context about the content itself. Unlike the protocol-specific fields (Sections 3.2.3–3.2.6), these fields are primarily designed for **discoverability, searchability, and display** across decentralized applications.

### Descriptive Data Structure

This object includes both standard, recognized fields and an arbitrary extension field for specialized details.

```json
{
  "title": "Symphony in D Minor",
  "description": "A haunting orchestral piece exploring themes of loss and redemption",
  "tags": ["classical", "orchestral", "symphony", "emotional"],
  "media_type": "audio/mpeg",
  "language": "en",
  "duration": 1847,           // In seconds
  "file_size": 45678901,      // In bytes
  "thumbnail_cid": "QmThumbnail...",
  "additional": {
    "composer": "Jane Doe",
    "performed_by": "City Orchestra",
    "recording_date": "2025-11-15",
    "instruments": ["violin", "cello", "piano", "flute"]
  }
}
```

-----

### Fields for Discoverability

Descriptive metadata allows decentralized search engines to index and categorize content **without relying on centralized services**.

  * **Standard Fields:** Include universally recognized data points like **`title`**, **`description`**, **`tags`** (keywords for categorization), **`media_type`** (MIME type for client rendering), and **`language`** (ISO 639-1 code).
  * **Extended Fields (`additional`):** This arbitrary object allows creators to include structured, domain-specific data (e.g., *composer* for music, *resolution* for video, *dependencies* for software). This ensures the protocol can handle rich metadata for any asset type.
  * **Thumbnail/Preview:** The **`thumbnail_cid`** links to a small, optimized preview file (e.g., a 200x200px image, a 30-second audio clip). This enables client applications to provide **rich preview displays** for content catalogs and search results without requiring the download of the full, large file.

-----

## Metadata Object Lifecycle

The complete metadata bundle is a complex object composed of all seven component sections (3.2.1 through 3.2.7). Its creation follows a precise sequence:

### Metadata Object Creation Flow

1.  **Raw Content Upload:** The file is uploaded to IPFS, generating the `content_cid`.
2.  **External Data Fetch:** Current Bitcoin block height is queried, and the creator generates a digital signature using their cryptographic key.
3.  **Bundle Construction:** The complete metadata object (including protocol data, identity, and descriptive fields) is assembled.
4.  **Serialization:** The object is serialized using **dag-cbor** for efficient, binary encoding and deterministic hashing.
5.  **Metadata Upload:** The serialized bundle is uploaded to IPFS, generating the **`metadata_cid`** (the primary, immutable identifier).
6.  **Usage:** The `metadata_cid` is used for all interactions: sharing, indexing, legal referencing, and triggering Lightning payments.

### Metadata Immutability vs. Updates (IPNS)

The core challenge of content-addressing is that changing a single field in the metadata creates an entirely new `metadata_cid`, potentially breaking existing links.

#### Solution: InterPlanetary Name System (IPNS)

IPFS-Sats uses **IPNS** to provide a **mutable pointer** to the latest version of the immutable metadata object.

1.  The creator generates an **IPNS name** (often derived from their **Decentralized Identifier**).
2.  This IPNS name is initially signed to point to the first metadata version (e.g., `/ipns/k51qzi...` $\to$ `QmMetadata_v1`).
3.  When a protocol-level update occurs (e.g., a DAO vote changes a royalty split), a new metadata CID is generated (e.g., `QmMetadata_v2`).
4.  The creator signs an update that points the **same IPNS name** to the new `QmMetadata_v2`.

**Best Practice:**

  * **Immutable References** (e.g., legal documents, long-term archives) should use the raw **`metadata_cid`**.
  * **Dynamic References** (e.g., client applications, websites) should use the **IPNS name** to ensure they always resolve to the latest, most up-to-date version of the content's configuration and rights.

## 3.2.8 Verification, Trust, and Anti-Plagiarism Guardrails 🛡️

The IPFS-Sats metadata bundle is designed to eliminate the need for centralized trust by establishing a **self-securing, multilayered verification system**. This architecture inherently serves as a powerful **anti-plagiarism guardrail**, transforming raw content into a cryptographically proven digital asset.

---

### Layered Cryptographic Trust

Verification of an asset does not rely on trusting the IPFS-Sats infrastructure, servers, or any certificate authority. Instead, verification is a series of mathematically provable checks against universally verifiable cryptographic primitives.

| Layer | Proof Element | Verification Check |
| :--- | :--- | :--- |
| **1. Content Integrity** | Content Hash ($\text{CID}$) | $\text{Hash}(\text{Content}) = \text{Content CID}$ (Proves the file hasn't been altered). |
| **2. Temporal Proof** | Bitcoin OP_RETURN | $\text{Block Height}$ exists and contains $\text{AnchorHash}$ (Proves **when** the content existed). |
| **3. Creator Identity** | $\text{DID}$ Signature | $\text{Signature}$ verifies against the Creator's $\text{Public Key}$ (Proves **who** created it). |
| **4. Provenance Chain** | $\text{Parent CID}$ | Links to a **prior** $\text{Metadata CID}$ (Proves the history and derivative relationship). |
| **5. Economic Validity** | $\text{Wallet Address}$ | $\text{Lightning Wallet}$ responds and $\text{DAO}$ governance is auditable (Proves economic functionality). |


---

### Anti-Plagiarism and Attribution

The combination of the **Content Hash** (Layer 1) and the **Temporal Proof** (Layer 2) makes plagiarism detectable and financially non-viable.

#### **Theft Scenario and Detection**

If **Alice** uploads content at **Bitcoin Block 875432** and **Bob** attempts to steal the exact file and claim it as his own at a later time (e.g., **Block 876890**):

1.  **Content Immutability:** Both Alice's and Bob's metadata will point to the **same Content CID** ($\text{QmSong...}$), confirming the files are identical.
2.  **Temporal Conflict:** A simple query for the content's metadata will return two records. The **earlier Bitcoin Block Height (Alice's 875432)** automatically proves Alice's priority of creation.

**Bob's theft attempt fails because:**
* He cannot forge an earlier OP_RETURN timestamp on the immutable Bitcoin blockchain.
* He cannot forge Alice's signature (Layer 3).
* Users' payment systems are directed to pay the wallet associated with the **earlier timestamp** (Alice's wallet), negating Bob's economic incentive.

#### **Success of Legitimate Forks**

Conversely, the same architecture ensures legitimate derivatives succeed:

* The creator explicitly includes **`parent_cid` attribution** (Layer 4).
* The system is designed for **automated royalty payments** to the parent wallet, financially recognizing the original creator.
* The derivative is clearly defined by the **`derivative_type`** (Section 3.2.5), which provides legal context for fair use or transformative work.

---

## The Metadata Bundle as Universal Product Passport

The IPFS-Sats metadata bundle functions as a comprehensive **Digital Product Passport** that defines the complete state and rights of the content.

It enables the **Right to Verify** (via cryptographic timestamps) and the **Right to Fork** (via automated royalty sharing) while remaining entirely decentralized.

| Component | Function | Proof |
| :--- | :--- | :--- |
| **CID** | Content Identification | Cryptographic Proof of **What** |
| **Bitcoin Anchor** | Temporal Proof | Cryptographic Proof of **When** |
| **DID Signature** | Identity Proof | Cryptographic Proof of **Who** |
| **Lightning Wallet** | Economic Infrastructure | Infrastructure for **Monetization** |
| **DAO/License** | Governance and Rights | Structure for **Ownership & Usage** |
| **Parent CID** | Provenance Chain | Record for **Derivative Works** |

This is not merely storage—it is foundational infrastructure for digital rights. The metadata bundle enables the **Right to Verify** (cryptographic timestamps) and the **Right to Fork** (automated royalties) while remaining compatible with the open, decentralized ethos of IPFS.

## Anti-Plagiarism Through Metadata

The metadata bundle's design naturally prevents content theft.

### Theft Scenario and Automatic Detection

| Element | Alice (Original) | Bob (Theft Attempt) | Comparison Result |
| :--- | :--- | :--- | :--- |
| **Content CID** | QmSong... | QmSong... | **Match** (Files are identical) |
| **Metadata CID** | QmAliceMetadata... | QmBobMetadata... | **Mismatch** |
| **Bitcoin Block** | 875432 | 876890 | **Alice's is Earlier** |
| **Wallet** | lnbc_alice... | lnbc_bob... | **Payment directed to Alice** |

**Detection is Automatic:**
1. **Query:** "Show metadata for content QmSong..."
2. **Results:** Two metadata objects found.
3. **Compare:** Alice's Block 875432 < Bob's Block 876890. **Alice is proven as the original creator.**

**Bob's theft fails because:**
* He cannot forge an earlier Bitcoin block (impossible).
* He cannot forge Alice's signature (no private key).
* Users will pay Alice's wallet (due to the earlier timestamp).
* Bob faces legal liability (his own metadata proves he came later).

**Legitimate forks succeed because:**
* Explicit `parent_cid` attribution.
* Automated royalty payments to Alice.
* Clear derivative relationship.
* Legal protection (fair use, transformative work).

---

