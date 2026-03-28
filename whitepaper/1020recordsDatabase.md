# 10.2 The Records Database Specification

The Records Database is the distributed, permissionless data layer that underlies the Host Discovery Layer (Section 3.5). It stores three tables of structured records — Host Registry Records, Anchor Records, and Content Flag Records — and makes them queryable by any participant without requiring a central coordinator.

This specification defines what a conforming Records Database node must do. It does not specify internal storage engines, gossip protocol implementations, or network topology beyond the minimum required for interoperability. A developer familiar with Nostr relay architecture, IPFS content routing, or BitTorrent DHT will recognize the pattern immediately. The Records Database is the same class of system applied to the specific schemas and query patterns of IPFS-Sats.

---

## 10.2.1 Design Principles

**Permissionless writes.** Any participant can publish a conforming record. Schema compliance is the only gatekeeping mechanism. A node must reject records that fail schema validation and must accept records that pass it.

**Append-optimized.** Anchor Records and Content Flag Records are append-only — once written, they are never modified or deleted. Host Registry Records are the only mutable table: a host updates its record by publishing a new version with a higher timestamp, and the network converges on the freshest version.

**Eventual consistency.** The database does not require global consensus. A record published to one node will propagate to connected peers through replication. Queries against nodes that have not yet received a recent update may return slightly stale results. This is acceptable — a stale Host Registry Record results in a failed AtomicSats attempt and a retry, not a lost payment.

**No trust required.** The database does not validate the truth of the claims stored within it. It validates schema conformance only. Truth is validated elsewhere: host inventory claims at the AtomicSats exchange layer, Anchor Record claims against the Bitcoin blockchain, Content Flag claims through the confirmation process. The Records Database is a claims index, not an audit system.

**Fully transparent and publicly queryable.** All three tables are open to any participant without permission or authentication. This transparency is the foundation for an ecosystem of application-layer query engines built on top of the protocol — content discovery tools, rights management dashboards, provenance explorers, royalty auditing tools, host reputation services, and network analytics. The protocol stores and serves; applications observe, query, and act. No special access is required and no gatekeeper controls what can be built.

**Economic incentive for participation.** Nodes that participate in the Records Database earn AtomicSats revenue by being discoverable to requesting clients. The incentive to maintain accurate, current records is the same incentive that drives all host behavior: correct participation earns sats, incorrect or stale participation earns less.

---

## 10.2.2 Node Participation Model

A Records Database node is any process that:

1. Maintains a local copy of some or all records across the three tables
2. Responds to the query interface defined in Section 10.2.4
3. Accepts conforming record publications and replicates them to connected peers
4. Rejects records that fail schema validation

### Participation Tiers

**Full nodes** store all records across all three tables for all CIDs they are aware of. Full nodes provide the highest query reliability and earn the strongest reputation signal in the Host Discovery Layer.

**Partial nodes** store records selectively — for example, only Host Registry Records for CIDs they currently serve, or only Anchor Records for content they have anchored. Partial nodes are valid participants. A AtomicSats node that only publishes and maintains its own Host Registry Record is a conforming partial node.

**Query-only clients** query the database without maintaining records or participating in replication. Query-only clients are not nodes in the network sense — they are consumers of the interface. No publication or replication behavior is required of them.

### Minimum Viable Node

The minimum viable Records Database node:

- Publishes and maintains its own Host Registry Record (if it is a AtomicSats host)
- Responds to `query(cid)` requests for CIDs it serves
- Replicates records it receives to at least two connected peers
- Rejects schema-invalid records without propagating them

---

## 10.2.3 Bootstrap and Peer Discovery

A new node joining the network must find its first peers before it can participate in replication. This is the standard bootstrap problem that IPFS, BitTorrent, and Nostr all solve through the same mechanism: a seed list of known-stable nodes provided with the client software, combined with peer exchange once initial connections are established.

### Bootstrap Sequence

1. **Seed connection.** The node connects to one or more bootstrap peers from a hardcoded or configurable seed list. Bootstrap peers are well-known, stable nodes maintained by early network participants — analogous to IPFS bootstrap nodes or BitTorrent trackers. The protocol does not specify who runs bootstrap nodes; the reference implementation will include a default seed list.

