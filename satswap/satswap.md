# SatSwap Protocol Specification
## Atomic Block-for-Sats Exchange for Content-Addressed Storage

**Version:** 0.4  
**Date:** March 2026  
**Author:** Chad Lupkes (IPFS-Sats Protocol)  
**Repository:** github.com/chadlupkes/IPFS-Sats

---

## Abstract

SatSwap is a four-message atomic exchange protocol for content-addressed block retrieval. Any node can request any content block; any node that holds that block can serve it; payment settles atomically with delivery via Lightning Network HTLC. No free-riding. No trusted intermediary. No persistent session state required between node pairs.

SatSwap is not a modification of BitSwap. It is a distinct protocol that replaces BitSwap's reciprocity model — exchange blocks with peers who exchange blocks with you — with direct bilateral payment: serve a block, earn sats; request a block, pay sats. The economic mechanism is simpler, more robust, and does not require accounting for bilateral relationships across a peer graph.

A SatSwap node is a Lightning node. Not a node that runs alongside a Lightning node — a node whose payment settlement is handled by the Lightning Network natively. The Lightning HTLC mechanism is what enforces the atomicity of every exchange at the protocol level, without any additional escrow, intermediary, or trust relationship.

The exchange is the verification step. A host that delivers a block whose hash matches the requested CID has proven it holds that block. There is no separate proof-of-storage mechanism. There is no challenge-response verification. The four-message handshake is sufficient.

---

## 1. Background and Motivation

### 1.1 The Free-Riding Problem in Content-Addressed Networks

IPFS's BitSwap protocol operates on reciprocal altruism: nodes exchange blocks with peers who exchange blocks with them, with a credit/debt accounting system to manage short-term imbalances. In practice this model fails because:

- Nodes that consume content without contributing blocks accumulate debt but face no meaningful consequence
- ~70% of peers become unavailable within minutes of uploading content
- Over 90% of peers are unreachable after six months
- Node operators bear real costs — bandwidth, storage, electricity — with no compensation mechanism

The result is a network where content persistence depends on altruism, content availability is unreliable, and node operators have no economic reason to stay online.

### 1.2 Why Existing Solutions Are Insufficient

**Centralized pinning services** (Pinata, Infura) restore the trust model IPFS was designed to eliminate. Persistence is guaranteed by a billing relationship with a vendor, not by a protocol mechanism. Vendors can censor, deplatform, or shut down.

**Filecoin** addresses persistence through cryptographic proofs (Proof-of-Replication, Proof-of-Spacetime) but imposes industrial-scale barriers — specialized hardware, FIL token collateral, complex deal-making — and operates adjacent to the retrieval layer rather than integrated into it.

**BitSwap credit accounting** cannot solve the free-riding problem because debt in a network with no enforcement mechanism is not debt. It is a number that nodes may or may not honor.

### 1.3 The SatSwap Solution

SatSwap resolves the free-riding problem structurally, not through accounting. Every block retrieval requires payment. Payment settles atomically with delivery. A node that serves blocks earns sats continuously. A node that stops serving earns nothing. There is no debt, no credit, no bilateral relationship to maintain. The economic incentive is immediate, direct, and enforceable at the protocol level.

---

## 2. Protocol Architecture

### 2.1 Core Design Principles

**Minimal.** The protocol defines only what is necessary to complete an atomic exchange. Discovery, routing strategy, block assembly, and reputation are handled by adjacent layers. The four-message handshake is the complete protocol.

**Atomic.** The requesting node does not pay unless it receives a verifiable block. The delivering node does not release the block unless payment is confirmed. The Lightning HTLC mechanism enforces this without any additional escrow or intermediary.

**Implementation-agnostic.** Message definitions specify fields and semantics. Wire format, serialization, and transport are left to the implementer. A conforming implementation may use Protocol Buffers, CBOR, JSON, or any other encoding, provided required fields are present and correctly interpreted.

**Stateless per exchange.** Each four-message handshake is self-contained. No persistent session state is required between node pairs. Nodes may conduct exchanges with any number of counterparties simultaneously.

**Role-agnostic.** The handshake does not distinguish between a client requesting content for end-user delivery and an intermediate node requesting a block it does not hold locally in order to serve a downstream request. The same implementation handles every hop in a multi-node swarm delivery without modification.

