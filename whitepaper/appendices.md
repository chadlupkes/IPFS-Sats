# Appendices 📚

---

## Appendix A: Glossary

This glossary defines the canonical technical terms used throughout the IPFS-Sats 0.4 white paper. Where a term has been generalized from a specific implementation (such as IPFS or the Lightning Network), the definition reflects the protocol-agnostic framing used in 0.4.

### Core Protocol Terms

| Term | Definition |
|---|---|
| **Anchor Record** | A record in the Records Database that links a Metadata Bundle CID to the Bitcoin transaction containing its Bundle Hash via OP_RETURN. The Anchor Record is the verifiable proof that a specific Metadata Bundle existed at a specific Bitcoin block height. Schema defined in Section 10.8. |
| **Bundle Hash** | The cryptographic hash of the combination of a Content CID and its Metadata Wrapper — Hash(Content CID + Metadata Wrapper). The Bundle Hash is the single value committed to the Bitcoin blockchain via OP_RETURN, binding the content reference and its current governance rules into a single cryptographic commitment. |
| **Content CID** | A content-addressed identifier derived from the cryptographic hash of a content payload. Immutable by definition: any change to the content produces a different CID. Serves as both the address for retrieving data and proof of its integrity. |
| **Content Flag Record** | A record in the Records Database documenting a community concern about a specific Content CID. Append-only — flags accumulate. Any participant can submit a flag; confirmation follows a two-path process. Schema defined in Section 10.9. |
| **Content-Addressed Storage** | A storage model where data is identified by what it is — a cryptographic hash of its contents — rather than where it is stored. Content-addressed identifiers are tamper-evident: any change to the data produces a different identifier. IPFS is the reference implementation used in this white paper, but the protocol is not IPFS-specific. |
| **Decentralized Identifier (DID)** | A self-sovereign, cryptographically verifiable identity that does not depend on any centralized registry or authority. Used in IPFS-Sats to establish creator authorship within the Metadata Wrapper and to identify DAO members, hosts, and other protocol participants. |
| **Fork Provenance** | The set of fields in the Metadata Wrapper that encode a derivative work's relationship to its source — specifically the `parent_bundle_hash`, `derivative_type`, and `royalty_split` fields. Fork provenance is the data structure that implements the Right to Fork at the protocol layer. |
| **Host** | A network participant that stores content blocks and serves them via SatSwap exchanges, earning sats per block delivered. Hosts publish Host Registry Records to the Records Database to advertise their inventory, pricing, and performance metrics. |
| **Host Registry Record** | A record in the Records Database published by a SatSwap host to advertise its block inventory, pricing, Lightning endpoint, and performance metrics. The Host Discovery Layer's query function operates against this table. Schema defined in Section 10.7. |
| **Hashed Timelock Contract (HTLC)** | A cryptographic construct used by the Lightning Network to enable atomic exchanges. An HTLC locks a payment until the recipient reveals a cryptographic preimage, which the sender verifies before the payment settles. SatSwap uses HTLCs to enforce the atomicity of every block-for-sats exchange — no delivery, no payment; no payment, no delivery. |
| **Key 1 — Content Binding Key** | The constitutional authority layer of the three-key architecture. Key 1 binds the content to its creator identity and defines the governance constraints within which Key 2 and Key 3 operate. Key 1 configuration options range from solo creator to multi-sig to fully locked. |
| **Key 2 — Human Authority Key** | The governance layer of the three-key architecture. Key 2 represents the DAO's human decision-making capacity — the members who submit proposals, cast votes, and authorize significant changes to the content's operational parameters. |
| **Key 3 — Execution Key** | The automation layer of the three-key architecture. Key 3 executes governance decisions made by Key 2, distributes yield, pays hosts, and manages the LYW — all without requiring human action on every transaction. Key 3 executes; it does not decide. |
| **Lightning Yield Wallet (LYW)** | A Bitcoin Lightning wallet that generates passive income by deploying its balance into Lightning Network liquidity positions — channel leasing and routing fee generation. In IPFS-Sats, the LYW is the economic engine of content persistence: its yield funds host SatSwap payments, making content self-sustaining without ongoing manual funding. |
| **Metadata Bundle** | The combination of a Content CID and its associated Metadata Wrapper. Represents the full state of a piece of content — its immutable payload reference and its current governance rules — at a point in time. |
| **Metadata Wrapper** | The structured metadata document that encodes the economic, governance, and provenance rules for a piece of content. Governable: a successful DAO vote produces a new Metadata Wrapper. One of the two components of the Metadata Bundle. Schema defined in Section 10.1. |
| **Per-Content DAO** | A Decentralized Autonomous Organization initialized for a single piece of content. It manages governance, income distribution, licensing, and derivative work approval for that content object specifically, scaling from solo creator control to complex multi-stakeholder arrangements. |
| **Records Database** | The distributed, permissionless data layer underlying the Host Discovery Layer. Stores three tables: Host Registry Records, Anchor Records, and Content Flag Records. Fully transparent and publicly queryable — the foundation for application-layer discovery engines, provenance explorers, and analytics tools. Architecture defined in Section 10.2. |
| **Right to Fork** | The inalienable right of any individual, collective, or organization to copy, modify, and redeploy the governance code and protocols of any existing content operating on the IPFS-Sats protocol. Implemented through the fork provenance fields in the Metadata Wrapper and enforced by the Child DAO's smart contract upon receiving payment. |
| **Right to Verify** | The inalienable right of any participant to independently verify a piece of content against two distinct proofs: a Bitcoin timestamp proof confirming when the content existed, and a Lightning availability proof confirming it is currently retrievable. The protocol makes this right technically unrevocable. |
| **SatSwap** | The atomic block-for-sats exchange primitive of the IPFS-Sats protocol. A four-message handshake — WANT, QUOTE, PAYMENT_HASH, BLOCK — between any two nodes. Analogous to BitSwap but replacing reciprocal block exchange with direct Lightning micropayment. The atomicity of every exchange is enforced by the Lightning Network's HTLC mechanism. |