2. **Peer exchange.** Connected peers share their own peer lists. The node expands its connections through this exchange until it has a sufficient number of active peers for reliable replication.

3. **Initial sync.** The node requests recent records from connected peers to populate its local database. Full sync of the entire database is not required — a node may choose to sync only the record types and CID ranges relevant to its participation tier.

4. **Active participation.** Once connected and minimally synced, the node begins responding to queries and accepting publications from peers.

### Peer Discovery via DHT

For networks of sufficient size, a Kademlia-style distributed hash table provides peer discovery without relying on a fixed seed list. Nodes register themselves in the DHT keyed by their node ID. New nodes locate peers by querying the DHT for nodes near their own ID. This is identical to the libp2p Kademlia DHT used for IPFS content routing and is the recommended peer discovery mechanism for production deployments.

The reference implementation should support both seed-list bootstrap (for early network) and DHT-based discovery (for mature network). A node should attempt DHT discovery first and fall back to seed list if the DHT returns insufficient results.

---

## 10.2.4 Wire Protocol

The Records Database exposes a minimal message-passing interface. Messages are JSON objects transmitted over any reliable transport (WebSocket, TCP, libp2p streams). The following message types are required for a conforming implementation.

### Publication Messages

**PUBLISH_HOST_RECORD**
```json
{
  "type": "PUBLISH_HOST_RECORD",
  "record": { /* Host Registry Record — schema at Section 10.7 */ },
  "signature": "ed25519:..."  // Signed by the host's node key
}
```

**PUBLISH_ANCHOR_RECORD**
```json
{
  "type": "PUBLISH_ANCHOR_RECORD",
  "record": { /* Anchor Record — schema at Section 10.8 */ },
  "signature": "ed25519:..."  // Signed by the publishing LYW node's key
}
```

**PUBLISH_FLAG_RECORD**
```json
{
  "type": "PUBLISH_FLAG_RECORD",
  "record": { /* Content Flag Record — schema at Section 10.9 */ },
  "signature": "ed25519:..."  // Signed by the submitting participant's DID key
}
```

### Query Messages

**QUERY_HOSTS**
```json
{
  "type": "QUERY_HOSTS",
  "content_cid": "<content-cid>",
  "filters": {              // Optional
    "max_price_msats": 1000,
    "min_uptime_score": 0.95,
    "region": "us-west"
  }
}
```
Response:
```json
{
  "type": "QUERY_HOSTS_RESPONSE",
  "content_cid": "<content-cid>",
  "hosts": [
    { /* Host Registry Record fields */ },
    { /* Host Registry Record fields */ }
  ]
}
```

**QUERY_ANCHOR**
```json
{
  "type": "QUERY_ANCHOR",
  "metadata_bundle_cid": "<metadata-bundle-cid>"
}
```
Response:
```json
{
  "type": "QUERY_ANCHOR_RESPONSE",
  "metadata_bundle_cid": "<metadata-bundle-cid>",
  "anchor": { /* Anchor Record fields — null if not found */ }
}
```

**QUERY_FLAGS**
```json
{
  "type": "QUERY_FLAGS",
  "content_cid": "<content-cid>",
  "filters": {              // Optional
    "min_severity": "medium",
    "confirmed_only": true
  }
}
```
Response:
```json
{
  "type": "QUERY_FLAGS_RESPONSE",
  "content_cid": "<content-cid>",
  "flags": [
    { /* Content Flag Record fields */ }
  ]
}
```

### Replication Messages

**REPLICATE**
```json
{
  "type": "REPLICATE",
  "records": [
    { "table": "host_registry", "record": { /* ... */ } },
    { "table": "anchor",        "record": { /* ... */ } },
    { "table": "content_flag",  "record": { /* ... */ } }
  ]
}
```
Used by nodes to push records to peers during initial sync and ongoing gossip replication.

**PEER_EXCHANGE**
```json
{
  "type": "PEER_EXCHANGE",
  "peers": [
    { "node_id": "...", "endpoint": "ws://..." },
    { "node_id": "...", "endpoint": "ws://..." }
  ]
}
```