### 2.2 System Architecture

```
┌──────────────────────────────────────────────────────────────┐
│                      SatSwap Node                            │
├──────────────────────────────────────────────────────────────┤
│                                                              │
│  ┌─────────────────────┐     ┌──────────────────────────┐  │
│  │   SatSwap Handler   │     │    Lightning Node        │  │
│  │                     │     │                          │  │
│  │  WANT               │     │  HTLC management         │  │
│  │  QUOTE              │◀───▶│  Invoice generation      │  │
│  │  PAYMENT_HASH       │     │  Preimage settlement     │  │
│  │  BLOCK              │     │  Channel management      │  │
│  └─────────────────────┘     └──────────────────────────┘  │
│           │                                                  │
│           ▼                                                  │
│  ┌─────────────────────┐     ┌──────────────────────────┐  │
│  │  Content-Addressed  │     │   Host Discovery Layer   │  │
│  │    Block Store      │     │                          │  │
│  │                     │     │  Records Database query  │  │
│  │  CID → block data   │     │  Host Registry Records   │  │
│  └─────────────────────┘     └──────────────────────────┘  │
│                                                              │
└──────────────────────────────────────────────────────────────┘
```

The SatSwap Handler and Lightning Node are unified — this is not a Lightning wallet attached to a content node. It is a single implementation where payment settlement is a native capability, not an integration.

---

## 3. Host Discovery

Before initiating a SatSwap exchange, a requesting node must locate hosts that hold the block it wants. This is handled by the Host Discovery Layer, which queries the Records Database for Host Registry Records matching the requested CID.

### 3.1 Host Registry Record Query

A requesting node queries the Host Discovery Layer with a block-level CID. The layer returns a list of Host Registry Records — each containing the host's Lightning endpoint, pricing policy, uptime score, and available block inventory.

```
QUERY_HOSTS {
  cid:          string    // Block-level CID being sought
  max_results:  uint32    // Maximum number of host records to return
}

HOST_RECORD {
  host_did:           string    // Host's decentralized identifier
  lightning_endpoint: string    // Host's Lightning node address
  price_msats_per_kb: uint64    // Host's stated price per kilobyte
  uptime_score:       float     // 0.0 to 1.0 reliability score
  last_seen:          uint64    // Unix timestamp of last activity
}
```

The requesting node receives a ranked list of candidate hosts, selects one or more based on price and uptime score, and initiates parallel SatSwap handshakes. The discovery step is entirely separate from the exchange — the four-message handshake assumes the requesting node already knows which host to contact.

---

## 4. The Four-Message Handshake

Every SatSwap exchange follows this sequence without exception:

```
Requesting Node              Delivering Node
       |                            |
       |---------- WANT ----------->|
       |                            |
       |<--------- QUOTE -----------|
       |                            |
       |------- PAYMENT_HASH ------>|
       |                            |
       |<--------- BLOCK -----------|
       |                            |
```

The exchange completes when the requesting node receives a BLOCK message containing data that verifies against the requested CID. If any step fails or times out, the exchange is abandoned and the requesting node may retry with a different host.

### 4.1 WANT

Sent by the requesting node to initiate an exchange.

```
WANT {
  cid:          string    // Content identifier of the requested block
  max_msats:    uint64    // Maximum price the requester will pay, in millisatoshis
  request_id:   string    // Unique identifier for this exchange instance
}
```

**Field notes:**

`cid` identifies the specific block being requested. For a multi-block file, each block in the content-addressed data structure has its own CID. The requesting node issues one WANT per block, potentially in parallel to multiple hosts.

`max_msats` communicates the requester's price ceiling. A delivering node that cannot serve the block at or below this ceiling should not respond with a QUOTE.

`request_id` is generated by the requesting node and must be unique per exchange. All subsequent messages echo this identifier to correlate the handshake.

---

### 4.2 QUOTE

Sent by the delivering node in response to a WANT.

```
QUOTE {
  request_id:   string    // Echoed from the WANT message
  cid:          string    // Echoed from the WANT message
  msats:        uint64    // Price the delivering node will accept, in millisatoshis
  invoice:      string    // BOLT11 Lightning invoice for the stated amount
  expires_at:   uint64    // Unix timestamp after which this quote is no longer valid
}
```

**Field notes:**

