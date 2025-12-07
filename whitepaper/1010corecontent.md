# PART IV: PROTOCOL SPECIFICATIONS (Technical Details) ⚙️

# 10\. Data Structures

The functionality and reliability of the $\text{IPFS-Sats}$ protocol are secured by a set of distinct, cryptographically-linked data structures. These structures govern content persistence, monetization, and governance.

## 10.1 Core Content Object (Metadata Bundle)

The **Core Content Object**, often referred to as the **Metadata Bundle**, is the primary, mutable control object for a piece of content. Its $\text{CID}$ is the single value committed to the Bitcoin blockchain via the $\text{OP\_RETURN}$ field, serving as the immutable, timestamped anchor for the content's mutable rules.

**Key Change:** The mutable `anchor_details` are now externalized. The `provenance` section now exclusively tracks the internal $\text{Parent} \rightarrow \text{Child}$ lineage for the **Right to Fork**.

### $\text{JSON}$ Schema: Core Content Object

This schema defines the minimum required fields and optional descriptive elements.

```json
{
  // 1. CONTENT REFERENCE (Immutable Payload)
  "content_cid": "QmOriginalContent...",  // IPFS CID of the raw media/file payload

  // 2. PROVENANCE (Internal Fork Chain)
  "provenance": {
    "bundle_hash": "0xABCDEF...",       // Hash of the current JSON object (for self-verification)
    "parent_bundle_cid": null,          // CID of the object this one is derived from (null for originals)
    "is_fork": false                    // Boolean flag indicating derivative work
  },

  // 3. IPFS-SATS PROTOCOL DATA
  "ipfs_sats_metadata": {
    "version": "2.0",                   // Protocol version
    "wallet_address": "lnbc...",        // Primary Lightning Yield Wallet (LYW) address
    "dao_cid": "QmDAOconfig...",        // CID pointing to the immutable DAO configuration script
    "smart_contract_hash": "sha256:abc123..." // Hash of the governing key-3 smart contract
  },

  // 4. CREATOR IDENTITY & SIGNATURE (Proof of Authorship)
  "creator": {
    "did": "did:key:z6Mk...",           // Creator's Self-Sovereign Identity (DID)
    "signature": "ed25519:...",         // Creator's signature over the entire bundle hash
    "public_key": "base58:..."          // Creator's public key for signature verification
  },

  // 5. LICENSING & TERMS
  "license": {
    "type": "custom",                   // e.g., "CC0", "Standard Copyright", "Custom"
    "terms_cid": "QmLicenseTerms...",   // CID pointing to the full text of custom terms
    "derivative_royalty": 10            // Percentage (1-100) due to this Parent from all Child forks
  },

  // 6. DESCRIPTIVE METADATA (Optional for Discovery)
  "title": "My Creative Work",
  "description": "A groundbreaking innovation",
  "tags": ["music", "electronic", "2025"]
}
```

### Required Fields for Anchoring

The following fields must be present and correctly formatted for a Core Content Object to be considered valid and eligible for anchoring and persistence on the network:

  * **`content_cid`:** The immutable link ($\text{CID}$) to the raw content.
  * **`provenance`:** The internal linking information (`bundle_hash`, `is_fork`, `parent_bundle_cid`).
  * **`ipfs_sats_metadata`:** Protocol configuration (`version`, `wallet_address`, `dao_cid`).
  * **`creator`:** Identity and proof of ownership (`did`, `signature`, `public_key`).
