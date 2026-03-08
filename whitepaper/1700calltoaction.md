# 17. Getting Involved 📢

The IPFS-Sats protocol is released as a public good. There is no central development organization, no token sale, no foundation controlling access. The reference architecture is here. The specifications are here. What gets built from them depends entirely on who picks this up and what they build with it.

This section is an open invitation to the four participant types whose combined activity makes the protocol work. Each one's participation strengthens the incentives for all the others. The flywheel turns when all four are present.

The project repository is at github.com/chadlupkes/IPFS-Sats. That is where the conversation starts.

---

## 17.1 For Protocol Developers

The most important thing that needs to happen is a working implementation of the SatSwap node and the Records Database. Everything else — applications, creator tools, host software — depends on those two primitives existing and being reliable.

The core implementation work is well-defined. The SatSwap four-message handshake (Section 10.6) is a minimal, implementation-agnostic exchange protocol. A developer familiar with Go and the Lightning Network could implement a conforming SatSwap node in weeks, not months. The Records Database wire protocol (Section 10.2) is modeled on Nostr relay architecture with libp2p peer discovery — both are mature, well-documented reference implementations.

**What is needed:**
- A Go developer with Lightning Network and content-addressed storage experience to build the reference SatSwap node
- A Records Database node implementation conforming to the wire protocol in Section 10.2
- Metadata Wrapper tooling — command-line tools for creating, signing, anchoring, and querying content
- Protocol testnet infrastructure to validate that the economic loop closes end-to-end

This is foundational infrastructure work. The developer who builds the reference SatSwap implementation is writing the core economic plumbing of a system designed to outlast any platform built on top of it. The work is public, permanent, and attributable — and if the protocol's own Right to Fork mechanism is applied to the reference implementation itself, foundational contributors earn from every commercial deployment built on their work.

The Bitcoin and Lightning developer communities — including groups like Seattle BitDevs and contributors to the broader Bitcoin ecosystem — are the natural home for this conversation. If you are a developer who sees the architecture and wants to build it, the repository is open.

---

## 17.2 For Content Creators

Content creators are the participant type that proves the protocol works in the real world. A working SatSwap node and a correctly functioning LYW with real content earning real sats is the demonstration that matters — more than any white paper, more than any roadmap.

**What the protocol gives creators:**
- **Censorship-resistant hosting** — content is served by a decentralized swarm of hosts, each earning sats per block delivered. No platform can deplatform content that any host can serve.
- **Bitcoin timestamping** — every Metadata Bundle is anchored to Bitcoin via OP_RETURN, providing permanent, globally verifiable proof of existence and authorship without any institution's cooperation
- **Direct monetization** — zaps, access fees, and fork royalties flow directly to the creator's LYW. No platform intermediary. No transaction fee beyond standard Lightning routing costs.
- **Perpetual persistence** — the LYW generates Lightning liquidity yield that funds host payments automatically. Content persists as long as the LYW balance supports it, without ongoing manual payment.
- **The LYW as a personal economic instrument** — a creator can hash any document, fund a LYW, and that LYW immediately begins generating Lightning yield. The content doesn't need to be commercially accessed. The yield runs on the LYW's Lightning liquidity participation alone. This is a savings account, a timestamping service, a persistence engine, and a programmable distribution instrument — simultaneously, for any content, at any scale.

Early creators who publish content and initialize LYWs during the testnet phase are doing more than testing the protocol. They are demonstrating the economic model to every developer, host, and application builder watching. The creator who earns the first real sat through a SatSwap exchange is the proof of concept the entire ecosystem is waiting for.

Community feedback from creators is actively sought — through the project repository, through Nostr, and through the Bitcoin developer community. The protocol's feature set should be shaped by the people who will use it, not designed in isolation.

---

## 17.3 For Hosts

Hosts are the supply side of the delivery network. Without hosts serving blocks, there is no content retrieval. Without content retrieval, there is no SatSwap revenue. The host network is the physical infrastructure on which everything else depends.

**What hosting requires:**
- A SatSwap node implementation (Phase 1 deliverable from Section 14)
- A Lightning node with sufficient channel capacity to handle SatSwap payment flows
- Storage capacity for the blocks the host chooses to serve
- A published Host Registry Record in the Records Database advertising inventory, pricing, and performance metrics

**What hosting earns:**
Hosts earn sats per block delivered via SatSwap exchange completions. Payment is atomic with delivery — the HTLC settles when the preimage is revealed, simultaneously confirming delivery and releasing payment. There is no separate verification step, no proof-of-storage challenge, no staking requirement. Serve a valid block, receive payment. The economic model is as simple as the exchange primitive.

The host pricing market self-regulates through the Host Discovery Layer. Hosts that price competitively and maintain high uptime scores appear higher in discovery results and receive more WANT messages. Hosts that price too high or maintain poor reliability receive fewer exchanges and earn less. The market signal is direct and immediate.

**Who can host:**
The architecture accommodates hosts at every scale — from a personal server running on home broadband to institutional-grade infrastructure serving petabytes of high-demand content. A host that serves a single piece of content for a single creator is a valid, earning participant. There is no minimum scale requirement. The network's resilience comes from the aggregate of many participants, not from any single large operator.

---

## 17.4 For Application Developers

The protocol provides the backend. Application developers build the experiences through which creators and users interact with it. The protocol API (Section 12) is the interface surface — everything above it is an application-layer decision.

**What the protocol enables applications to build:**
- Decentralized media platforms where creators publish directly and earn per access without platform intermediaries
- Provenance explorers and attribution chain visualizers built on the transparent Anchor Records table
- Rights management dashboards querying fork royalty flows across entire content lineages
- Immutable document repositories with Bitcoin timestamping for legal, academic, and journalistic use cases
- Host reputation and network health monitoring tools built on the public Host Registry Records table
- Content discovery engines querying the Records Database by creator DID, license type, tags, or any other Metadata Wrapper field
- Per-Content DAO governance interfaces for managing membership, voting, and yield distribution

Any application that needs permanent content identity, Bitcoin-verified provenance, direct micropayment monetization, or decentralized governance for digital content can be built on IPFS-Sats. The protocol does not compete with applications built on it — it has no application-layer functionality of its own. Every useful experience is an opportunity for an application developer.

The reference applications described in Section 14.2 — a decentralized media platform and an immutable document repository — will be open-sourced as blueprints. Application developers who want to build in a specific vertical before those reference implementations exist are encouraged to engage through the project repository. The protocol specifications are complete enough to build against now.

---

*The project repository is at github.com/chadlupkes/IPFS-Sats. Pull requests, issues, and forks are welcome. The protocol is released as a public good — what it becomes depends on what the community builds with it.*
