## 10.2 Application Transaction Proof Object ($\text{ATP}$) ⛓️ (Revised)

The **Application Transaction Proof Object ($\text{ATP}$)** is an application-layer data structure that establishes a chronological, cryptographically linked chain of events unique to a specific installation or user instance. This chain acts as a secondary, highly granular **Timestamp Proof** for the Core Content Object, leveraging the time-sequencing and commitment details provided by Lightning Network Layer-2 transactions.

**Crucial Distinction:** The $\text{ATP}$ is created at the time an application event is *initiated*. It includes the necessary cryptographic **commitments** (like the payment hash/$\text{HTLC}$ lock) that prove the event's sequence and will later be used to anchor the event on the Layer-2 network, thereby securing the timestamp. The $\text{ATP}$ does *not* require the final settlement $\text{preimage}$ or $\text{Layer-1}$ Bitcoin $\text{TXID}$ upon creation.

The immutability of the **Core Content Object ($\text{asset\_cid}$)** is preserved, as the $\text{ATP}$ object is created *after* the Core Content Object is sealed.

### $\text{JSON}$ Schema: Application Transaction Proof Object ($\text{ATP}$)

This structure is sealed (hashed) and its $\text{CID}$ is used to form the `preceding\_tx\_proof\_cid` of the next $\text{ATP}$ in the chain, creating an unalterable history.

```json
{
  // 1. ASSET LINK (Reference to Immutable Content)
  "asset_cid": "bafy... (CID of the Core Content Object)", // The immutable content being verified

  // 2. APPLICATION CHAINING CONTEXT (Establishing the Local Chain)
  "application_instance_id": "UUID-of-this-install-node", // Unique identifier for the local chain instance
  "preceding_tx_proof_cid": "bafy... (CID of the previous ATP in this chain)", // Links to the immediate predecessor (null for the first link)

  // 3. LIGHTNING TRANSACTION COMMITMENT PROOF (The Time Anchor)
  "lightning_tx_commitment": {
    "payment_hash": "sha256:...",         // The HTLC hash (R-hash) locking the payment commitment
    "timestamp": 1735094400,             // Unix time of the L2 commitment event execution
    "event_type": "app_state_commitment", // e.g., 'data_backup_commit', 'private_access_log'
    "commitment_proof": "0xProof..."      // Cryptographic data proving the commitment was made at this time
  },

  // 4. METADATA (Optional Application Context)
  "app_metadata": {
    "app_version": "1.2.0",
    "user_defined_tag": "daily_backup_commit"
  }
}
```

### Required Fields for $\text{ATP}$ Validity

For an $\text{ATP}$ to be valid and successfully chain to its predecessor, the following fields must be present:

  * **`asset_cid`:** The immutable link to the **Core Content Object** that this application chain is verifying.
  * **`application_instance_id`:** A unique $\text{UUID}$ or hash to scope the chain to a specific application installation or user node.
  * **`preceding_tx_proof_cid`:** The $\text{CID}$ of the $\text{ATP}$ object that immediately precedes this one in the chain, ensuring cryptographic sequence integrity.
  * **`lightning_tx_commitment`:** The full proof set from the Layer 2 transaction commitment, necessary for cryptographic verification of the event's sequence and time against the Lightning Network's ledger **commitment layer**.
