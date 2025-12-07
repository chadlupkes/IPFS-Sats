## 10.4 Fork Relationships: Provenance and Automated Royalties 🌳

**Fork Relationships** are the architectural implementation of the Right to Fork, ensuring that every derivative work ($\text{Child}$) maintains an immutable link back to its original source ($\text{Parent}$). This mechanism establishes a clear line of attribution and automatically enforces licensing terms and royalty payments across the entire lineage.

### 📜 $\text{JSON}$ Schema Additions (Within Core Content Object)

The following `fork\_provenance` fields are mandatory additions to the Core Content Object (Section 10.1) if the `is\_fork` flag in the primary `provenance` section is set to `true`.

```json
{
  // ... other Core Content Object fields ...

  "fork_provenance": {
    // 1. Parent Linking
    "parent_cid": "bafy... (CID of the direct parent asset)",
    "derivative_type": "remix", // e.g., 'translation', 'adaptation', 'minor-update'

    // 2. Royalty Calculations
    "royalty_split": {
      "upstream_percentage": 0.10, // Percentage of revenue routed to the parent asset's wallet
      "creator_percentage": 0.90,  // Percentage allocated to the derivative creator's wallet
      "royalty_fee_cid": "QmContractLogic..." // CID of the contract logic handling the split
    },

    // 3. Attribution Chain (Optimization)
    "attribution_chain_cid": "bafy... (CID of the immutable list of all ancestors)"
  }
}
```

### 1\. Parent Linking (Immediate Predecessor)

Parent linking cryptographically seals the derivative work to its immediate source, forming the next step in the immutable chain of creation.

  * **`parent_cid`**: Contains the Core Content Object $\text{CID}$ of the asset this current work was **directly derived from**. This is the single most important piece of data for verifying the immediate lineage.
  * **`derivative_type`**: A descriptive tag that clarifies the nature of the derivative (e.g., `'remix'`, `'translation'`). This field assists in search indexing and application-level display.

### 2\. Royalty Calculations (Economic Enforcement)

The $\text{IPFS-Sats}$ protocol enforces economic terms at the protocol level for derivative works, ensuring original creators benefit perpetually from the reuse of their work.

  * **`upstream_percentage`**: The mandatory percentage of all revenue (e.g., from Zaps or access fees) that must be routed back to the wallet_address specified in the $\text{Parent CID}$'s Core Content Object.
  * **`creator_percentage`**: The remainder of the revenue allocated to the creator of the derivative work.
  * **`royalty_fee_cid`**: A $\text{CID}$ pointing to the **immutable smart contract logic** that executes the royalty split. This guarantees transparent, verifiable, and non-custodial disbursement of funds.

### 3\. Attribution Chain (Full Lineage)

While the `parent\_cid` links to the immediate predecessor, the **Attribution Chain** allows for the verification of the entire lineage back to the genesis object.

  * **`attribution_chain_cid`**: This $\text{CID}$ links to a separate, smaller **$\text{IPLD}$ structure** that is an immutable, ordered list of all ancestor $\text{CIDs}$.

This structure is a crucial **optimization**: instead of listing potentially hundreds of ancestor $\text{CIDs}$ within the primary Core Content Object (which would increase its size and anchoring cost), only a single link is stored. The full chain is verified by recursively resolving the $\text{CIDs}$ in the linked list.

Any node can resolve this chain to display the full, unalterable history of contributions, fulfilling the moral rights aspect of attribution.
