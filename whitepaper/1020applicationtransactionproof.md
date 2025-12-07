## 10.2 Application Transaction Proof Object ($\text{ATP}$) ⛓️

The **Application Transaction Proof Object ($\text{ATP}$)** is a critical application-layer data structure that establishes a chronological, cryptographically linked chain of events. Unique to a specific installation or user instance, this chain acts as a secondary, highly granular **Timestamp Proof** for the Core Content Object, leveraging the time-sequencing and finality provided by Lightning Network Layer-2 transactions.

The immutability of the **Core Content Object (asset_cid)** is preserved, as the $\text{ATP}$ object is created *after* the Core Content Object is sealed. This structure ensures that application-specific events—such as data backups, private access logs, or state changes—are permanently verifiable and ordered.

### $\text{JSON}$ Schema: Application Transaction Proof Object ($\text{ATP}$)

This structure is sealed (hashed) and its $\text{CID}$ is used to form the `preceding\_tx\_proof\_cid` of the next $\text{ATP}$ in the chain, creating an unalterable history.

```json
{
  // 1. ASSET LINK (Reference to Immutable Content)
  "asset_cid": "bafy... (CID of the Core Content Object)", // The immutable content being verified

  // 2. APPLICATION CHAINING CONTEXT (Establishing the Local Chain)
  "application_instance_id": "UUID-of-this-install-node", // Unique identifier for the local chain instance
  "preceding_tx_proof_cid": "bafy... (CID of the previous ATP in this chain)", // Links to the immediate predecessor (null for the first link)

  // 3. LIGHTNING TRANSACTION PROOF (The Time Anchor)
  "lightning_tx_details": {
    "tx_id": "sha256:...",           // Hash or identifier of the L2 (Lightning) transaction
    "timestamp": 1735094400,         // Unix time of the L2 event execution
    "event_type": "channel_open_commitment", // e.g., 'channel_open_commitment', 'settlement', 'HTLC_preimage_reveal'
    "proof_data": "0xProof..."       // Cryptographic data derived from the L2 event
  },

  // 4. METADATA (Optional Application Context)
  "app_metadata": {
    "app_version": "1.2.0",
    "user_defined_tag": "daily_backup_commit"
  }
}
```

### Required Fields for $\text{ATP}$ Validity

For an Application Transaction Proof Object to be valid and successfully chain to its predecessor, the following fields must be present:

  * **`asset_cid`:** The immutable link to the **Core Content Object** that this application chain is verifying.
  * **`application_instance_id`:** A unique $\text{UUID}$ or hash to scope the chain to a specific application installation or user node.
  * **`preceding_tx_proof_cid`:** The $\text{CID}$ of the $\text{ATP}$ object that immediately precedes this one in the chain, ensuring cryptographic sequence integrity.
  * **`lightning_tx_details`:** The full proof set from the Layer 2 transaction, necessary for cryptographic verification of the event's sequence and time against the Lightning Network's ledger.
