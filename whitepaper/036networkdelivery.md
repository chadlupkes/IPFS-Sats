# 3.6 Network Delivery: The Swarm Model

## The Delivery Topology Is Discovered, Not Assumed

SatSwap does not prescribe how many hosts serve a given piece of content. It prescribes how a client pays a host for a block. The number of hosts involved in any given delivery — and therefore the complexity of the payment flow — is determined entirely by what the Host Discovery Layer returns.

This means the network topology for content delivery is not a design choice. It is an outcome.

When the discovery layer returns one host holding all blocks for a CID, the delivery is direct and the payment is singular. When the discovery layer returns multiple hosts each holding a subset of blocks, the delivery becomes a coordinated swarm and the payment fans out accordingly. The exchange protocol handles both cases with the same four-message handshake (Section 10.6). What changes is how many times that handshake executes in parallel.

---

## 3.6.1 The Simple Case: Single-Host Delivery

The simplest delivery topology arises when one host holds the complete Merkle tree for a requested CID.

In this case:

1. The client queries the discovery layer with the CID
2. Discovery returns a single host holding all blocks
3. The client initiates a SatSwap exchange with that host
4. The host delivers all blocks; the client verifies the root CID matches
5. The host receives full payment

This is the baseline. It requires no coordination between hosts, no block assembly across sources, and no split payment logic. It is functionally identical to a conventional file download, except that payment is atomic and trustless.

The simple case is common for small files, frequently requested content held by well-resourced hosts, and content that has been fully cached by a single node. It is not a degenerate edge case — for a significant portion of requests, this is the expected path.

---

## 3.6.2 The Swarm Case: Multi-Host Delivery

The more complex topology arises when no single host holds all blocks for a CID. This occurs naturally with:

- Large files (a feature film, a dataset, a software archive) where the block count is high and distribution across hosts is uneven
- Recently published content where propagation across the network is incomplete
- Distributed query result sets assembled from data held by multiple independent nodes
- Long-tail content where individual hosts have cached partial subsets based on prior retrieval patterns

In this case, the discovery layer returns a map: which hosts hold which blocks. The client — or a coordinating SatSwap node acting on the client's behalf — uses this map to route block requests to the appropriate hosts simultaneously.

The delivery becomes a swarm: multiple hosts serving their respective portions of the block set in parallel, with the client assembling the complete file from the incoming streams. The Merkle tree structure of the CID provides the assembly map and the integrity check — each block's hash is known in advance, so the client can verify each piece as it arrives and detect any missing or corrupted blocks immediately.

Payment is issued independently to each contributing host, proportional to the blocks each delivered. A host that provides 30% of the blocks for a retrieval receives 30% of the total payment. No host receives payment for blocks it did not deliver.

---

## 3.6.3 Intermediate Nodes and the Spread

A SatSwap node does not need to hold a block locally to participate in its delivery. A node that does not hold a block can proxy the request to a node that does, forwarding the block downstream and collecting a spread — the difference between what it charges the downstream client and what it pays the upstream host.

This creates a routing economy analogous to Lightning Network payment routing, applied to data delivery. Intermediate nodes earn by connecting buyers to sellers they cannot reach directly. The spread is their margin for providing that connectivity.

This has a direct consequence for network formation: well-connected nodes with low latency and accurate knowledge of the discovery layer become valuable routing intermediaries. They do not need large storage capacity. They need good connectivity, current discovery data, and efficient routing logic.

The spread mechanism means that participation in SatSwap delivery is not limited to storage operators. Any Lightning node with sufficient connectivity and the SatSwap protocol stack is a potential participant in the delivery economy.

---

## 3.6.4 Caching as a Capital Decision

When a SatSwap node observes that a particular CID is generating high query volume through the discovery layer, caching those blocks locally converts a routing margin into a full delivery payment.

A node that proxies requests for a popular CID earns the spread on each delivery. The same node that caches those blocks earns the full per-block payment. The difference between spread and full payment, multiplied across high request volume, is the economic signal that drives caching decisions.

No central policy determines what gets cached. No administrator assigns caching responsibilities. The sats optimize the cache automatically: nodes cache content when doing so increases their revenue, and stop caching content when demand falls below the threshold that justifies the storage cost.

The result is a network where popular content propagates toward the edge — closer to the users requesting it — driven entirely by economic incentive. Frequently requested blocks become widely replicated. Rarely requested blocks remain on fewer, deeper nodes. The distribution of content across the network reflects actual demand, not administrative planning.

This is the same principle that drives content delivery network behavior in centralized infrastructure, implemented here without a central operator.

---

## 3.6.5 Block Assembly and Integrity Verification

Regardless of how many hosts contribute to a delivery, the client assembles the complete file and verifies it against the root CID.

The Merkle tree structure of content-addressed data makes this verification straightforward:

- Each block has a known hash, derived from its content
- The root CID is derived from the hashes of all constituent blocks
- Any missing block leaves the root hash unresolvable
- Any corrupted block produces a hash mismatch detectable before payment settles

A block that fails verification triggers a failed payment for that block and a retry from an alternate host if one is available in the discovery results. The atomic nature of the SatSwap exchange ensures that a host cannot receive payment for a block the client cannot verify.

This means the integrity guarantee of the delivery does not depend on trusting any individual host. It depends on the mathematics of the Merkle tree structure and the atomicity of the payment protocol — both of which hold regardless of how many hosts participate in the swarm.

---

## 3.6.6 Delivery Topology as an Emergent Property

The swarm model is not a mode the protocol enters. It is the natural behavior of the protocol when discovery returns more than one host.

A network with one host holding a complete CID delivers directly. A network with partial distribution delivers via swarm. A network with high caching density delivers via whichever nearby node holds the blocks. The protocol does not need to distinguish between these cases explicitly — the exchange handshake is the same in all of them. The topology emerges from the discovery result and the economics of individual node behavior.

This is the design property the protocol is built to preserve: define the exchange primitive, let the network topology emerge from the incentives. The swarm is not engineered. It is grown.

---

## Summary

SatSwap delivery topology is determined by the Host Discovery Layer, not prescribed by the protocol. A single host holding a complete block set delivers directly and receives full payment. When no single host holds all blocks, multiple hosts serve their respective portions simultaneously, with payment distributed proportionally. Intermediate nodes can proxy blocks they do not hold locally, earning the spread between upstream and downstream prices. Caching popular blocks converts spread income into full delivery income, driving organic replication of high-demand content toward the network edge without central coordination. In all cases, the Merkle tree structure of content-addressed data provides assembly guidance and integrity verification, and the atomic SatSwap handshake ensures no host receives payment for a block the client cannot verify.
