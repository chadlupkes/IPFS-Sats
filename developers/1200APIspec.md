# IPFS-Sats Protocol Developer API Reference (v0.4)

This document is the detailed developer companion to Section 12 of the IPFS-Sats white paper. It expands each endpoint group with full request/response schemas, authentication requirements, error handling, and implementation notes.

All endpoints accept and return `application/json`. Value amounts are denominated in **millisatoshis (msats)** unless otherwise noted. The base path for all endpoints is `/api/v1`.

This is a reference specification, not a frozen production contract. Implementations may extend these endpoints and add application-specific functionality within the bounds of the protocol architecture. The canonical specification is maintained at `github.com/chadlupkes/IPFS-Sats`.

---

## Authentication

All `POST` requests that create or modify state require two authentication headers:

| Header | Purpose |
|---|---|
| `X-API-KEY` | Service identification and rate limiting |
| `X-SIG-AUTH` | ECDSA or ed25519 signature over the request payload, proving the request originated from the claimed DID |

`GET` requests to public data (Records Database queries, content retrieval, LYW status) do not require authentication. All Records Database tables are fully public.

---

## 12.1 Content Operations

These endpoints manage the content lifecycle: publishing, anchoring, retrieval, and verification. **Publishing and anchoring are separate operations.** The Metadata Bundle is published first. Bitcoin anchoring happens asynchronously — the Bundle Hash waits for the next natural Lightning channel operation on the creator's LYW.

### POST `/api/v1/content/publish`

Publishes a new Metadata Wrapper to the network. Computes the Bundle Hash from the Content CID and Metadata Wrapper. Returns the Content CID, Bundle Hash, and Metadata Bundle CID. Does not anchor to Bitcoin — anchoring is a separate step.

**Request body:**

```json
{
  "content_cid": "QmContent...",
  "metadata_wrapper": {
    "timestamp_proof": {
      "creation_time": 1735094400,
      "provenance_chain": {
        "parent_bundle_hash": null,
        "is_fork": false
      }
    },
    "protocol_metadata": {
      "version": "0.4",
      "wallet_address": "lnbc...",
      "dao_cid": "QmDAO...",
      "smart_contract_hash": "sha256:abc123..."
    },
    "creator": {
      "did": "did:key:z6Mk...",
      "public_key": "base58:...",
      "signature": "ed25519:..."
    },
    "license": {
      "type": "custom",
      "terms_cid": "QmLicense...",
      "commercial_use": true,
      "attribution_required": true
    },
    "title": "My Work",
    "description": "...",
    "tags": ["music", "electronic"],
    "media_type": "audio/mpeg",
    "language": "en"
  }
}
```

**Response `202 Accepted`:**

```json
{
  "content_cid": "QmContent...",
  "metadata_bundle_cid": "QmBundle...",
  "bundle_hash": "0xABCDEF...",
  "status": "published",
  "anchored": false,
  "message": "Metadata Bundle published. Bundle Hash ready for Bitcoin anchoring via /api/v1/content/anchor."
}
```

**Notes:**
- The `creator.signature` in the Metadata Wrapper must be a valid signature over the Bundle Hash
- `wallet_address` must be set before publishing — it is included in the Bundle Hash computation
- `anchored: false` is the correct initial state — content is live and queryable before anchoring

---

### POST `/api/v1/content/anchor`

Initiates the Bitcoin anchoring process for a Bundle Hash. Embeds the Bundle Hash in a Bitcoin transaction's OP_RETURN output, then publishes the resulting Anchor Record to the Records Database. Returns the Anchor Record CID once the channel transaction is confirmed.

**Request body:**

```json
{
  "metadata_bundle_cid": "QmBundle...",
  "bundle_hash": "0xABCDEF...",
  "lyw_address": "lnbc...",
  "funding_amount_sats": 1000000
}
```

**Response `202 Accepted`:**

```json
{
  "status": "anchoring",
  "bundle_hash": "0xABCDEF...",
  "message": "Bundle Hash queued for next Lightning channel operation. Anchor Record will be published to Records Database on confirmation."
}
```

**Response `200 OK` (on confirmation):**

```json
{
  "anchor_record_cid": "QmAnchor...",
  "bundle_hash": "0xABCDEF...",
  "tx_id": "a1b2c3...",
  "block_height": 875432,
  "status": "anchored"
}
```

**Notes:**
- Anchoring is asynchronous. The `202` response confirms the Bundle Hash is queued. Poll `/api/v1/records/anchor/{bundle_hash}` for confirmation status.
- The service batches OP_RETURN commitments with natural Lightning channel operations on the creator's LYW — this is the zero marginal cost mechanism. Creators requiring immediate finality may specify `immediate: true` to trigger a dedicated anchor transaction at their own cost.

---

### GET `/api/v1/content/{cid}`