### Units and Acronyms

| Term | Definition |
|---|---|
| **sats (satoshis)** | The base unit of Bitcoin. 1 sat = 0.00000001 BTC. All SatSwap prices, LYW balances, and protocol payments are denominated in sats or millisatoshis (msats). Sats are not a protocol token — they are Bitcoin. |
| **msats (millisatoshis)** | One thousandth of a satoshi. The unit used for SatSwap pricing in the exchange protocol, enabling fine-grained per-block pricing below one satoshi. |
| **CID** | Content Identifier. The content-addressed hash that serves as both the address and the integrity proof for any block or document in the protocol. |
| **DAO** | Decentralized Autonomous Organization. In IPFS-Sats, always Per-Content — each piece of content has its own independent DAO. |
| **DID** | Decentralized Identifier. See definition above. |
| **HTLC** | Hashed Timelock Contract. See definition above. |
| **LYW** | Lightning Yield Wallet. See definition above. |
| **OP_RETURN** | A Bitcoin transaction opcode that allows a small amount of arbitrary data (up to 83 bytes) to be embedded in a provably unspendable transaction output. IPFS-Sats uses OP_RETURN to commit Bundle Hashes to the Bitcoin blockchain, creating permanent, globally verifiable timestamps at near-zero marginal cost. |

---

## Appendix B: References

### Foundational Protocols

**Bitcoin**
Nakamoto, Satoshi. *Bitcoin: A Peer-to-Peer Electronic Cash System.* 2008.
https://bitcoin.org/bitcoin.pdf

**Lightning Network**
Poon, Joseph, and Thaddeus Dryja. *The Bitcoin Lightning Network: Scalable Off-Chain Instant Payments.* 2016.
https://lightning.network/lightning-network-paper.pdf

**BOLT11 — Lightning Invoice Standard**
The standard wire format for Lightning Network payment requests used in SatSwap QUOTE messages.
https://github.com/lightning/bolts/blob/master/11-payment-encoding.md

