# 10.4 Fork Relationships: Provenance and Automated Royalties 🌳

**Fork Relationships** are the architectural implementation of the Right to Fork (Section 8), ensuring that every derivative work (Child) maintains an immutable link back to its original source (Parent). This mechanism establishes a clear line of attribution and automatically enforces licensing terms and royalty payments across the entire lineage.

---

## JSON Schema: fork_provenance Fields

The following `fork_provenance` fields are mandatory additions to the Metadata Wrapper (Section 10.1) when the `is_fork` flag in the `provenance` section is set to `true`. They are ignored for original works.

```json
{
  // ... other Metadata Wrapper fields ...

  "fork_provenance": {

    // 1. PARENT LINKING (Immediate Predecessor)
    "parent_bundle_hash": "<bundle-hash>",  // Bundle Hash of the direct Parent Metadata Bundle
                                             // this work was derived from
    "derivative_type": "remix",             // Descriptive tag: e.g., "translation", "adaptation",
                                            // "minor_update", "remix", "sampling"

    // 2. ROYALTY CONFIGURATION (Economic Terms)
    "royalty_split": {
      "upstream_percentage": 0.10,          // Fraction of Child DAO revenue routed to the
                                            // Parent content's LYW address
      "child_dao_percentage": 0.90,         // Fraction retained by the Child DAO for distribution
                                            // among its own members according to Child governance
      "royalty_contract_cid": "<contract-cid>" // CID of the smart contract logic that executes
                                               // the royalty split when the Child DAO receives payment
    },

    // 3. ATTRIBUTION CHAIN (Full Lineage)
    "attribution_chain_cid": "<chain-cid>"  // CID of a content-addressed ordered list of all
                                            // ancestor Bundle Hashes back to the genesis work
  }
}
```

---

## 1. Parent Linking

Parent linking cryptographically seals the derivative work to its immediate source, forming the next link in the provenance chain.

- **`parent_bundle_hash`:** The Bundle Hash of the Metadata Bundle this work was directly derived from. Using the Bundle Hash — rather than a content CID alone — binds the fork relationship to a specific version of the Parent's governance rules at the time of derivation. This is consistent with the Bundle Hash's role throughout the protocol as the single value that commits both content and governance state together.
- **`derivative_type`:** A descriptive tag that clarifies the nature of the derivative work. This field assists discovery and application-level display but carries no governance weight — the economic terms are defined in the royalty split, not the derivative type label.

---

## 2. Royalty Configuration

The fork_provenance fields encode the economic terms of the derivative relationship. Enforcement of those terms lives at the Child DAO layer — when the Child DAO receives payment, its smart contract executes the royalty split automatically, routing the upstream percentage to the Parent's LYW before distributing the remainder among the Child DAO's own members.

- **`upstream_percentage`:** The fraction of all Child DAO revenue — from zaps, access fees, or downstream fork royalties — that is automatically routed to the LYW address specified in the Parent Metadata Bundle. This is the direct economic expression of the Right to Fork: the Parent creator receives perpetual, passive income from all successful derivative works without any action required after publication.
- **`child_dao_percentage`:** The fraction retained by the Child DAO. This remainder is distributed among the Child DAO's members according to the Child's own governance configuration — which may include a creator, initial depositors, hosts, and other participants in whatever proportions the Child DAO defines. The label "child DAO" rather than "creator" reflects that the Child's income distribution is its own internal governance concern, independent of the fork relationship.
- **`royalty_contract_cid`:** The CID of the smart contract logic that executes the royalty split. Because this is a content-addressed reference, anyone can retrieve and inspect the exact logic governing the distribution — the terms are verifiable, not merely claimed.

---

## 3. Attribution Chain

While `parent_bundle_hash` links to the immediate predecessor, the Attribution Chain provides access to the complete lineage back to the genesis work.

- **`attribution_chain_cid`:** A CID pointing to a content-addressed, ordered list of all ancestor Bundle Hashes from the immediate Parent back to the genesis work. The genesis work is identified by the record in the chain where `is_fork` is false — verifiers know they have reached the root when this condition is met.

The Attribution Chain is a deliberate optimization. Embedding the full ancestor list directly in the Metadata Wrapper would increase its size — and therefore the anchoring cost — proportionally with the depth of the lineage. Instead, only a single CID is stored in the Wrapper. The full chain is available to any participant who resolves it, but the cost of storing and anchoring the Wrapper remains flat regardless of how many generations deep the derivative work sits.

Any node can resolve this chain to display the complete, unalterable history of contributions across the entire lineage — fulfilling the attribution function of the Right to Fork at any depth.

---

## How fork_provenance Interacts with the Records Database

Fork provenance is stored in the Metadata Wrapper and anchored to Bitcoin through the normal Anchor Record process. The Records Database does not maintain a separate fork index — provenance is resolved by retrieving Metadata Wrappers through their Bundle Hashes and following the `parent_bundle_hash` chain.

Applications that need to display full lineage trees — a provenance explorer, a royalty dashboard, a content discovery interface — traverse this chain by querying Anchor Records for each Bundle Hash in the Attribution Chain and retrieving the corresponding Metadata Wrappers. This keeps the protocol layer minimal: the data is all there, and applications decide how to surface it.
