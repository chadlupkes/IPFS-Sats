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
