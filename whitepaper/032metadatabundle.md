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