`msats` must be less than or equal to `max_msats` from the WANT. A well-behaved delivering node does not issue a QUOTE above the requester's price ceiling.

`invoice` is a standard BOLT11 Lightning invoice. The payment hash embedded in the invoice is the cryptographic commitment that binds this payment to this specific exchange.

`expires_at` gives the requesting node a deadline for payment initiation. Quotes not paid before expiry are abandoned by the delivering node.

---

### 4.3 PAYMENT_HASH

Sent by the requesting node after paying the Lightning invoice.

```
PAYMENT_HASH {
  request_id:     string    // Echoed from prior messages
  cid:            string    // Echoed from prior messages
  payment_hash:   string    // Hash of the Lightning payment preimage
}
```

**Field notes:**

`payment_hash` is the hash of the HTLC preimage. It proves that a payment has been initiated and committed on the Lightning Network. The delivering node verifies this against the invoice it issued in the QUOTE before proceeding to deliver the block.

The delivering node does not release the block until it has confirmed that the payment hash corresponds to the invoice and that the payment is in-flight via the Lightning Network.

---

### 4.4 BLOCK

Sent by the delivering node after payment is confirmed.

```
BLOCK {
  request_id:     string    // Echoed from prior messages
  cid:            string    // CID of the delivered block
  data:           bytes     // Raw block data
  preimage:       string    // Lightning payment preimage
}
```

**Field notes:**

`data` is the raw bytes of the block. The requesting node verifies that hashing `data` produces `cid`. This is the foundational property of content addressing — the same CID integrity check that underlies the entire protocol. If the hash does not match, the block is invalid, the exchange has failed, and the failure is attributable to the delivering node via the payment record.

`preimage` is the Lightning payment preimage. By including it in the BLOCK message, the delivering node allows the HTLC to settle — the payment completes as the preimage propagates back through the Lightning Network. Revealing the preimage is the delivering node's proof that it is releasing the block in exchange for payment.

---

## 5. Atomicity Guarantee

The atomicity of every SatSwap exchange is enforced by the Lightning Network's HTLC mechanism, not by the protocol itself.

```
Requesting Node                          Delivering Node
       |                                        |
       | Pays invoice → HTLC locked on LN      |
       |                                        |
       | -------- PAYMENT_HASH ---------------> |
       |                                        | Verifies payment in-flight
       |                                        | Retrieves block from store
       | <-------- BLOCK (+ preimage) --------- |
       |                                        |
       | Verifies hash(data) == cid             |
       | Preimage propagates → HTLC settles     |
       |                                        |
```

**What cannot happen:**
- The requesting node pays and receives no block: the HTLC timelock returns the payment if the preimage is never revealed
- The delivering node releases the block and receives no payment: revealing the preimage in the BLOCK message is what causes the payment to settle — withholding the block means withholding the preimage means no payment
- Either party is defrauded through normal protocol operation

The exchange is atomic by construction. No escrow. No intermediary. No trust required.

---

## 6. Pricing

### 6.1 Host Pricing Policy

Each host publishes its pricing policy in its Host Registry Record. The canonical pricing field is `price_msats_per_kb` — the host's stated price per kilobyte of block data served.

Hosts may also implement dynamic pricing based on demand signals, but any dynamic pricing must result in a QUOTE at or below the requester's `max_msats` ceiling. A host that cannot meet the ceiling for a given block at a given time should not respond to the WANT.

**Reference pricing:**

| Block Size | Base Rate (10 msats/KB) | Example Total |
|------------|------------------------|---------------|
| 256 KB     | 10 msats/KB            | 2,560 msats   |
| 512 KB     | 10 msats/KB            | 5,120 msats   |
| 1 MB       | 10 msats/KB            | 10,240 msats  |

At a Bitcoin price of $100,000 USD, 10,240 msats ≈ $0.001. Content retrieval is economically negligible for requesters; the aggregate of many retrievals is meaningful income for hosts.

### 6.2 Price Discovery

A requesting node that receives QUOTE responses from multiple hosts selects based on its own strategy — lowest price, best uptime score, lowest latency, or any combination. The Host Discovery Layer's uptime_score ranking provides a default ordering that balances price against reliability.

### 6.3 Host Economics

