# SatSwap Core Protocol Specification
## BitSwap + Lightning Network Integration for IPFS Block Exchange

**Version:** 1.0  
**Date:** December 2025  
**Author:** Chad (IPFS-Sats Protocol)

---

## Abstract

SatSwap is a protocol modification of IPFS's BitSwap that replaces the traditional credit-based block exchange with atomic Lightning Network micropayments. This enables a trustless, pay-per-block economy for IPFS content retrieval, eliminating free-riding while maintaining the performance characteristics of the original BitSwap protocol.

**Core Innovation:** Every IPFS block request can be atomically paid for using Lightning Network HTLCs (Hashed Timelock Contracts), creating a direct economic incentive for nodes to serve content without requiring complex accounting or trust relationships.

---

## 1. Problem Statement

### 1.1 BitSwap's Economic Limitations

IPFS's current BitSwap protocol operates on a credit/debt system where:
- Nodes exchange blocks based on reciprocal altruism
- "Free-riders" can request blocks without contributing
- No direct economic incentive exists for long-term content hosting
- ~70% of peers become unavailable within minutes of upload
- >90% of peers are unreachable after 6 months

### 1.2 The Need for Atomic Payments

Traditional approaches fail because:
- **Filecoin** requires complex deal-making and high collateral
- **Centralized pinning services** reintroduce platform dependency
- **Voluntary pinning** leads to rapid content decay

**Solution:** Integrate sub-millisecond Lightning payments directly into the block exchange protocol.

---

## 2. Technical Architecture

### 2.1 Core Components

```
┌─────────────────────────────────────────────────────────┐
│                     SatSwap Protocol                     │
├─────────────────────────────────────────────────────────┤
│                                                          │
│  ┌──────────────┐         ┌──────────────┐             │
│  │   BitSwap    │────────▶│   SatSwap    │             │
│  │  (Modified)  │         │   Handler    │             │
│  └──────────────┘         └──────────────┘             │
│         │                        │                      │
│         │                        ▼                      │
│         │                 ┌──────────────┐             │
│         │                 │   Lightning  │             │
│         │                 │   Gateway    │             │
│         │                 └──────────────┘             │
│         │                        │                      │
│         ▼                        ▼                      │
│  ┌──────────────────────────────────────┐              │
│  │         IPFS Block Store             │              │
│  └──────────────────────────────────────┘              │
│                                                          │
└─────────────────────────────────────────────────────────┘
```

### 2.2 Protocol Flow

**Standard BitSwap (No Payment):**
1. Requester sends WANT message for CID
2. Provider checks block availability
3. Provider sends block immediately
4. Credit/debt system updates internally

**SatSwap (Payment-Required):**
1. Requester sends WANT message with payment capability flag
2. Provider responds with Lightning invoice (HTLC hash)
3. Requester locks payment via Lightning HTLC
4. Provider delivers block with HTLC preimage
5. Payment settles atomically upon block verification

---

## 3. Message Protocol Extensions

### 3.1 Extended BitSwap Message Format

```protobuf
// Standard BitSwap Wantlist entry
message WantlistEntry {
  bytes block = 1;          // CID of wanted block
  int32 priority = 2;       // Priority (higher = more urgent)
  bool cancel = 3;          // Cancel previous want

  // SatSwap Extensions
  bool payment_enabled = 4;      // Supports Lightning payments
  uint64 max_price_msats = 5;    // Maximum willing to pay (millisats)
  string ln_node_pubkey = 6;     // Lightning node public key
}

// Provider's response for paid blocks
message BlockOffer {
  bytes block_cid = 1;           // CID being offered
  uint64 price_msats = 2;        // Price in millisatoshis
  bytes payment_hash = 3;        // Lightning HTLC payment hash
  string ln_invoice = 4;         // BOLT11 Lightning invoice
  uint32 timeout_seconds = 5;    // Payment timeout
}

// Block delivery with payment proof
message PaidBlock {
  bytes block_cid = 1;           // CID of the block
  bytes block_data = 2;          // Actual block content
  bytes payment_preimage = 3;    // HTLC preimage (proves payment)
  bytes signature = 4;           // Provider's signature
}
```

### 3.2 Backward Compatibility

