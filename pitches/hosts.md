# Pitch to Hosts

## Serve Blocks. Earn Sats. No Minimum Scale.

The IPFS-Sats protocol needs a distributed network of hosts to serve content blocks to requesters. Every host earns sats per block delivered via AtomicSats exchange. The mechanism is the same whether you are running a personal server on home broadband or operating a commercial data center. Capacity determines how much you can earn. Reliability determines how often you are selected. Nothing else.

---

## How Hosting Works

An AtomicSats host is a Lightning node that serves content blocks. Not a Lightning wallet attached to a content server — a single unified implementation where block delivery and payment settlement are the same operation.

When a requester wants a content block, it queries the Host Discovery Layer for hosts that hold that block. Your Host Registry Record — the record you publish to the Records Database advertising your block inventory, pricing, Lightning endpoint, and uptime score — is what makes you visible in that query. The Discovery Layer returns a ranked list of candidate hosts. The requester sends WANT messages to the best candidates. You respond with a QUOTE and a Lightning invoice. The requester pays. You deliver the block with the Lightning preimage. The HTLC settles. You earned sats.

That is the complete earning mechanism. No separate storage contract to negotiate. No separate payment routing role. No minimum capacity requirement. No staking. Serve a valid block, receive payment. Stop serving, receive nothing.

---

## The Economics

**You set your own price.** Your Host Registry Record contains your `price_msats_per_kb` — the price per kilobyte you charge for block delivery. The Host Discovery Layer uses this field, along with your uptime score, to rank you in requester queries. Price competitively and maintain high reliability: you appear higher in results, receive more WANT messages, earn more sats. Price too high or drop below the network's uptime norm: you receive fewer exchanges.

**The market self-regulates.** There is no protocol authority setting prices or allocating hosting contracts. Requesters choose their counterparties based on price and reliability. Popular content — content with many requesters — creates more AtomicSats revenue for hosts serving it, which attracts more hosts to cache and serve it, which increases availability and drives prices toward equilibrium. The same market mechanism that makes centralized CDNs efficient operates here without any central coordinator.

**Illustrative economics:**

| Capacity Served | Price | Monthly Revenue |
|---|---|---|
| 100 GB/month | 10 msats/KB | ~1,000,000 sats |
| 1 TB/month | 10 msats/KB | ~10,000,000 sats |
| 10 TB/month | 10 msats/KB | ~100,000,000 sats |

These are illustrative. Actual earnings depend on your pricing, the demand for content you serve, and your uptime score. Popular content served reliably earns more. Hosts who cache content that is in high demand — content with active LYWs funding host payments — will find their capacity utilized more consistently.

**Lightning channel capacity.** Hosts need sufficient inbound Lightning channel capacity to receive AtomicSats payments. This is a much lower bar than operating a Lightning routing node — you are receiving payments for block delivery, not routing third-party payments through your node. A modest channel balance is sufficient for a personal-scale host.

---

## Who Can Host

The protocol is designed for universal participation — the same mechanism works at every scale.

**Personal scale.** A dedicated home server or always-on personal computer with a Lightning node implementation and a content-addressed block store. Suitable for hosting a specific creator's content, serving a niche content library, or simply participating in the network's resilience with whatever spare capacity you have.

**Small operator scale.** A VPS or small dedicated server running full-time with meaningful storage and bandwidth. At this scale, hosting becomes a consistent income stream rather than a side contribution. Specializing in specific content types — academic datasets, media from a specific genre, software repositories — allows a small operator to become a reliable discovery result for that content category.

**Commercial scale.** Data centers with large storage capacity and high-bandwidth connections. At commercial scale, the AtomicSats exchange model rewards uptime and pricing discipline more than raw capacity. A commercial host that maintains a 99%+ uptime score and prices competitively will dominate discovery results for the content it serves. The protocol has no ceiling on scale.

---

## What You Need to Get Started

**An AtomicSats node implementation.** The reference implementation is the first deliverable of the IPFS-Sats development roadmap. Once available, running an AtomicSats host requires installing the node software, connecting it to a Lightning node implementation (LND or Core Lightning), and pointing it at a content-addressed block store.

**A Lightning node.** LND and Core Lightning are the two mature options. You likely already have one if you are active in the Lightning Network ecosystem.

**A content-addressed block store.** IPFS is the reference implementation. go-ipfs provides the block store interface directly. Any implementation that supports CID-based lookup and retrieval is conforming.

**A published Host Registry Record.** Once your node is running, you publish a Host Registry Record to the Records Database. This record — signed by your host DID, containing your Lightning endpoint, pricing policy, and block inventory — is what makes you discoverable. No Host Registry Record means no WANT messages. Publishing one is how you enter the market.

---

## The Broader Picture

Every host that joins the network increases the resilience of every piece of content stored on it. A content item served by ten hosts is harder to lose than one served by two. A content item served by a hundred hosts is cheaper to retrieve than one served by ten, because competition drives prices toward the efficient market rate.

The swarm delivery model means that popular content becomes more available and cheaper as demand increases — the inverse of centralized CDN economics, where popularity increases cost. You benefit from this too: hosting content that becomes popular means your capacity is utilized more, at potentially higher prices as demand initially outpaces supply.

You are not just earning sats. You are the infrastructure that makes the Right to Verify and the Right to Fork function in practice. Cryptographic proofs and smart contracts mean nothing if the content they reference is unavailable. Hosts are what make the protocol real.

---

## Where to Start

The white paper is at github.com/chadlupkes/IPFS-Sats. Section 3.5 covers the Host Discovery Layer. Section 3.6 covers the swarm delivery model and how host participation creates network effects. Section 10.7 covers the Host Registry Record schema — the record you will publish to enter the market.

The AtomicSats Protocol Specification in the repository covers the four-message handshake in detail. That is the protocol your node will implement.

When the reference implementation is available, it will be at the same repository. If you are a host operator who wants to be involved in testnet deployment, open an issue and say so.