Retrieves the Metadata Wrapper for the specified Content CID.

**Response `200 OK`:**

```json
{
  "content_cid": "QmContent...",
  "metadata_bundle_cid": "QmBundle...",
  "bundle_hash": "0xABCDEF...",
  "metadata_wrapper": { ... },
  "anchored": true,
  "anchor_record_cid": "QmAnchor..."
}
```

**Notes:**
- `anchored: false` is a valid state — content is live and payable before Bitcoin anchoring completes
- Bitcoin proof details (block height, txid) are in the Anchor Record, retrieved via `/api/v1/records/anchor/{bundle_hash}`
- The response does not include raw content data — content is retrieved directly via CID through the SatSwap layer

---

### POST `/api/v1/content/verify`

Verifies a piece of content against its two independent proofs. Returns each proof result independently — both passing constitutes the Right to Verify.

**Request body:**

```json
{
  "metadata_bundle_cid": "QmBundle..."
}
```

**Response `200 OK`:**

```json
{
  "metadata_bundle_cid": "QmBundle...",
  "bundle_hash": "0xABCDEF...",
  "bitcoin_proof": {
    "verified": true,
    "block_height": 875432,
    "tx_id": "a1b2c3...",
    "message": "Bundle Hash confirmed in Bitcoin block 875432"
  },
  "availability_proof": {
    "verified": true,
    "responding_hosts": 4,
    "message": "Content retrievable via SatSwap exchange"
  },
  "right_to_verify": true
}
```

**Notes:**
- Bitcoin proof: verifies the Bundle Hash appears in the Anchor Records table and matches an OP_RETURN in the referenced Bitcoin block. Requires only a Bitcoin node — no trust in any service.
- Availability proof: confirms the content is currently retrievable by initiating a SatSwap WANT message and receiving a valid QUOTE response.
- Both proofs are independent. `right_to_verify: true` requires both. A valid Bitcoin proof with `availability_proof.verified: false` means the content existed at that block height but is not currently being served.

---

## 12.2 Records Database Queries

These endpoints expose the three Records Database tables to application-layer query engines. All three tables are fully public — no authentication required. See Section 10.2 for the full Records Database specification.

### GET `/api/v1/records/hosts/{block_cid}`

Queries the Host Registry Records table for hosts currently serving the specified block CID.

**Query parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `max_msats` | integer | No | Filter hosts by maximum price per block in msats |
| `min_uptime_score` | float | No | Filter hosts by minimum uptime score (0.0–1.0) |

**Response `200 OK`:**

```json
{
  "block_cid": "QmBlock...",
  "hosts": [
    {
      "node_id": "node_xyz...",
      "lyw_address": "lnbc...",
      "price_msats": 1000,
      "uptime_score": 0.98,
      "last_seen_block": 875430,
      "supported_protocols": ["satswap/1.0"]
    }
  ],
  "count": 4
}
```

---

### GET `/api/v1/records/anchor/{bundle_hash}`

Queries the Anchor Records table for the Anchor Record associated with the specified Bundle Hash.

**Response `200 OK`:**

```json
{
  "metadata_bundle_cid": "QmBundle...",
  "bundle_hash": "0xABCDEF...",
  "wallet_address": "lnbc...",
  "tx_id": "a1b2c3...",
  "block_height": 875432,
  "published_by": "node_xyz...",
  "signature": "..."
}
```

**Response `404 Not Found`:**

```json
{
  "bundle_hash": "0xABCDEF...",
  "message": "No Anchor Record found. Content may not yet be anchored to Bitcoin — this is a valid intermediate state."
}
```

---

### GET `/api/v1/records/flags/{content_cid}`

Queries the Content Flag Records table for all flags associated with the specified Content CID.

**Query parameters:**

| Parameter | Type | Required | Description |
|---|---|---|---|
| `confirmed_only` | boolean | No | Return only flags with quorum confirmation |
| `min_severity` | string | No | Filter by severity level: `low`, `medium`, `high` |

**Response `200 OK`:**

```json
{
  "content_cid": "QmContent...",
  "flags": [
    {
      "flag_cid": "QmFlag...",
      "type": "copyright_claim",
      "severity": "high",
      "confirmed": true,
      "filed_by": "did:key:...",
      "filed_at_block": 875100
    }
  ],
  "count": 1
}
```

---

### POST `/api/v1/records/search`

Queries Anchor Records by Metadata Wrapper fields. The primary entry point for application-layer content discovery.

**Request body:**

```json
{
  "creator_did": "did:key:z6Mk...",
  "tags": ["music", "electronic"],
  "license_type": "custom",
  "title_contains": "remix",
  "after_block": 870000,
  "limit": 20,
  "offset": 0
}
```

**Response `200 OK`:**

