# 3.5 Host Discovery Layer

## The Problem This Layer Solves

SatSwap defines how a client pays a host for a block of data. It does not define how the client finds the host in the first place.

That gap is not a detail — it is a foundational requirement. Without a reliable answer to the question *"which hosts currently hold the blocks for CID X?"*, the exchange protocol has no starting point. A client cannot issue a WANT message to a host it cannot locate.

The Host Discovery Layer is the system that answers that question.

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

At minimum, a conforming discovery layer must answer one query reliably:

> *"Given CID X, return a list of hosts currently serving that content, their Lightning endpoints, and their stated price per block."*

Everything else — reputation scoring, geographic filtering, uptime history, price comparison — is optimization built on top of that primitive query.

A host participates in the discovery layer by publishing a **Host Registry Record** (defined in Section 10.6) that declares:

- Which CIDs the host currently holds
- The host's Lightning Network endpoint for receiving payment
- The host's price per block in millisatoshis
- Uptime and performance metrics (self-reported, reputation-weighted)

These records are written to the discovery database when a host begins serving content and updated or removed as the host's inventory changes.

---

## 3.5.3 Decentralized Database as the Implementation Class

The discovery layer requires a database with specific properties that centralized systems cannot provide without reintroducing trust dependencies:

**No single point of failure.** A discovery database controlled by one operator creates a chokepoint. That operator can censor hosts, manipulate rankings, or disappear entirely. The discovery layer must survive the failure of any individual participant.

**No permission to write.** Any host meeting the protocol's schema requirements must be able to publish a Host Registry Record without approval from a gatekeeper. Permissioned writes recreate the platform problem the protocol is designed to escape.

**Content-addressed storage.** Records in the discovery database should themselves be addressable by hash, making tampering detectable. A record that claims a host holds CID X should be verifiable against the record's own hash.

**Eventual consistency is acceptable.** Discovery does not require global consensus in the way financial settlement does. A slightly stale record that resolves to a host who no longer holds a block results in a failed WANT message and a retry — not a lost payment. The exchange layer is atomic; discovery merely needs to be *good enough, fast enough*.

These properties describe a class of technology — decentralized, append-optimized, peer-replicated databases — that has been under active development since Protocol Labs first explored the IPDB concept alongside IPFS. Current implementations in this class include OrbitDB, Ceramic, and similar systems. The IPFS-Sats protocol does not mandate any specific implementation. What it mandates is conformance to the Host Registry Record schema (Section 10.6) and participation in the query interface. Which database engine underlies that conformance is a decision left to the implementer.

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

The interface the discovery layer must expose is simple:

```
query(cid)                        → [{ node_id, lightning_endpoint, price_per_block, uptime_score }]
publish(host_registry_record)     → confirmation
remove(node_id, cid)              → confirmation
```

Any system that correctly implements these three operations, stores records in the Host Registry Record schema, and participates in a peer-replication network qualifies as a conforming discovery layer. A small network might run a single implementation. A mature network might have several competing discovery databases, each optimized for different trade-offs — one prioritizing low query latency, another prioritizing maximum host diversity, another specializing in archival or rarely-accessed content.

Clients can be configured to query multiple discovery databases and merge results. The SatSwap exchange layer does not care which discovery layer surfaced a host candidate — it only cares whether the host delivers the block and receives payment.

---

## 3.5.6 Relationship to Content Addressing

The discovery layer does not validate content. It does not verify that a host actually holds a block — it only records that the host *claims* to hold it. Validation happens at the exchange layer, through the atomic SatSwap handshake: the client pays only upon receiving a valid block, and an invalid or missing block results in a failed payment.

This division of responsibility keeps the discovery layer lightweight. It is a claims database, not an audit system. The exchange protocol provides the audit.

What the discovery layer does provide is the index that makes the exchange protocol reachable. Without it, the SatSwap network has no way for demand to find supply. With it, any client holding a CID can find, in milliseconds, a ranked list of hosts willing to serve that content for sats.

---

## Summary

The Host Discovery Layer is the market-making infrastructure of the SatSwap network. It is a decentralized, permissionless database that maps CIDs to willing hosts, providing the starting point for every exchange. It sits above the exchange protocol and below the application layer, separate from both, pluggable by design. Query patterns logged by the discovery layer feed directly into the cache optimization economics described in the following section. The protocol specifies the schema and the interface. The implementation is left to the developer community.
