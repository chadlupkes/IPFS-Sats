# PART IV: PROTOCOL SPECIFICATIONS (Technical Details) ⚙️

# 10. Data Structures

The functionality and reliability of the IPFS-Sats protocol are secured by a set of distinct, cryptographically-linked data structures. These structures govern content persistence, monetization, and governance.

---

## 10.1 The Metadata Wrapper

The **Metadata Wrapper** is the structured metadata document that encodes the economic, governance, and provenance rules for a piece of content. It is one of two components of the **Metadata Bundle** — the other being the Content CID, which references the immutable content payload itself.

The relationship between these structures is precise and load-bearing:

- **Content CID** — a content-addressed hash of the raw content payload. Immutable by definition: any change to the content produces a new CID.
- **Metadata Wrapper** — the structured document defined in this section. Governable: a successful DAO vote produces a new Metadata Wrapper with updated terms.
- **Metadata Bundle** — the combination of the Content CID and the current Metadata Wrapper. Represents the full state of the content at a point in time.
- **Bundle Hash** — Hash(Content CID + Metadata Wrapper). This is the single value committed to the Bitcoin blockchain via OP_RETURN, binding the content reference and its current governance rules into a single cryptographic commitment. The Bundle Hash is what the Anchor Record records and what verifiers check against the Bitcoin timestamp.

The Metadata Wrapper is therefore the governable layer: the content never changes, but the rules governing it can evolve through DAO governance, with each governance update producing a new Bundle Hash anchored to Bitcoin.

---

### JSON Schema: Metadata Wrapper

This schema defines the minimum required fields and optional descriptive elements.

```json
{
  // 1. CONTENT REFERENCE (Immutable Payload)
  "content_cid": "<content-cid>",        // Content-addressed hash of the raw media or file payload

  // 2. PROVENANCE (Fork Chain and Self-Verification)
  "provenance": {
    "bundle_hash": "<bundle-hash>",      // Hash(Content CID + this Metadata Wrapper) — the value
                                         // committed to Bitcoin via OP_RETURN in the Anchor Record
    "parent_bundle_hash": null,          // Bundle Hash of the Metadata Bundle this one is derived
                                         // from — null for original works, required for forks
    "is_fork": false                     // Boolean flag indicating derivative work status
  },

  // 3. PROTOCOL METADATA
  "protocol_metadata": {
    "version": "0.4",                    // Protocol version
    "wallet_address": "lnbc...",         // Lightning Yield Wallet (LYW) address for this content
    "dao_cid": "<dao-config-cid>",       // CID pointing to the DAO configuration for this content
    "smart_contract_hash": "sha256:..."  // Hash of the governing Key 3 smart contract
  },

  // 4. CREATOR IDENTITY AND SIGNATURE (Proof of Authorship)
  "creator": {
    "did": "did:key:z6Mk...",            // Creator's Decentralized Identifier (DID)
    "signature": "ed25519:...",          // Creator's signature over the Bundle Hash
    "public_key": "base58:..."           // Creator's public key for signature verification
  },

  // 5. LICENSING AND TERMS
  "license": {
    "type": "custom",                    // e.g., "CC0", "CC-BY", "Standard Copyright", "Custom"
    "terms_cid": "<license-terms-cid>",  // CID pointing to the full text of the license terms
    "derivative_royalty": 10             // Percentage (0-100) of Child fork revenue routed to this
                                         // content's LYW under the Right to Fork (Section 8)
  },

  // 6. DESCRIPTIVE METADATA (Optional — for discovery and display)
  "title": "My Creative Work",
  "description": "A description of the content and its context",
  "tags": ["music", "electronic", "2026"]
}
```

---

### Required Fields for Anchoring

The following fields must be present and correctly formatted for a Metadata Wrapper to be considered valid and eligible for anchoring and persistence on the network:

- **`content_cid`:** The content-addressed reference to the raw content payload. Required to establish what is being governed.
- **`provenance`:** The Bundle Hash and fork chain fields (`bundle_hash`, `is_fork`, `parent_bundle_hash`). Required for Bitcoin timestamping and provenance verification.
- **`protocol_metadata`:** Protocol configuration fields (`version`, `wallet_address`, `dao_cid`). Required for LYW operation and DAO governance.
- **`creator`:** Identity and authorship fields (`did`, `signature`, `public_key`). Required for Proof of Authorship under the Right to Verify (Section 7).

Descriptive metadata fields (`title`, `description`, `tags`) are optional. Their absence does not prevent anchoring or persistence, but their presence improves discoverability through the Host Discovery Layer.

---

### How the Metadata Wrapper Relates to the Records Database

The Metadata Wrapper does not live in the Records Database directly. It is content-addressed and retrievable by its CID from the network. What the Records Database stores is the **Anchor Record** — which links the Bundle Hash to the Bitcoin transaction that proves it existed at a specific block height (Section 10.8). Verifiers query the Records Database for the Anchor Record, then retrieve the Metadata Wrapper by its CID, compute the Bundle Hash independently, and confirm it matches the OP_RETURN data in the referenced Bitcoin transaction.

This separation keeps the Records Database lightweight: it stores references and proofs, not the full content of every Metadata Wrapper version.