```json
{
  "results": [
    {
      "content_cid": "QmContent...",
      "metadata_bundle_cid": "QmBundle...",
      "bundle_hash": "0xABCDEF...",
      "title": "My Remix",
      "creator_did": "did:key:z6Mk...",
      "block_height": 875432
    }
  ],
  "count": 3,
  "total": 3
}
```

---

## 12.3 Governance Operations

These endpoints interact with the Per-Content DAO governance layer. All state-modifying requests require authentication from a DAO member's DID.

### POST `/api/v1/dao/proposal`

Submits a new governance proposal for a specified Content CID.

**Request body:**

```json
{
  "content_cid": "QmContent...",
  "proposer_did": "did:key:z6Mk...",
  "type": "UPDATE_INCOME_DISTRIBUTION",
  "title": "Adjust income split",
  "description": "...",
  "proposed_state": {
    "distribution_split": {
      "creator": 0.60,
      "compound": 0.40
    }
  },
  "signature": "ed25519:..."
}
```

**Response `201 Created`:**

```json
{
  "proposal_cid": "QmProposal...",
  "proposal_id": "prop_875440_001",
  "status": "active",
  "expires_at_block": 879472
}
```

---

### POST `/api/v1/dao/vote`

Registers a DAO member's cryptographically signed vote on an active proposal.

**Request body:**

```json
{
  "proposal_cid": "QmProposal...",
  "voter_did": "did:key:z6Mk...",
  "vote": "FOR",
  "signature": "ed25519:..."
}
```

**Response `200 OK`:**

```json
{
  "proposal_cid": "QmProposal...",
  "updated_proposal_cid": "QmProposal2...",
  "current_weight_for": 0.50,
  "current_weight_against": 0.0,
  "threshold": 0.80,
  "status": "active"
}
```

**Notes:**
- Vote weight is derived from the voter's `income_share` in the DAO Configuration Object — not a fixed integer weight
- `income_share` values sum to 1.0; `current_weight_for` is directly the approval fraction

---

### POST `/api/v1/dao/execute/{proposal_id}`

Triggers Key 3 execution of a passed proposal after the `execution_delay_blocks` has elapsed.

**Response `200 OK`:**

```json
{
  "proposal_id": "prop_875440_001",
  "status": "executed",
  "execution_block": 875464,
  "updated_dao_cid": "QmDAO2..."
}
```

**Response `425 Too Early`:**

```json
{
  "proposal_id": "prop_875440_001",
  "status": "approved",
  "timelock_expires_at_block": 875464,
  "current_block": 875450,
  "message": "Timelock has not elapsed. Execution available after block 875464."
}
```

---

### GET `/api/v1/dao/state/{content_cid}`

Returns the current DAO state for the specified content.

**Response `200 OK`:**

```json
{
  "content_cid": "QmContent...",
  "dao_cid": "QmDAO...",
  "mutable_state_cid": "QmState...",
  "distribution_split": {
    "creator": 0.50,
    "compound": 0.50
  },
  "license_type": "custom",
  "members": [
    {
      "did": "did:key:z6Mk...",
      "income_share": 0.50,
      "role": "creator"
    }
  ],
  "active_proposals": ["QmProposal..."],
  "drawdown_mode": false
}
```

---

## 12.4 Fork Management

These endpoints support the Right to Fork: registering derivative works, querying royalty flows, and tracing provenance chains. The Child sets its own royalty terms — the Parent cannot impose them.

### POST `/api/v1/fork/register`

Registers a new derivative work by publishing a Metadata Wrapper with `is_fork: true` and populated `fork_provenance` fields.

**Request body:**

```json
{
  "content_cid": "QmDerivativeContent...",
  "metadata_wrapper": {
    "timestamp_proof": {
      "creation_time": 1735094400,
      "provenance_chain": {
        "parent_bundle_hash": "0x012345...",
        "is_fork": true,
        "derivative_type": "remix",
        "upstream_percentage": 0.15
      }
    },
    "protocol_metadata": {
      "version": "0.4",
      "wallet_address": "lnbc...",
      "dao_cid": "QmChildDAO...",
      "smart_contract_hash": "sha256:..."
    },
    "creator": { ... },
    "license": { ... }
  }
}
```

**Response `201 Created`:**

```json
{
  "content_cid": "QmDerivativeContent...",
  "metadata_bundle_cid": "QmChildBundle...",
  "bundle_hash": "0xDEFABC...",
  "parent_bundle_hash": "0x012345...",
  "upstream_percentage": 0.15,
  "status": "published"
}
```

**Notes:**
- The fork link is established by the Child's Metadata Wrapper — the Parent's content is unmodified
- `upstream_percentage` is the fraction of the Child's income routed to the Parent LYW address by Key 3
- The Parent cannot approve or reject a fork — the Right to Fork is unconditional

---

### GET `/api/v1/fork/royalties/{content_cid}`