**Content Addressing and IPFS**
Benet, Juan. *IPFS — Content Addressed, Versioned, P2P File System.* 2014.
https://ipfs.io/ipfs/QmR7GSQM93Cx5eAg6a6yRzNde1FQv7uL6X1o4k7zrJa3LX/ipfs.draft3.pdf

**CID Specification**
The Multiformats Project. *Self-describing content-addressed identifiers for distributed systems.*
https://github.com/multiformats/cid

### Records Database Reference Implementations

**Nostr Protocol (NIPs 01 and 11)**
The schema-validated, gossip-replicated relay architecture that the Records Database wire protocol is modeled on.
https://github.com/nostr-protocol/nostr

**libp2p Kademlia DHT**
The peer discovery and distributed hash table implementation used by IPFS, referenced as the production-grade DHT model for Records Database node discovery.
https://github.com/libp2p/specs/tree/master/kad-dht

**OrbitDB**
A distributed database built on IPFS and libp2p supporting append-log and key-value store patterns directly matching the Records Database table requirements.
https://github.com/orbitdb/orbitdb

**BitTorrent DHT (BEP 5)**
The bootstrap and peer discovery mechanism referenced for the Records Database seed list and DHT bootstrap sequence.
https://www.bittorrent.org/beps/bep_0005.html

### Bitcoin Timestamping

**OpenTimestamps**
The most mature production implementation of Bitcoin-based document timestamping. The closest existing implementation to the Anchor Record mechanism.
https://opentimestamps.org

**Bitcoin OP_RETURN Standard**
The Bitcoin opcode used to embed Bundle Hashes into transactions. Limited to 83 bytes of data per output. Outputs are provably unspendable and prunable by full nodes, making them near-zero-cost permanent records.
https://en.bitcoin.it/wiki/OP_RETURN

### Related Storage Protocols

**Storj**
The closest comparable decentralized storage network to IPFS-Sats in economic model — incentivized hosts, distributed storage, content retrieval. Key distinction: Storj uses a proprietary token (STORJ) rather than Bitcoin. Demonstrates the market viability of the incentivized storage model.
https://storj.io

**Filecoin**
Addresses persistence using cryptographic proofs (Proof-of-Spacetime) but operates at industrial scale with a proprietary token and lacks native integration with content retrieval incentives.
https://filecoin.io

**Arweave**
Provides one-time permanent storage funded by an endowment model. Lacks native retrieval incentives and flexibility for dynamic governance. Demonstrates the demand for permanent content archival.
https://www.arweave.org

---

## Appendix C: Frequently Asked Questions

### About the Protocol

**What is SatSwap and how is it different from BitSwap?**
BitSwap is the block exchange protocol used by IPFS. It operates on a reciprocity model — nodes exchange blocks with each other, and nodes that don't share get deprioritized. SatSwap replaces reciprocity with direct payment: a requesting node pays sats for every block it receives, and a delivering node earns sats for every block it delivers. This eliminates free-riding structurally — there is no incentive to consume without contributing because consumption requires payment, and contribution is directly rewarded.

**How does the LYW generate yield?**
The Lightning Yield Wallet deploys its sats balance into Lightning Network liquidity positions — channel leasing and routing fee generation. Other Lightning participants pay fees to lease channel capacity from the LYW, and the LYW earns routing fees when payments flow through its channels. This yield is generated by the LYW's participation in Lightning Network infrastructure, independent of whether the associated content is ever accessed. A LYW with sufficient balance can sustain content persistence indefinitely through yield alone.

**What happens to content when the LYW balance runs low?**
The protocol has a graceful degradation mechanism. When the LYW balance drops below the hosting cost threshold, the `drawdown_mode` flag activates and host SatSwap payments are suspended. The remaining balance continues to distribute yield to DAO members only. The content may become less available as hosts that are no longer receiving payment stop serving it — but no debt is incurred and no abrupt shutdown occurs. If the balance recovers — through new access income, a zap from a supporter, or a fork royalty inflow — `drawdown_mode` deactivates automatically and host payments resume. If the balance remains below threshold for the duration configured in the `sunset_condition`, the DAO executes its archival action — typically releasing the content to the public domain.