```
Revenue (illustrative):
  1 TB served/month @ 10 msats/KB = 10,000,000,000 msats = 10,000,000 sats

Costs (illustrative):
  Bandwidth (1 TB @ $5/TB):   $5
  Storage (1 TB SSD):         $2
  Electricity:                $3
  Total:                      $10/month

Net at $100k BTC:             ~$10/month per TB hosted
```

The economics improve with popular content: high-demand blocks are requested more frequently, generating more SatSwap revenue per unit of storage. Hosts that serve popular content earn more. This creates a natural incentive for hosts to cache and serve content that users actually want.

---

## 7. Multi-Block Retrieval

### 7.1 Parallel Handshakes

For content split across multiple blocks, the requesting node issues parallel WANT messages — one per block, potentially to different hosts. Each handshake is independent. A WANT sent to Host A has no relationship to a WANT sent to Host B, even for blocks belonging to the same file.

This parallelism is the swarm delivery model described in the IPFS-Sats white paper Section 3.6. The aggregate effect of many independent exchanges is a delivery network where popular content is faster and cheaper to retrieve than unpopular content, because more hosts are caching and serving it.

### 7.2 Batched Payment Optimization

For requesting nodes with established channel relationships with a specific host, a batched payment optimization is possible: a single HTLC covers multiple blocks, with the preimage revealed only after all blocks are delivered. This reduces Lightning routing fees for high-volume retrieval pairs.

**Batch flow:**
```
WANT (block_1), WANT (block_2), ... WANT (block_N)
  → single HTLC covering total price
  → BLOCK (block_1), BLOCK (block_2), ... BLOCK (block_N)
  → single preimage reveal settles all
```

Batching is an optimization, not a protocol requirement. A conforming implementation that handles only single-block exchanges is fully compliant.

---

## 8. Failure Handling

| Failure Condition | Cause | Resolution |
|---|---|---|
| No QUOTE received | Host does not hold block, cannot meet price ceiling, or is offline | Wait for timeout, retry with different host from discovery results |
| QUOTE above max_msats | Misbehaving host issued a quote above the stated ceiling | Discard QUOTE, treat exchange as failed, note as negative signal |
| Quote expires before payment | Requester failed to pay within expires_at window | Host abandons exchange; requester may issue new WANT |
| Block fails CID verification | Corrupted or fraudulent delivery | Retry with different host; record failed delivery as negative uptime signal |
| Payment in-flight, no BLOCK received | Host offline after payment initiated | Wait for HTLC timelock expiry; payment returns automatically; retry |

**The HTLC timelock is the safety net.** A requester that has paid but not received a BLOCK should wait for HTLC resolution before retrying. The Lightning Network guarantees return of funds if the preimage is not revealed within the timelock window.

---

## 9. Security

### 9.1 Attack Vectors and Mitigations

| Attack | Description | Mitigation |
|---|---|---|
| **Block withholding** | Host accepts payment initiation but never reveals preimage or delivers BLOCK | HTLC timelock returns payment automatically; host earns nothing |
| **Invalid block delivery** | Host delivers data that does not hash to the requested CID | Requester verifies CID before preimage propagates; payment fails; attributable to host via payment record |
| **Payment evasion** | Requester receives BLOCK but attempts to prevent preimage settlement | Preimage is revealed in the BLOCK message itself; settlement is automatic once preimage propagates |
| **Price manipulation** | Host quotes artificially high prices | Requester queries multiple hosts; market competition regulates pricing; high-pricing hosts receive fewer WANTs |
| **WANT flooding** | Attacker floods host with WANT messages at no cost | Hosts may implement rate limiting; requiring a small payment to receive a QUOTE is a valid anti-DoS measure |
| **Sybil host attack** | Attacker creates many fake host identities to manipulate discovery rankings | Host Registry Records are signed by host DID; reputation signals accumulate over time and cannot be transferred |

### 9.2 Host Reputation via Host Registry Records

Hosts publish Host Registry Records to the Records Database. The `uptime_score` field in the Host Registry Record is the canonical reputation signal — it reflects the ratio of successful deliveries to total exchange attempts, updated by the host and observable by any participant querying the Records Database.

A host that consistently fails to deliver valid blocks — through offline status, invalid block delivery, or HTLC abandonment — will accumulate a low uptime_score and appear lower in Host Discovery Layer results, receiving fewer WANT messages. This is the enforcement mechanism: not a punishment system, but a natural consequence of unreliable service in a market where requesters choose their counterparties.

