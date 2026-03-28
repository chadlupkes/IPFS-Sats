# 6.3 Metadata Bundle Updates and Propagation 📡

While the underlying content is fundamentally immutable — any change to the content itself generates a new Content CID — the rules governing that content are dynamic. The **Metadata Wrapper** is the governable layer: a structured document that defines the economic and commercial terms under which the content is accessed, distributed, and compensated. When a DAO vote passes and its execution delay expires, the result is a new Metadata Wrapper, not new content.

This distinction is load-bearing. The content never changes. What changes is the set of rules the network enforces around it — and those rules are always current, always verifiable, and always anchored to Bitcoin through the Anchor Record that records each governance update.

---

## The Metadata Wrapper as the Governable Layer

The Metadata Wrapper is the structured component of the Metadata Bundle that encodes all governable parameters for a piece of content. It is the part of the bundle that DAO votes can update. The Content CID it is paired with remains unchanged.

| Component | Description | Example |
|---|---|---|
| **Economic Terms** | Current yield distribution, access pricing in sats, and zap allocation split | `{"price_sats": 1500, "creator_share": 0.50, ...}` |
| **Rights Management** | Licensing status, remix permissions, fork approval status | `{"license": "CC-BY-NC-SA", "remix_permitted": true, ...}` |
| **Content Pointer** | The Content CID of the immutable content this wrapper governs | `{"content_cid": "<content-cid>"}` |
| **Version Chain** | A cryptographic link to the previous Metadata Wrapper, providing a complete and auditable governance history | `{"prev_bundle_hash": "<prior-bundle-hash>"}` |

The combination of the Content CID and the current Metadata Wrapper is the **Metadata Bundle**. The hash of that combination is the **Bundle Hash**. Every governance update produces a new Metadata Wrapper, a new Metadata Bundle, and a new Bundle Hash — each anchored to Bitcoin via the Anchor Record written to the Records Database (Section 3.5).

---

## The Governance Update Sequence

When a proposal passes the required threshold and the execution delay expires (as defined in Sections 6.1 and 6.2), Key 3 initiates the following update sequence:

1. **State Transition:** Key 3 commits the new parameters from the passed proposal to the DAO's governing smart contract, producing an updated Metadata Wrapper.
2. **Bundle Regeneration:** The new Metadata Wrapper is combined with the unchanged Content CID to form a new Metadata Bundle. The Bundle Hash is computed from this combination.
3. **Anchor Record Publication:** The new Bundle Hash is embedded in the next natural Lightning channel operation via OP_RETURN, establishing a Bitcoin timestamp. After channel confirmation, a new Anchor Record is written to the Records Database — the authoritative, network-wide source of truth for the current governance state of this content.

The Anchor Record is the single point of truth the entire network converges on. Any node querying the Host Discovery Layer for this content CID will receive the current Bundle Hash from the Records Database and can verify it against the Bitcoin timestamp independently.

---

## Propagation Through the Host Discovery Layer

Under 0.3, propagation relied on a separate event subscription service running on each host node. In 0.4, this function is handled natively by the Host Discovery Layer and the Records Database already defined in Section 3.5. No additional synchronization infrastructure is required.

Hosts are registered participants in the Host Discovery Layer. As part of normal operation, hosts query the Records Database to verify that their cached content matches the current Anchor Record for a given Content CID. When a governance update produces a new Anchor Record with a new Bundle Hash, that updated record becomes the authoritative state. The next query cycle returns the new Bundle Hash, and hosts update their local enforcement parameters accordingly.

The network converges on the new governance state through the same discovery infrastructure it uses for all content routing — not through a separate propagation mechanism layered on top.

---

## Enforcement Through AtomicSats

Enforcement of current governance terms does not require a separate compliance check. It is a natural consequence of how AtomicSats exchanges work.

Every AtomicSats negotiation is governed by the terms embedded in the current Metadata Wrapper, identified by the current Bundle Hash. A requesting node presents the current Bundle Hash — retrieved from the Records Database — and the exchange proceeds under the terms that hash represents. A host operating on stale governance terms will quote parameters that do not match the current Bundle Hash. The requesting node will not complete the exchange. Payment flows only through successful AtomicSats trades, and successful trades require matching current terms.

A host that fails to update after a governance change is not penalized through a separate enforcement action. It simply stops completing trades, stops earning, and drops in the Host Discovery Layer's performance ranking until it falls below the threshold for continued inclusion. The economic incentive to stay current is the same incentive that drives all host behavior: sats flow to hosts that serve correctly, and stop flowing to those that do not.

This is the correct enforcement model for a decentralized network — not a compliance check imposed from outside, but an economic gradient that makes correct behavior the path of least resistance.