SatSwap nodes MUST:
- Accept standard BitSwap requests (payment_enabled = false)
- Fall back to traditional credit/debt for non-paying peers
- Advertise payment capability in peer discovery

This ensures gradual network adoption without breaking existing IPFS functionality.

---

## 4. Atomic Exchange Mechanism

### 4.1 HTLC Integration

**Hashed Timelock Contracts** guarantee atomic exchange:

```
┌─────────────┐                           ┌─────────────┐
│  Requester  │                           │  Provider   │
└─────────────┘                           └─────────────┘
       │                                          │
       │  1. WANT(CID, max_price)                │
       ├─────────────────────────────────────────▶
       │                                          │
       │  2. OFFER(price, payment_hash)          │
       ◀─────────────────────────────────────────┤
       │                                          │
       │  3. Lock payment via HTLC               │
       │     (reveals R if block valid)          │
       ├─────────────────────────────────────────▶
       │                                          │
       │  4. BLOCK(data, preimage R)             │
       ◀─────────────────────────────────────────┤
       │                                          │
       │  5. Verify block matches CID            │
       │     Reveal R → Payment settles          │
       │                                          │
```

**Key Properties:**
- **Atomicity:** Block delivery OR payment refund (no partial outcomes)
- **Trustless:** No escrow or intermediary required
- **Instant:** Settlement in <2 seconds via Lightning

### 4.2 Verification Flow

```python
def verify_and_settle_payment(block_data, block_cid, preimage, payment_hash):
    """
    Atomic verification and payment settlement.
    Returns: (success: bool, error: str)
    """
    # Step 1: Verify block integrity
    computed_cid = hash_block(block_data)
    if computed_cid != block_cid:
        return (False, "Block CID mismatch")
    
    # Step 2: Verify preimage matches payment hash
    computed_hash = sha256(preimage)
    if computed_hash != payment_hash:
        return (False, "Invalid payment preimage")
    
    # Step 3: Reveal preimage to Lightning Network
    # This automatically settles the HTLC payment
    ln.reveal_preimage(preimage)
    
    # Step 4: Store block locally
    ipfs.block_store.put(block_cid, block_data)
    
    return (True, "Payment settled, block stored")
```

---

## 5. Pricing Mechanisms

### 5.1 Dynamic Pricing Model

Providers set prices based on:
- **Block size** (bytes)
- **Block popularity** (request frequency)
- **Provider resources** (bandwidth, storage cost)
- **Network conditions** (congestion, routing fees)

**Reference Formula:**
```
price_msats = (base_rate × block_size_kb) + (popularity_multiplier × demand_factor)
```

**Example Pricing:**
| Block Size | Base Rate | Popularity | Total Price |
|------------|-----------|------------|-------------|
| 256 KB     | 10 msats  | Low (1x)   | 10 msats    |
| 256 KB     | 10 msats  | High (3x)  | 30 msats    |
| 1 MB       | 40 msats  | Medium (2x)| 80 msats    |

### 5.2 Price Discovery

**Provider Announcement:**
```protobuf
message PricingPolicy {
  uint64 base_rate_msats_per_kb = 1;
  uint64 min_price_msats = 2;
  uint64 max_price_msats = 3;
  repeated PriceMultiplier multipliers = 4;
}

message PriceMultiplier {
  bytes cid_prefix = 1;      // Apply to specific content
  float multiplier = 2;      // Price adjustment factor
  string reason = 3;         // "high_demand", "rare_content"
}
```

**Requester Strategy:**
- Query multiple providers for price quotes
- Select optimal provider (price, latency, reliability)
- Negotiate timeout and payment conditions

---

## 6. Performance Optimizations

### 6.1 Batched Payments

For multi-block content (e.g., large files split into 256KB chunks):

```
Single HTLC → Multiple Blocks → Single Settlement
```

**Batch Protocol:**
```protobuf
message BatchRequest {
  repeated bytes block_cids = 1;    // List of wanted blocks
  uint64 total_budget_msats = 2;    // Maximum total payment
  bytes batch_payment_hash = 3;     // Single HTLC for entire batch
}

message BatchResponse {
  repeated PaidBlock blocks = 1;     // All blocks with shared preimage
  bytes batch_preimage = 2;          // Single preimage unlocks all
  uint64 total_price_msats = 3;      // Final batch price
}
```