**Why use Bitcoin and Lightning rather than a new token or a different blockchain?**
Bitcoin provides the most secure, most widely trusted timestamping layer available. An OP_RETURN commitment to the Bitcoin blockchain is verifiable by anyone with a Bitcoin node — no protocol-specific infrastructure required. The Lightning Network provides instant, trustless micropayments at the millisatoshi level necessary for per-block pricing. Both are production-proven at scale. A new token would introduce speculative volatility into what should be a stable economic primitive, and would fragment liquidity away from the deepest, most liquid monetary network available.

**Is IPFS-Sats a new blockchain?**
No. IPFS-Sats is a protocol layer built on top of existing infrastructure — content-addressed storage (IPFS as the reference implementation) and Bitcoin's Lightning Network. It uses the Bitcoin blockchain only for high-security timestamp anchoring via OP_RETURN, not as a general data storage or consensus layer. The actual content is stored by hosts on the content-addressed network. The protocol introduces no new consensus mechanism, no new token, and no new chain.

---

### About Content and Creators

**Can I use IPFS-Sats for private content?**
Yes. The protocol is content-agnostic. A creator can hash any document — a private journal, a legal agreement, a personal photo — fund a LYW, and that LYW immediately begins generating Lightning yield. The content does not need to be publicly accessible or commercially valuable for the LYW to function. Access controls are an application-layer decision: a creator can publish a Metadata Wrapper with a license that restricts access and configure their DAO to only route payments to authorized requesters.

**How does the protocol prevent plagiarism and content theft?**
The Bitcoin timestamp in the Anchor Record establishes when a specific Metadata Bundle existed. If two parties claim authorship of the same content, the Anchor Records table will show which Bundle Hash appeared in an earlier Bitcoin block — that party has cryptographic proof of priority. The earlier timestamp cannot be forged: the Bitcoin blockchain is immutable and globally verifiable. A plagiarist who uploads stolen content after the original creator will always have a later timestamp, which any participant can verify independently by querying the Anchor Records table and checking the referenced Bitcoin transaction.

**What is the Right to Fork and how is royalty payment enforced?**
The Right to Fork is the inalienable right to copy, modify, and redeploy any content or governance structure on the protocol. When a creator publishes a derivative work, they encode the `parent_bundle_hash` and their chosen `upstream_percentage` in the `fork_provenance` fields of their Metadata Wrapper. When the Child DAO receives payment — from any source — its smart contract automatically routes the upstream percentage to the Parent content's LYW address before distributing the remainder to the Child's own members. Enforcement is not by legal contract or platform policy; it is by the Child DAO's own governance code executing automatically upon receipt of payment.

---

### About Misconceptions

**"IPFS-Sats requires IPFS specifically."**
IPFS is the reference implementation used throughout this white paper because it is the most mature content-addressed storage system available. The protocol's core primitive is content-addressed storage — data identified by the cryptographic hash of its contents. Any system that implements this property can serve as the storage layer. IPFS is where a developer should start; it is not the only valid implementation.

**"The data is stored on the Bitcoin blockchain."**
Only a tiny cryptographic hash — the Bundle Hash, 32 bytes — is recorded on the Bitcoin blockchain via OP_RETURN. This hash represents the content's existence and integrity at a specific moment in time. The actual content is stored by hosts on the content-addressed network and retrieved via SatSwap exchanges. The Bitcoin blockchain is the timestamping layer, not the storage layer.

**"The protocol is controlled by a central DAO."**
Governance in IPFS-Sats is entirely Per-Content. Each piece of content has its own independent DAO configured by its creator. There is no protocol-level DAO, no central treasury, and no governing body that controls the protocol's parameters. The protocol is released as a public good — like Bitcoin, it has no owner and no controller. Individual Per-Content DAOs govern their own content according to the rules their creators configure.

**"IPFS-Sats introduces a new token."**
The protocol uses sats — Bitcoin — as its unit of account. Sats are not a protocol token; they are the base unit of the most established monetary network in existence. There is no IPFS-Sats token, no token sale, and no tokenomics. Every economic relationship in the protocol is denominated in sats and settled over the Lightning Network.