---

## 10. Implementation Guide

### 10.1 Prerequisites

A conforming SatSwap implementation requires:

- A Lightning node implementation (LND or Core Lightning are the mature options) with HTLC management capability
- A content-addressed block store capable of CID-based lookup and retrieval
- Network connectivity for both Lightning peer connections and SatSwap message exchange
- A key pair for host DID generation and Host Registry Record signing

The reference implementation language is Go. The Lightning Network ecosystem has the most mature Go tooling (LND, go-libp2p, go-cid).

### 10.2 Reference Implementation Pseudocode

```go
// SatSwap Node — Core Exchange Logic

package satswap

type SatSwapNode struct {
    blockStore  ContentAddressedBlockStore
    lightning   LightningNode
    discovery   HostDiscoveryLayer
    pricing     PricingEngine
}

// REQUEST SIDE: Retrieve a block with payment

func (n *SatSwapNode) RequestBlock(cid string, maxMsats uint64) ([]byte, error) {
    // 1. Discover hosts that hold this block
    hosts := n.discovery.QueryHosts(cid, 10)
    if len(hosts) == 0 {
        return nil, ErrNoHostsFound
    }

    // 2. Send WANT to best candidate
    requestID := generateRequestID()
    want := WANT{
        CID:       cid,
        MaxMsats:  maxMsats,
        RequestID: requestID,
    }
    quote, err := hosts[0].SendWant(want)
    if err != nil || quote.Msats > maxMsats {
        return nil, ErrNoValidQuote
    }

    // 3. Pay Lightning invoice → HTLC locks payment
    paymentHash, err := n.lightning.PayInvoice(quote.Invoice)
    if err != nil {
        return nil, ErrPaymentFailed
    }

    // 4. Send PAYMENT_HASH to host
    block, err := hosts[0].SendPaymentHash(PAYMENT_HASH{
        RequestID:   requestID,
        CID:         cid,
        PaymentHash: paymentHash,
    })
    if err != nil {
        // Wait for HTLC timelock to return payment
        n.lightning.WaitForHTLCResolution(paymentHash)
        return nil, ErrBlockDeliveryFailed
    }

    // 5. Verify block integrity — this is the proof of delivery
    if computeCID(block.Data) != cid {
        return nil, ErrInvalidBlock
    }

    // 6. Preimage propagates automatically → payment settles on Lightning
    // Store block locally
    n.blockStore.Put(cid, block.Data)

    return block.Data, nil
}

// SERVE SIDE: Deliver a block in exchange for payment

func (n *SatSwapNode) HandleWant(want WANT) (*QUOTE, error) {
    // 1. Check if we hold the block
    block, err := n.blockStore.Get(want.CID)
    if err != nil {
        return nil, ErrBlockNotFound
    }

    // 2. Calculate price — must be at or below requester's ceiling
    price := n.pricing.Calculate(want.CID, len(block))
    if price > want.MaxMsats {
        return nil, ErrPriceExceedsCeiling
    }

    // 3. Generate Lightning invoice with preimage
    preimage := generatePreimage()
    paymentHash := sha256(preimage)
    invoice := n.lightning.CreateInvoice(price, paymentHash)

    // 4. Store preimage for delivery after payment confirmed
    n.storeExchangeState(want.RequestID, preimage, block)

    return &QUOTE{
        RequestID: want.RequestID,
        CID:       want.CID,
        Msats:     price,
        Invoice:   invoice,
        ExpiresAt: now() + 60,
    }, nil
}

func (n *SatSwapNode) HandlePaymentHash(ph PAYMENT_HASH) (*BLOCK, error) {
    // 1. Retrieve stored exchange state
    state := n.getExchangeState(ph.RequestID)

    // 2. Verify payment is in-flight on Lightning Network
    if !n.lightning.VerifyPaymentInFlight(ph.PaymentHash) {
        return nil, ErrPaymentNotFound
    }

    // 3. Deliver block with preimage — payment settles automatically
    return &BLOCK{
        RequestID: ph.RequestID,
        CID:       ph.CID,
        Data:      state.block,
        Preimage:  state.preimage,
    }, nil
}
```