---

## 10.2.5 Replication Model

The Records Database uses a **gossip replication** model. When a node receives a valid record publication, it stores the record locally and forwards it to a subset of connected peers. Those peers forward to their peers. Within a small number of hops, the record reaches all nodes in the network.

This is the same model used by Nostr relays for event propagation. It is simple, robust, and does not require coordination between nodes.

### Replication Rules

**Host Registry Records:** When a node receives a Host Registry Record for a given node ID, it compares the `updated_at` timestamp against any existing record for that node ID. If the incoming record is newer, it replaces the existing record and is forwarded to peers. If it is older or identical, it is discarded without forwarding. This ensures the network converges on the freshest version of each host's record.

**Anchor Records:** Anchor Records are append-only. A node stores every valid Anchor Record it receives and forwards it to peers. There are no conflicts — each Anchor Record is uniquely identified by its `metadata_bundle_cid` and `tx_id`. Duplicate records received from multiple peers are deduplicated by this composite key and stored once.

**Content Flag Records:** Content Flag Records are append-only. A node stores every valid flag it receives and forwards it to peers. Flags accumulate — multiple flags against the same Content CID from different submitters are stored as separate records. Confirmation status is updated when confirmation messages arrive, referencing the original flag by its record CID.

### Replication Fan-Out

A node should forward each received record to a minimum of 3 and a maximum of 8 connected peers, selected randomly from its peer list. This fan-out range is a recommendation, not a requirement — implementations may tune it based on network conditions. The goal is to ensure rapid propagation without flooding the network.

---

## 10.2.6 Schema Validation and Rejection

A node must validate every incoming record against the schema for its table before storing or replicating it. Records that fail validation must be rejected and must not be forwarded to peers.

Minimum validation requirements:

- All required fields are present
- Field types match the schema (string, integer, boolean, etc.)
- CID fields are well-formed content-addressed hashes
- Signatures are valid against the claimed signing key
- `updated_at` timestamps are not in the future beyond a reasonable clock skew tolerance (recommended: 10 minutes)

A node should log rejected records with the reason for rejection. Peers that repeatedly send invalid records may be deprioritized or disconnected at the implementation's discretion.

Schema definitions for each table are in Sections 10.7 (Host Registry Records), 10.8 (Anchor Records), and 10.9 (Content Flag Records).

---

## 10.2.7 Conflict Resolution Summary

| Table | Conflict Type | Resolution |
|---|---|---|
| **Host Registry Records** | Two records for the same node ID | Freshest `updated_at` timestamp wins; older record discarded |
| **Anchor Records** | Two records with same `metadata_bundle_cid` and `tx_id` | Deduplicate — identical records stored once |
| **Anchor Records** | Two records with same `metadata_bundle_cid`, different `tx_id` | Both stored — multiple anchors for the same bundle are valid |
| **Content Flag Records** | Two flag records from different submitters for the same CID | Both stored — flags accumulate |
| **Content Flag Records** | Duplicate flag from the same submitter for the same CID | Deduplicate — identical records stored once |

---

## 10.2.8 Relationship to Existing Implementations

A developer implementing the Records Database does not need to build this infrastructure from scratch. The following existing systems provide reference implementations for each major component:

| Component | Reference Implementation | Notes |
|---|---|---|
| **Gossip replication and schema-validated records** | Nostr relay (NIPs 01, 11) | Direct analogy — replace Nostr event kinds with IPFS-Sats table schemas |
| **Peer discovery via DHT** | libp2p Kademlia (used by IPFS) | Production-grade Go and Rust implementations available |
| **Append-optimized distributed database** | OrbitDB (built on IPFS and libp2p) | Directly supports append-log and key-value store patterns matching all three tables |
| **Bootstrap and seed list mechanism** | BitTorrent DHT (BEP 5) | Well-documented; the IPFS bootstrap mechanism is a direct adaptation |

A minimal production implementation could be built by running an OrbitDB instance with three databases — one per table — connected to the libp2p network used by the SatSwap nodes, with a Nostr-style relay interface exposing the query and publication endpoints. This is not the only valid approach, but it demonstrates that all required components exist as mature, open-source software today.