**Benefits:**
- Reduces Lightning Network routing fees (one payment vs. hundreds)
- Improves throughput for large file retrievals
- Maintains atomicity (all blocks or full refund)

### 6.2 Payment Channels

For frequent requester-provider pairs:

1. **Open Payment Channel:** Lock collateral once
2. **Off-chain Updates:** Exchange blocks with signed state updates
3. **Close Channel:** Settle final balance on Lightning Network

**Use Case:** Media streaming, database replication, continuous backup

---

## 7. Security Considerations

### 7.1 Attack Vectors and Mitigations

| Attack | Description | Mitigation |
|--------|-------------|------------|
| **Block Withholding** | Provider accepts payment but doesn't send block | HTLC timeout returns payment; reputation system penalizes provider |
| **Invalid Block** | Provider sends corrupted data | Requester verifies CID before revealing preimage; payment fails if mismatch |
| **Payment Evasion** | Requester receives block but doesn't pay | HTLC ensures payment or provider retains block; no free-riding possible |
| **Price Manipulation** | Provider quotes artificially high prices | Requester queries multiple providers; market competition regulates pricing |
| **DoS via Invoices** | Attacker floods provider with payment requests | Rate limiting; require small bond for quote requests |

### 7.2 Reputation System

**Trust Anchor:**
```protobuf
message ProviderReputation {
  string peer_id = 1;                    // IPFS peer identifier
  uint64 total_blocks_served = 2;        // Successful deliveries
  uint64 failed_deliveries = 3;          // Timeouts or invalid blocks
  uint64 average_response_time_ms = 4;   // Latency metric
  repeated bytes verified_by_peers = 5;  // Peer signatures (web of trust)
}
```

**Reputation Score:**
```
score = (successful_deliveries / total_requests) × speed_factor
```

Requesters prioritize high-reputation providers for critical content.

---

## 8. Implementation Roadmap

### 8.1 Phase 1: Core Protocol (Months 1-3)

**Deliverables:**
- Modified BitSwap message handlers with payment flags
- Lightning Gateway integration (LND/Core Lightning)
- Basic HTLC verification and settlement logic
- Reference implementation in Go (go-ipfs fork)

**Success Criteria:**
- Single-block paid retrieval works end-to-end
- Payment settlement <2 seconds
- Backward compatibility with standard BitSwap verified

### 8.2 Phase 2: Optimization (Months 4-6)

**Deliverables:**
- Batched payment protocol
- Payment channel support for frequent pairs
- Dynamic pricing engine
- Reputation system (basic trust scores)

**Success Criteria:**
- Large file retrieval (1GB+) economically viable
- Provider earnings cover hosting costs + profit margin
- Network throughput matches or exceeds standard BitSwap

### 8.3 Phase 3: Ecosystem (Months 7-12)

**Deliverables:**
- Client SDKs (JavaScript, Python, Rust)
- Provider dashboard (pricing controls, earnings analytics)
- Network explorer (price discovery, provider search)
- Integration with IPFS GUIs (IPFS Desktop, Brave)

**Success Criteria:**
- 100+ providers online with competitive pricing
- 1000+ daily paid retrievals
- Documented use cases (media streaming, archival services)

---

## 9. Economic Model

### 9.1 Cost-Benefit Analysis

**Provider Economics:**
```
Revenue per Month:
  - 1TB served @ 40 msats/MB = 40,000,000 msats = 40,000 sats (~$40 at $100k BTC)

Costs per Month:
  - Bandwidth (1TB @ $5/TB) = $5
  - Storage (1TB SSD) = $2
  - Electricity = $3
  
Net Profit: $40 - $10 = $30/month per TB
```

**Requester Economics:**
```
Cost to retrieve 1GB file:
  - 1GB @ 40 msats/MB = 40,000 msats = 40 sats (~$0.04)

Compared to:
  - AWS S3 egress: $0.09/GB
  - Traditional CDN: $0.05/GB
  - SatSwap: $0.04/GB + instant, censorship-resistant
```

### 9.2 Market Equilibrium

**Supply-Demand Dynamics:**
- Low content availability → Higher prices → More providers join
- High provider competition → Lower prices → More requester adoption
- Popular content → Distributed across many providers → Reliable, cheap access

