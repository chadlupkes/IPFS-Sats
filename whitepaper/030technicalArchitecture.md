# PART II: CORE PROTOCOL (How It Works)

# 3. Technical Architecture

IPFS-Sats is built as a layered protocol stack. Each layer has a single, well-defined responsibility and depends only on the layers beneath it. This separation is deliberate: it keeps each layer simple enough to reason about independently, allows each layer to evolve without breaking the others, and ensures that application developers can build on the protocol without needing to understand every layer below their point of integration. The sections that follow describe each layer in turn, from the cryptographic foundation upward to the governance structure that manages rights and compensation.

---

## The Stack

**Content Hashing** is the foundation. Every piece of data in the protocol is identified by a Content Identifier (CID) — a cryptographic hash derived directly from the content itself. This primitive makes data tamper-evident, location-independent, and universally verifiable without reference to any authority. Nothing in the protocol above this layer is possible without it. IPFS is the reference implementation of a complete technology stack built on this primitive, providing the chunking, DAG construction, and retrieval mechanisms that turn raw content hashing into a functional storage and distribution system.

**The Metadata Bundle** sits directly above content addressing. A CID alone identifies data — it says nothing about who created it, when it existed, what rights apply to it, or how it connects to other works. The metadata bundle wraps a content CID with the information needed to transform a file into a complete digital asset: a Bitcoin-anchored timestamp proving existence at a specific point in time, a creator identity and signature, licensing terms, provenance links to parent works, and the economic infrastructure needed to fund its persistence. The metadata bundle is what makes the Right to Verify and the Right to Fork technically enforceable rather than merely aspirational.

**Bitcoin and the Lightning Network** provide the economic and timestamping layer. Bitcoin's proof-of-work consensus anchors metadata bundle CIDs to an immutable, globally verifiable timeline — the cost of falsifying a Bitcoin timestamp is prohibitive at any scale. The Lightning Network, built on Bitcoin, provides the payment infrastructure: instant, atomic, sub-cent micropayments that enable the SatSwap exchange, fund storage hosts through the Lightning Yield Wallet, and distribute royalties to creators and their upstream contributors without intermediaries.

**SatSwap** is the exchange primitive. It defines a minimal four-message handshake — WANT, QUOTE, PAYMENT_HASH, BLOCK — between any two nodes that wish to exchange a block of data for a Lightning micropayment. SatSwap is role-agnostic and stateless: it does not distinguish between a client requesting content and an intermediate node proxying a request, and it carries no memory between exchanges. Every data transfer in the protocol, regardless of topology, is composed of SatSwap exchanges.

**Host Discovery** sits above SatSwap. Before a requesting node can initiate an exchange, it needs to know which nodes hold the blocks it wants, at what price, and how to reach them for payment. The Host Discovery Layer is a decentralized database of Host Registry Records — declarations published by nodes advertising their inventory at the individual block CID level, their Lightning endpoints, and their current pricing. Discovery enables the requesting node to construct a complete delivery plan before the first WANT message is sent.

**Swarm Delivery** is not a separate protocol layer but an emergent property of the discovery and exchange layers operating together. When no single host holds all blocks for a requested file, the requesting node initiates parallel SatSwap exchanges with multiple hosts simultaneously — one per block, each independent. Intermediate nodes that hold some blocks but not others can proxy requests upstream, earning the spread between what they charge downstream and what they pay upstream. The result is a self-organizing delivery topology that routes around missing data, distributes load across the network, and propagates popular content toward the edge driven entirely by economic incentive.

**Per-Content DAO Governance** sits above the exchange and payment layers. Each piece of content has its own governance instance — a smart contract that manages membership, voting, licensing decisions, and the automated distribution of revenue to creators, upstream contributors, and storage providers. The DAO does not participate in the exchange or discovery layers; it operates on the economic output of those layers, receiving payment flows and distributing them according to rules set by the creator and enforced by code.

---

## How Data and Value Flow

A complete interaction — from a user requesting content to a creator receiving compensation — touches every layer. The user's application resolves the root CID of the requested content and queries the Host Discovery Layer, which returns a map of which hosts hold which blocks. The application constructs a delivery plan and initiates parallel SatSwap exchanges, one per block. Each exchange is atomic: the block is released only when the Lightning payment is confirmed. Assembled blocks are verified against the Merkle DAG, and the complete content is delivered to the user.

Value flows in the opposite direction. Payment for each block travels via Lightning to the delivering node. A portion flows upstream through any intermediate nodes that proxied the request, each earning their margin. A portion flows to the content's Lightning Yield Wallet, where it funds ongoing storage costs and generates yield for persistence. The DAO governance layer receives its share and distributes it automatically — to the creator, to upstream contributors in the provenance tree, and to stakers who funded the content's initial persistence deposit.

The sections that follow describe each layer in detail: how content is addressed and verified (3.1), how the metadata bundle is structured (3.2), how the Lightning economic layer operates (3.3), how per-content DAO governance is organized (3.4), how the Host Discovery Layer enables routing (3.5), how swarm delivery emerges from discovery and exchange (3.6), and how the economics of distributed storage compare to centralized alternatives (3.7).

