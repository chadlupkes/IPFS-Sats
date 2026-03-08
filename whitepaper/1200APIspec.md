# 12. API Specifications 🌐

The following endpoints represent a minimal reference API for the IPFS-Sats protocol. They demonstrate the interface surface across the protocol's five functional categories — content operations, Records Database queries, governance, fork management, and LYW status — and are intended to give developers enough structure to build conforming implementations and application-layer tools.

This is a reference specification, not a frozen production contract. Implementations may extend these endpoints and add application-specific functionality within the bounds of the protocol architecture. A comprehensive API specification will be developed collaboratively with early implementers and maintained in the project repository at github.com/chadlupkes/IPFS-Sats.

All endpoints accept and return JSON. Value amounts are denominated in millisatoshis (msats) unless otherwise noted. Requests that modify state require a cryptographic signature from the relevant DID key.

---

## 12.1 Content Operations

These endpoints handle the core content lifecycle: publishing, retrieval, anchoring, and verification.

| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/content/publish` | POST | Publishes a new Metadata Wrapper to the network. Returns the Content CID and Bundle Hash. Does not anchor to Bitcoin — anchoring is a separate operation triggered after the Metadata Wrapper is published. |
| `/api/v1/content/anchor` | POST | Initiates the Bitcoin anchoring process for a Bundle Hash via OP_RETURN on a Lightning channel operation. Returns the resulting Anchor Record CID once the channel transaction is confirmed. See Section 3.2 for the full six-step anchoring sequence. |
| `/api/v1/content/{cid}` | GET | Retrieves the Metadata Wrapper for the specified Content CID, including current governance state and fork provenance fields. |
| `/api/v1/content/verify` | POST | Verifies a piece of content against its two independent proofs: (1) Bitcoin timestamp proof — confirms the Bundle Hash appears in the Anchor Records table and matches an OP_RETURN in the referenced Bitcoin block; (2) Lightning availability proof — confirms the content is currently retrievable via a SatSwap exchange. Returns the result of both proofs independently. See Section 7. |

---

## 12.2 Records Database Queries

These endpoints expose the three Records Database tables (Section 10.2) to application-layer query engines. All three tables are fully public and require no authentication to read.

| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/records/hosts/{block_cid}` | GET | Queries the Host Registry Records table for hosts currently serving the specified block-level CID. Accepts optional filter parameters: `max_msats`, `min_uptime_score`. Returns an array of matching Host Registry Records. |
| `/api/v1/records/anchor/{bundle_hash}` | GET | Queries the Anchor Records table for the Anchor Record associated with the specified Bundle Hash. Returns the Bitcoin block height, transaction ID, and OP_RETURN data confirming the timestamp proof. |
| `/api/v1/records/flags/{content_cid}` | GET | Queries the Content Flag Records table for all flags associated with the specified Content CID. Accepts optional filter parameters: `confirmed_only`, `min_severity`. Returns an array of matching Content Flag Records. |
| `/api/v1/records/search` | POST | Queries Anchor Records by Metadata Wrapper fields — creator DID, title, tags, license type, or any other indexed field. Returns matching Bundle Hashes and their associated Metadata Wrappers. This is the primary entry point for application-layer content discovery engines. |

---

## 12.3 Governance Operations

These endpoints interact with the Per-Content DAO governance layer, enabling proposal submission, voting, and state queries.

| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/dao/proposal` | POST | Submits a new governance proposal for a specified Content CID. Requires the submitting member's income share to meet the `proposal_threshold`. Request body includes the proposed action (from `allowed_actions`), proposed parameters, and submitter DID signature. |
| `/api/v1/dao/vote` | POST | Registers a DAO member's cryptographically signed vote (yes / no / abstain) on an active proposal. Vote weight is calculated from the member's current income share percentage per Section 10.3. |
| `/api/v1/dao/execute/{proposal_id}` | POST | Triggers Key 3 execution of a passed proposal after the `execution_delay_blocks` has elapsed. Verifies that quorum and passage thresholds were met before executing. |
| `/api/v1/dao/state/{content_cid}` | GET | Returns the current `mutable_state_cid` and its contents for the specified content's DAO — active income distribution, current license terms, and membership list. |

---

## 12.4 Fork Management

These endpoints support the Right to Fork — registering derivative works, querying royalty flows, and tracing provenance chains.

| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/fork/register` | POST | Registers a new derivative work by publishing a Metadata Wrapper with `is_fork: true` and populated `fork_provenance` fields, including the `parent_bundle_hash` and the Child's defined `upstream_percentage`. The Child sets its own royalty terms — the Parent cannot impose them. |
| `/api/v1/fork/royalties/{content_cid}` | GET | Returns the royalty flow record for the specified CID — inbound royalties received from Child DAOs and outbound royalties routed to Parent LYW addresses — as recorded in the LYW State Ledger. |
| `/api/v1/fork/provenance/{content_cid}` | GET | Traces the complete lineage of a content piece by resolving the Attribution Chain (Section 10.4). Returns the ordered list of ancestor Bundle Hashes from the immediate Parent back to the genesis work, with creator DID and royalty terms at each level. |

---

## 12.5 LYW Status and Lightning Operations

These endpoints expose the LYW's economic state and Lightning Network operational status for a given piece of content.

| Endpoint | Method | Description |
|---|---|---|
| `/api/v1/lyw/status/{content_cid}` | GET | Returns the current LYW State Ledger snapshot for the specified content — deployed balance, current cycle income, host payments, yield rate, drawdown mode status, and `cycles_at_threshold`. Signed by the service's DID key. See Section 10.5. |
| `/api/v1/lyw/did/{node_id}` | GET | Returns the Decentralized Identifier and associated service endpoint for the LYW operator managing the specified node. Public metadata, no authentication required. |
| `/api/v1/lyw/zap` | POST | Initiates a direct Lightning micropayment (zap) to a content creator's LYW address. Returns a BOLT11 invoice for the requested amount. Payment routes directly to the LYW; Key 3 records the inflow in the current cycle's `zap_income_sats` field. |

---

*For the full API specification including request and response schemas, error codes, authentication requirements, and implementation guidance, see the project repository at github.com/chadlupkes/IPFS-Sats.*