**Long-term Stability:**
- Payment-per-block eliminates altruism dependency
- Economic incentives ensure content persists as long as demand exists
- Market-driven pricing prevents both exploitation and undervaluation

---

## 10. Conclusion and Next Steps

### 10.1 Core Achievement

SatSwap transforms IPFS from a volunteer-based network into a **self-sustaining data economy** by:
1. **Eliminating free-riding** through atomic micropayments
2. **Incentivizing persistence** via direct provider compensation
3. **Maintaining performance** through optimized batching and channels
4. **Ensuring trust** via cryptographic verification (HTLCs)

### 10.2 Path Forward

**Immediate Actions:**
1. **Finalize Spec:** Community review and feedback (Month 1)
2. **Reference Implementation:** Fork go-ipfs, integrate LND (Months 1-3)
3. **Testnet Launch:** Deploy to Bitcoin testnet for public testing (Month 4)
4. **Mainnet Beta:** Limited production deployment (Month 6)

**Community Engagement:**
- GitHub: `ipfs-sats/satswap-spec`
- Discussion: IPFS Forums, Lightning Dev Mailing List
- Funding: Open-source development grants, angel investment

### 10.3 Vision

SatSwap is the foundation for the larger IPFS-Sats protocol, which adds:
- **Bitcoin timestamping** for content verification (Right to Verify)
- **Automated royalties** for derivative works (Right to Fork)
- **DAO governance** for per-content economics

But the core—**pay-per-block via Lightning**—must work flawlessly first. This specification provides the technical blueprint to make that vision real.

---

## Appendix: Reference Implementation Pseudocode

```go
// SatSwap Handler - Core Logic

package satswap

import (
    "github.com/ipfs/go-cid"
    "github.com/lightningnetwork/lnd/lnrpc"
)

type SatSwapNode struct {
    ipfs     IPFSBlockStore
    lightning LightningGateway
    pricing  PricingEngine
}

// Request a block with payment
func (n *SatSwapNode) RequestPaidBlock(cid cid.Cid, maxPrice uint64) ([]byte, error) {
    // 1. Find provider and get price quote
    provider := n.discoverProvider(cid)
    offer := provider.GetBlockOffer(cid)
    
    if offer.PriceMillisats > maxPrice {
        return nil, ErrPriceTooHigh
    }
    
    // 2. Create HTLC payment
    htlc := n.lightning.CreateHTLC(offer.PaymentHash, offer.PriceMillisats)
    
    // 3. Request block with payment proof
    response := provider.RequestWithPayment(cid, htlc)
    
    // 4. Verify block and settle payment
    if !verifyCID(response.BlockData, cid) {
        n.lightning.CancelHTLC(htlc)
        return nil, ErrInvalidBlock
    }
    
    if !verifyPreimage(response.Preimage, offer.PaymentHash) {
        return nil, ErrInvalidPreimage
    }
    
    // 5. Reveal preimage → payment settles automatically
    n.lightning.RevealPreimage(response.Preimage)
    
    // 6. Store block locally
    n.ipfs.Put(cid, response.BlockData)
    
    return response.BlockData, nil
}

// Serve a block for payment
func (n *SatSwapNode) ServeBlockForPayment(cid cid.Cid) (*BlockOffer, error) {
    // 1. Check if we have the block
    block, err := n.ipfs.Get(cid)
    if err != nil {
        return nil, ErrBlockNotFound
    }
    
    // 2. Calculate price
    price := n.pricing.CalculatePrice(cid, len(block))
    
    // 3. Generate Lightning invoice
    preimage := generateRandomPreimage()
    paymentHash := sha256(preimage)
    invoice := n.lightning.CreateInvoice(price, paymentHash)
    
    // 4. Store preimage for later delivery
    n.storePreimage(cid, preimage)
    
    return &BlockOffer{
        CID:          cid,
        PriceMillisats: price,
        PaymentHash:  paymentHash,
        Invoice:      invoice,
    }, nil
}
```

---

**End of Specification**

For questions, contributions, or implementation assistance:
- Email: chadlupkes@gmail.com
- GitHub: github.com/IPFS-Sats/satswap
- Community: Pending Interest