Returns the royalty flow record for the specified CID from the LYW State Ledger.

**Response `200 OK`:**

```json
{
  "content_cid": "QmContent...",
  "inbound_royalties": {
    "sources": ["QmChildContent..."],
    "cycle_income_sats": 950,
    "total_received_sats": 4200
  },
  "outbound_royalties": {
    "parent_bundle_hash": "0x012345...",
    "upstream_percentage": 0.15,
    "cycle_outflow_sats": 1200,
    "total_routed_sats": 5100
  }
}
```

---

### GET `/api/v1/fork/provenance/{content_cid}`

Traces the complete lineage of a content piece by resolving the Attribution Chain (Section 10.4).

**Response `200 OK`:**

```json
{
  "content_cid": "QmContent...",
  "depth": 2,
  "chain": [
    {
      "level": 0,
      "bundle_hash": "0xDEFABC...",
      "creator_did": "did:key:child...",
      "derivative_type": "remix",
      "upstream_percentage": 0.15
    },
    {
      "level": 1,
      "bundle_hash": "0x012345...",
      "creator_did": "did:key:parent...",
      "derivative_type": null,
      "upstream_percentage": null
    }
  ]
}
```

---

## 12.5 LYW Status and Lightning Operations

These endpoints expose the LYW's economic state and Lightning operations. The LYW is the creator's personal Lightning node — the service reports its observable state but does not control it.

### GET `/api/v1/lyw/status/{content_cid}`

Returns the current LYW State Ledger snapshot for the specified content.

**Response `200 OK`:**

```json
{
  "content_cid": "QmContent...",
  "lyw_address": "lnbc...",
  "last_updated_block": 875440,
  "liquidity_yield": {
    "deployed_balance_sats": 950000,
    "cycle_income_sats": 12740,
    "yield_rate_ppm": 1200
  },
  "access_income": {
    "cycle_income_sats": 12250
  },
  "expenses": {
    "cycle_expenses_sats": 11000,
    "drawdown_mode": false
  },
  "balance": {
    "available_sats": 48600,
    "total_sats": 998600,
    "sunset_threshold_sats": 1000,
    "cycles_at_threshold": 0
  },
  "signed_by": "did:key:node...",
  "signature": "ed25519:..."
}
```

**Notes:**
- `drawdown_mode: true` means host SatSwap payments are suspended — content may have reduced availability
- `cycles_at_threshold > 0` means sunset evaluation is active — the balance has been below `sunset_threshold_sats` for that many consecutive distribution cycles
- The response is signed by the serving node's DID for authenticity verification

---

### GET `/api/v1/lyw/did/{node_id}`

Returns the Decentralized Identifier and associated service endpoints for the LYW node managing the specified node ID.

**Response `200 OK`:**

```json
{
  "node_id": "node_xyz...",
  "did": "did:key:...",
  "public_key": "base58:...",
  "satswap_endpoint": "https://node.example.com/satswap",
  "lyw_status_endpoint": "https://node.example.com/api/v1/lyw/status/"
}
```

---

### POST `/api/v1/lyw/zap`

Initiates a direct Lightning micropayment to a content creator's LYW address. Returns a BOLT11 invoice. Payment routes directly to the LYW — Key 3 records the inflow in `access_income.zap_income_sats`.

**Request body:**

```json
{
  "target_cid": "QmContent...",
  "amount_msats": 1000000,
  "memo": "Great work"
}
```

**Response `200 OK`:**

```json
{
  "invoice": "lnbc10u1p...",
  "amount_msats": 1000000,
  "expires_at": 1735094700,
  "target_lyw_address": "lnbc..."
}
```

---

## Error Reference

| Code | Reason | Resolution |
|---|---|---|
| `400 Bad Request` | Missing required parameters or invalid JSON | Check request body against the schema above |
| `401 Unauthorized` | Missing or invalid `X-API-KEY` or `X-SIG-AUTH` | Verify API key and re-sign the request payload with the correct DID key |
| `402 Payment Required` | LYW `available_sats` insufficient to fund the requested SatSwap exchange | Add sats to the LYW via `/api/v1/lyw/zap` or a direct Lightning payment to `lyw_address` |
| `404 Not Found` | Requested CID, Bundle Hash, or node_id not found | Verify the identifier; a `404` on an Anchor Record is a valid intermediate state |
| `409 Conflict` | Duplicate vote or proposal already active | Check active proposals via `/api/v1/dao/state/{content_cid}` |
| `425 Too Early` | Proposal timelock has not elapsed | Wait until `timelock_expires_at_block` before calling `/api/v1/dao/execute` |
| `429 Too Many Requests` | Rate limit exceeded | Honor the `Retry-After` response header |
| `503 Service Unavailable` | Node offline or DAO in emergency pause | Check node status; if DAO paused, Key 2 authorization required to resume |
