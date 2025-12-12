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