### 10.3 Swarm Delivery Pattern

An intermediate node — one that receives a WANT for a block it does not hold locally — can participate in swarm delivery by issuing its own WANT upstream:

```go
func (n *SatSwapNode) HandleWantAsIntermediary(want WANT) (*QUOTE, error) {
    // Check local store first
    if n.blockStore.Has(want.CID) {
        return n.HandleWant(want)
    }

    // Not held locally — query upstream hosts
    upstreamHosts := n.discovery.QueryHosts(want.CID, 5)
    if len(upstreamHosts) == 0 {
        return nil, ErrBlockNotFound
    }

    // Margin: charge downstream more than upstream cost
    upstreamPrice := upstreamHosts[0].EstimatedPrice(want.CID)
    myPrice := upstreamPrice + n.pricing.IntermediaryMargin()

    if myPrice > want.MaxMsats {
        return nil, ErrPriceExceedsCeiling
    }

    // Generate invoice for downstream, will pay upstream on delivery
    // ... standard QUOTE generation ...
}
```

The intermediary earns the spread between what it charges downstream and what it pays upstream. The protocol has no visibility into this — every hop looks identical from the outside.

---

## 11. Implementation Roadmap

### Phase 1 — Core Protocol

**Goal:** Single-block paid retrieval working end-to-end on testnet.

**Deliverables:**
- SatSwap node implementation in Go with integrated Lightning (LND)
- Four-message handshake: WANT, QUOTE, PAYMENT_HASH, BLOCK
- CID verification on block delivery
- Host Registry Record publishing to Records Database testnet
- Basic Host Discovery Layer query

**Success criteria:**
- Single-block exchange completes end-to-end on Lightning testnet
- Payment returns correctly when block delivery fails
- Host Registry Record visible in Records Database

### Phase 2 — Network and Tooling

**Goal:** Multi-host swarm delivery working; developer tooling available.

**Deliverables:**
- Parallel WANT dispatch to multiple hosts
- Batched payment optimization for high-volume pairs
- Host pricing dashboard
- Requester client library (Go)
- Records Database node implementation

**Success criteria:**
- Large file retrieval (1GB+) economically viable via parallel exchanges
- Host earnings cover operating costs with margin at reference pricing
- Third-party developers can query Records Database and initiate exchanges

### Phase 3 — Ecosystem

**Goal:** Production deployment; application developer SDKs; mainnet.

**Deliverables:**
- Client SDKs in JavaScript, Python, Rust
- Network explorer — price discovery, host reputation, exchange analytics
- Integration with IPFS Desktop for end-user access
- Mainnet deployment with real sats

**Success criteria:**
- 100+ hosts online with competitive pricing
- 1,000+ daily paid exchanges
- At least one third-party application built on the protocol API

---

## 12. Relationship to the IPFS-Sats Protocol Stack

SatSwap is the transport layer of the IPFS-Sats protocol. It handles block retrieval and payment. Everything else is built on top of it:

| Layer | Component | Function |
|---|---|---|
| Transport | SatSwap | Atomic block-for-sats exchange |
| Discovery | Host Discovery Layer / Records Database | Locating hosts, Anchor Records, Content Flag Records |
| Economics | Lightning Yield Wallet | Generating yield to fund host payments |
| Governance | Per-Content DAO | Revenue distribution, fork royalties, licensing |
| Provenance | Metadata Bundle / Bitcoin OP_RETURN | Content identity and timestamping |

SatSwap must work flawlessly before the layers above it can function. A creator whose LYW is funding host payments depends on SatSwap exchanges completing reliably. An application that monetizes content access depends on SatSwap as the payment primitive. The entire economic model of the IPFS-Sats protocol closes through SatSwap.

---

## 13. Get Involved

The reference SatSwap implementation is the most important near-term deliverable in the IPFS-Sats ecosystem. Go developers with Lightning Network experience are invited build a conforming implementation from this specification. The four-message handshake is minimal. The intended timeline is weeks, not months.

**Repository:** github.com/chadlupkes/IPFS-Sats  
**Community:** Bitcoin, Nostr, Lightning Dev communities  
**Contact:** chadlupkes@gmail.com

The specification is as complete as I can make it. The next step is implementation.

---

*SatSwap is released as a public good. No patents. No restrictions. Build with it.*
