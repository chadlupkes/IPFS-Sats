# 3.5 Host Discovery Layer

## The Problem This Layer Solves

SatSwap defines how a client pays a host for a block of data. It does not define how the client finds the host in the first place.

That gap is not a detail — it is a foundational requirement. Without a reliable answer to the question *"which hosts currently hold the blocks for CID X?"*, the exchange protocol has no starting point. A client cannot issue a WANT message to a host it cannot locate.

The Host Discovery Layer is the system that answers that question. It also serves two additional functions introduced in Sections 3.2 and 6.4: providing the distributed infrastructure for Anchor Records linking Metadata Bundle CIDs to their Bitcoin timestamp proofs, and storing Content Flag Records that application operators can query to implement content filtering and accountability systems. All three functions are served by the same underlying database — the **Records Database** — described in Section 3.5.3.

---

## 3.5.1 Architectural Position

The Host Discovery Layer sits at the application layer, above the SatSwap exchange protocol and below the user-facing application. It is not part of SatSwap itself. This separation is deliberate and load-bearing.

**SatSwap defines the exchange. Discovery defines the market.**

Keeping them separate means:

- Multiple discovery implementations can compete without modifying the exchange protocol
- A host can participate in any number of discovery networks simultaneously
- Discovery databases can be upgraded, replaced, or specialized without disrupting the payment layer
- The core SatSwap specification remains minimal and stable

The relationship between layers is strictly one-directional: the discovery layer surfaces host candidates; the exchange layer executes the trade. Discovery has no visibility into whether a SatSwap exchange succeeds or fails unless that outcome is explicitly reported back as a reputation signal.

---

## 3.5.2 What the Discovery Layer Must Do

The Host Discovery Layer serves three distinct functions, each corresponding to a table in the Records Database.

**Function 1: Host Routing**

Answer the primary query reliably:

> *"Given CID X, return a list of hosts currently serving that content, their Lightning endpoints, and their stated price per block."*

Everything else — reputation scoring, geographic filtering, uptime history, price comparison — is optimization built on top of that primitive query.

A host participates in the discovery layer by publishing a **Host Registry Record** (defined in Section 10.7) that declares:

- Which CIDs the host currently holds
- The host's Lightning Network endpoint for receiving payment
- The host's price per block in millisatoshis
- Uptime and performance metrics (self-reported, reputation-weighted)

These records are written to the Records Database when a host begins serving content and updated or removed as the host's inventory changes.

**Function 2: Anchor Record Lookup**

Answer the verification query:

> *"Given a Metadata Bundle CID, return the Bitcoin transaction that proves the Bundle Hash existed at a specific block height."*

A LYW node participates in this function by writing an **Anchor Record** (defined in Section 10.8) after a Lightning channel operation confirms on-chain. The Anchor Record links the Metadata Bundle CID and Bundle Hash to the `tx_id` and `block_height` of the confirming transaction, enabling any verifier to check the timestamp proof against the Bitcoin blockchain without scanning the full chain.

**Function 3: Content Flag Lookup**

Answer the accountability query:

> *"Given a Content CID, return any confirmed flag records associated with it, including category, severity, submitting identity, and confirmation status."*

Any participant — user, application, or designated validator — can submit a Content Flag Record against a Content CID. The flag enters the Records Database as pending and transitions to confirmed as additional participants independently verify it, or as application-designated validators provide confirmation weight. Content Flag Records are associated with the Content CID itself, not the Metadata Bundle, meaning they persist regardless of governance updates or distribution channel changes.

A full description of the Content Flag Record schema, flag categories, and the confirmation lifecycle is provided in Section 10.9. The protocol stores and serves this data. How applications act on it is an application layer decision.

All three functions are served by the same distributed database infrastructure. The economic incentive for nodes to maintain all three tables comes from the same source: participation in the discovery layer earns revenue through SatSwap exchanges, and that incentive covers the full database.

---

## 3.5.3 The Records Database

The distributed database underlying the Host Discovery Layer is the **Records Database** — a permissionless, application-layer database maintained collectively by participating nodes. It holds three tables:

**Table 1: Host Registry Records**
Maps CIDs to hosts willing to serve them, their Lightning endpoints, and their pricing. Populated by SatSwap nodes advertising their inventory. Full schema in Section 10.7.

**Table 2: Anchor Records**
Links Metadata Bundle CIDs to Bitcoin transactions containing their Bundle Hash in OP_RETURN. Populated by LYW nodes after channel confirmation. Full schema in Section 10.8.

**Table 3: Content Flag Records**
Associates Content CIDs with accountability signals: flag category, severity, submitting identity, confirmation status, and confirmation history. Populated by any participant identifying content that warrants a flag; confirmation status updated as the flag is verified or disputed. Full schema in Section 10.9.

The Records Database requires specific properties that centralized systems cannot provide without reintroducing trust dependencies:

**No single point of failure.** A database controlled by one operator creates a chokepoint. That operator can censor hosts, manipulate rankings, or disappear entirely. The Records Database must survive the failure of any individual participant.

**No permission to write.** Any host meeting the protocol's schema requirements must be able to publish a Host Registry Record without approval from a gatekeeper. Any LYW node must be able to write an Anchor Record after channel confirmation. Any participant must be able to submit a Content Flag Record. Permissioned writes recreate the platform problem the protocol is designed to escape.

**Content-addressed storage.** Records in the database should themselves be addressable by hash, making tampering detectable. A record that claims a host holds CID X should be verifiable against the record's own hash.

**Eventual consistency is acceptable.** No table requires global consensus in the way financial settlement does. A slightly stale Host Registry Record results in a failed WANT message and a retry — not a lost payment. An Anchor Record that arrives after channel confirmation rather than simultaneously is still correct when it arrives. A Content Flag Record that propagates with a short delay does not compromise the integrity of the flag itself. The exchange layer is atomic; the Records Database merely needs to be good enough, fast enough.

These properties describe a class of technology — decentralized, append-optimized, peer-replicated databases — that has been under active development since Protocol Labs first explored the IPDB concept alongside IPFS. Current implementations in this class include OrbitDB, Ceramic, and similar systems. The IPFS-Sats protocol does not mandate any specific implementation. What it mandates is conformance to the Host Registry Record schema (Section 10.7), the Anchor Record schema (Section 10.8), the Content Flag Record schema (Section 10.9), and participation in the query interface. Which database engine underlies that conformance is a decision left to the implementer.

---

## 3.5.4 Query Logging as a Protocol Signal

Searches against the discovery layer are not disposable events. Every query carries information:

- Which CIDs are being requested
- At what frequency
- From which geographic regions or network segments
- Whether the requesting client ultimately completed a SatSwap exchange

This query log, aggregated across the discovery network, is one of the most valuable signals in the system. It answers questions no individual host can answer alone:

- *Which content is experiencing rising demand?*
- *Which CIDs have many hosts but low query volume — potential oversupply?*
- *Which CIDs have high query volume but few hosts — a caching opportunity?*

When query logs are stored and made accessible (with appropriate privacy considerations), they become an input to the economic optimization described in Section 3.6. Hosts monitoring the discovery layer can identify high-demand CIDs and proactively cache them before demand peaks. The query log turns the discovery layer from a passive lookup table into an active market signal.

This is not a requirement for a minimal implementation. A discovery layer that simply answers "who holds CID X?" is fully functional. Query logging is the path from functional to optimal.

---

## 3.5.5 Pluggability and Implementation Diversity

The protocol's design philosophy applies here as directly as anywhere: define the interface, not the implementation.

The interface the discovery layer must expose is:

```
query(cid)                        → [{ node_id, lightning_endpoint, price_per_block, uptime_score }]
publish(host_registry_record)     → confirmation
remove(node_id, cid)              → confirmation
query_anchor(metadata_bundle_cid) → { bundle_hash, wallet_address, tx_id, block_height }
write_anchor(anchor_record)       → confirmation
query_flag(content_cid)           → [{ flag_category, severity, submitting_identity, confirmation_status }]
write_flag(content_flag_record)   → confirmation
```

Any system that correctly implements these operations, stores records in the defined schemas, and participates in a peer-replication network qualifies as a conforming discovery layer. A small network might run a single implementation. A mature network might have several competing discovery databases, each optimized for different trade-offs — one prioritizing low query latency, another prioritizing maximum host diversity, another specializing in archival or rarely-accessed content.

Clients can be configured to query multiple discovery databases and merge results. The SatSwap exchange layer does not care which discovery layer surfaced a host candidate — it only cares whether the host delivers the block and receives payment.

---

## 3.5.6 Division of Responsibility

The Records Database does not validate the claims stored within it. It does not verify that a host actually holds a block — it only records that the host claims to hold it. It does not verify that a Bitcoin transaction contains a given Bundle Hash — it only records that a LYW node claims it does. It does not verify that flagged content is genuinely harmful — it only records that a participant has submitted a flag and tracks the confirmation state.

Validation happens elsewhere by design:

- **Host inventory claims** are validated at the exchange layer through the atomic SatSwap handshake. The client pays only upon receiving a valid block; an invalid or missing block results in a failed payment.
- **Anchor Record claims** are validated by any verifier who chooses to check: retrieve the Metadata Wrapper, compute the Bundle Hash locally, retrieve the referenced Bitcoin transaction, and compare the OP_RETURN data directly against the computed hash.
- **Content Flag claims** are validated through the confirmation process: community participants independently verifying the flag, or application-designated validators providing confirmation weight according to the trust model their application defines. The protocol records confirmation state; it does not adjudicate it.

This division of responsibility keeps the Records Database lightweight. It is a claims database and a lookup index — not an audit system. The exchange protocol, the Bitcoin blockchain, and the application layer's confirmation processes provide the audits respectively. What the Records Database provides is the connective tissue that makes all three reachable.

---

## Summary

The Host Discovery Layer is the market-making and verification infrastructure of the IPFS-Sats network. Its core construct is the **Records Database** — a distributed, permissionless, application-layer database with three tables: Host Registry Records mapping CIDs to willing hosts; Anchor Records linking Metadata Bundle CIDs to their Bitcoin timestamp proofs; and Content Flag Records associating Content CIDs with accountability signals that application operators can query to implement content filtering systems. The layer sits above the exchange protocol and below the application layer, separate from both, pluggable by design. Query patterns logged by the discovery layer feed directly into the cache optimization economics described in Section 3.6. The protocol specifies the schemas and the interface. The implementation is left to the developer community.
