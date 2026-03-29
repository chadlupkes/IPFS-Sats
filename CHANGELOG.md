# IPFS-Sats Changelog

All notable changes to the IPFS-Sats protocol white paper are documented here. Entries describe the evolution of the protocol specification from initial concept through the current version.

Repository: [github.com/chadlupkes/IPFS-Sats](https://github.com/chadlupkes/IPFS-Sats)

---

## v0.4.1 — Terminology Migration: SatSwap → AtomicSats

The exchange primitive previously named "SatSwap" throughout the protocol is renamed to "AtomicSats" in all documents and repository files. This change was required because "SatSwap" is a registered trademark belonging to another project, a conflict that was not identified during v0.4 drafting. No architectural, structural, or substantive changes accompany the rename. The four-message handshake, message field definitions, specification section numbering, and all other protocol content remain identical to v0.4.

Bitcoin-anchored via OpenTimestamps at block 942,688.

---

## v0.4 — Major Revision: The Protocol Becomes Implementable

v0.4 is a ground-up rewrite that transforms the white paper from a conceptual architecture document into a protocol specification that a developer could build against. The document grew from ~7,350 lines to ~11,100, but the increase reflects architectural depth rather than bulk — the prose is significantly tighter and more disciplined, with editorial artifacts, working notes, and speculative material eliminated.

**The Layered Stack.** The most visible structural change is the introduction of an explicit, ordered protocol stack presented as a continuous narrative at the opening of the Technical Architecture section. Each layer has a single responsibility, depends only on layers beneath it, and is described in terms of what it does, why it exists at that position, and how data and value flow through it. The stack, from bottom to top: Content Hashing → Metadata Bundle → Bitcoin/Lightning (economic and timestamping layer) → SatSwap (exchange primitive) → Host Discovery → Swarm Delivery (emergent, not a protocol layer) → Per-Content DAO Governance. This ordering was implicit in v0.3 but never stated. In v0.4 it becomes the organizing principle of the entire document.

**SatSwap: The Named Exchange Primitive.** The atomic block-for-sats exchange — previously described in general terms across multiple sections — is extracted, named, and specified as a standalone primitive. SatSwap is defined as a minimal four-message handshake: WANT → QUOTE → PAYMENT_HASH → BLOCK. The specification (Section 10.6) defines each message's fields, failure handling, and timeout behavior. Critically, SatSwap is role-agnostic and stateless: the same handshake serves end-client retrieval, intermediate node proxying, and swarm delivery without modification. The handshake is the protocol's atomic unit — every data transfer in the system is composed of SatSwap exchanges.

**Host Discovery Layer (Section 3.5).** A new protocol layer filling the gap between "SatSwap defines how to exchange" and "but how does a client find a host?" The layer is explicitly positioned above SatSwap and below the application, with the separation described as "load-bearing" — discovery defines the market, exchange defines the trade. The layer is backed by the Records Database and answers the primitive query: given CID X, return hosts, Lightning endpoints, and prices.

**Records Database Specification (Section 10.2).** A full distributed database specification for three tables: Host Registry Records (mutable, advertising host inventory and pricing), Anchor Records (append-only, linking Metadata Bundle CIDs to Bitcoin timestamps), and Content Flag Records (append-only, storing accountability signals). The spec defines design principles (permissionless writes, eventual consistency, schema-only gatekeeping), a node participation model with full/partial/query-only tiers, bootstrap and peer discovery, a wire protocol, a replication model, conflict resolution, and the relationship to existing implementations (Nostr relays, IPFS routing, BitTorrent DHT). This is entirely new — v0.3 referenced "decentralized indexes" without specifying them.

**Swarm Delivery as Emergent Behavior (Section 3.6).** Multi-host content delivery is reframed not as a separate protocol mode but as what naturally happens when the discovery and exchange layers operate together. The section walks through single-host delivery, multi-host swarm assembly, intermediate node routing with spread economics, and caching as a capital decision driven by the gap between routing margin and full delivery payment. The key insight — that popular content propagates toward the edge through economic incentive alone, with no central caching policy — is stated explicitly for the first time.

**Competitive Economics Analysis (Section 3.7).** An honest structural comparison of SatSwap economics versus centralized cloud storage. The section identifies where centralized storage retains durable advantages (cold storage, operational simplicity, latency consistency) and where SatSwap creates structural advantages centralized systems cannot replicate (no organizational overhead, censorship resistance, popularity reducing rather than increasing cost, aligned incentives). The analysis explicitly caveats that these are reasoned hypotheses, not proven outcomes — the network must be built first.

**Protocol Economics (Section 15).** A new section documenting four distinct value flows: the LYW Yield Loop (persistence from liquidity yield), the Access Income Loop (popularity compounding durability), the Host Payment Flow (direct payment for verified delivery), and the Fork Royalty Cascade (automatic upstream distribution through provenance chains). The section includes a formal argument for why there are no protocol-level fees — framed not as a gap but as the economic model itself.

**The LYW as Personal Economic Instrument (Section 15.3).** A significant conceptual expansion. The LYW is reframed as simultaneously four things: a savings account with yield, a timestamping service, a self-sustaining persistence engine, and a programmable inheritance mechanism. The section argues that the protocol does not distinguish between a song heard by millions and a private document read by no one — both initialize the same instrument, generate the same class of yield, and persist by the same mechanism.

**Host Registry Record Specification (Section 10.7).** A full record schema for hosts advertising their inventory at the individual block CID level, including field definitions, record lifecycle, and the boundary between protocol-layer records and application-layer extensions.

**Content Flagging Redesign.** The v0.3 content flagging system (Concern Flags triggered by Global Validators with specific flag IDs like 0x01, 0x02, 0x03) is replaced with a more principled design. Content Flag Records are now stored in the Records Database as the third table. The flag vocabulary is explicitly described as a "starting vocabulary, not a complete taxonomy," and applications are expected to extend or replace it. The confirmation mechanism is split into community confirmation and validator confirmation, with validator selection explicitly pushed to the application layer. A new "Why Harmful Use Is Structurally Unwise" argument replaces enforcement with transparency: every content CID carries a permanent, cryptographically verifiable identity and distribution trail that is queryable without centralized cooperation.

**Refined: Abstract.** Completely rewritten. The v0.3 abstract led with the protocol's innovations; v0.4 leads with the three crises, introduces each innovation as a direct resolution of a specific crisis, and names SatSwap explicitly as the primitive that connects them. The "public good" framing ("not a platform, not a company, and not a token") and the Living Civilization connection appear in the abstract for the first time.

**Refined: Implementation Roadmap.** The three phases are now anchored to concrete deliverables (SatSwap node, Records Database node, Metadata Wrapper CLI tools, Host Discovery query interface) rather than abstract goals. The flywheel model is retained but simplified.

**Added: Appendices.** A glossary (Appendix A), references (Appendix B), and a Frequently Asked Questions section (Appendix C) addressing common misconceptions: "IPFS-Sats requires IPFS specifically" (no — IPFS is the reference implementation), "the data is stored on the Bitcoin blockchain" (no — only a 32-byte hash), "the protocol is controlled by a central DAO" (no — governance is per-content), "IPFS-Sats introduces a new token" (no — sats are Bitcoin).

**Retained:** The Three-Key Architecture, V4V enterprise adaptation (cinema, streaming, transition roadmap), Per-Content DAO governance, Right to Verify, Right to Fork, IP management framework, and the Living Civilization conclusion all carry forward, with v0.4's tighter prose style applied throughout.

Bitcoin-anchored via OpenTimestamps at block 941,445.

---

## v0.3 — The First "Real" Version: Structural Discipline and Architectural Depth

v0.3 is where the white paper became a coherent protocol specification rather than an evolving draft. The document was substantially tightened — reduced from roughly 12,500 lines to 7,350 — with working notes, editorial artifacts, and redundant exposition removed. The core thesis (Right to Verify, Right to Fork, Living Civilization framing) remained unchanged from v0.2, but the technical architecture gained several major new components while the presentation became significantly more structured.

**New: Three-Key Architecture (Section 4.1).** The most significant architectural addition. Every piece of content now generates a 3-of-3 multi-signature wallet with role-based key separation: Key 1 (CID-derived, proves *what* — the content), Key 2 (creator/DAO control, proves *who* — the authority), and Key 3 (smart contract execution, proves *how* — the automation rules). This separation enables automated payments without requiring human consent for each transaction while preventing the automation layer from unilaterally changing governance. Key derivation pseudocode and recovery scenarios (Key 3 malfunction, Key 2 loss, worst-case) are specified.

**New: Creator Node Bootstrapping.** The cold-start problem is formally addressed. Every content CID is initially linked to the creator's own node as the first mandatory host, meaning the LYW balance can start at zero. Persistence bootstraps from the creator's intrinsic motivation before transitioning to market-compensated hosting as micropayments accumulate. Host selection logic is specified as a dual-layered mechanism balancing social/altruistic pinning with economic incentive gradients.

**New: Content Flagging Framework (Section 6.4).** A protocol-level content flagging system using Concern Flags triggered by Global Validator consensus. The design explicitly preserves content agnosticism — flags signal but do not delete. The protocol layer continues hosting but can suspend payouts; the application layer is expected to filter. Specific flag types are enumerated (malware, illegal content, spam) with graduated severity and protocol actions.

**New: RESTful API Specification (Section 12).** Formal endpoint definitions for content operations (upload, retrieve, verify, zap) and DAO governance operations (proposal, vote, execute), giving the protocol a concrete interface surface for the first time.

**New: Anti-Plagiarism Guardrails (Section 3.2.8).** A five-layer cryptographic verification model is laid out — content integrity, temporal proof, creator identity, provenance chain, and economic validity — with a worked theft-detection scenario showing how temporal ordering on the Bitcoin blockchain makes plagiarism automatically detectable.

**New: Economic Flywheel Model.** The implementation roadmap was restructured from v0.2's loose phasing into a three-phase, three-year plan explicitly organized around a six-component economic flywheel (investors, core devs, content creators, hosts, application devs, LYW providers). Each phase identifies which flywheel components it activates and why.

**Refined: Metadata Bundle and Data Structures.** The Core Content Object schema was cleaned up with clearer field separation. The `anchor_details` were externalized from the provenance section, which now exclusively tracks parent-child fork lineage. Required fields for valid anchoring are explicitly enumerated. The license object gained a `derivative_royalty` percentage field.

**Refined: LYW Economics.** Non-custodial liquidity leasing is now explicitly labeled as the primary income stream with specific platform references. The relationship between LYW runway health and host payment rates is more formally specified.

**Retained from v0.2:** The V4V enterprise adaptation sections (cinema, streaming, transition roadmap) survived largely intact. The Per-Content DAO governance structure, Right to Fork mechanics, IP management framework, and the "Why This Matters" Living Civilization conclusion all carried forward with editorial tightening but no fundamental changes.

**Removed:** The extensive v0.2 DAO governance voting mechanics (quadratic voting, conviction voting) were simplified. Some of the more speculative smart contract execution detail was condensed. The overall document reads less like an exploratory draft and more like a specification someone could begin implementing against.

---

## v0.2 — Philosophical Reframing and Protocol Deepening

v0.2 represents a fundamental reconception of the project. Where v0.1 was framed as a "Dual-Mechanism Protocol for Atomic Data Retrieval and Yield-Backed Persistence" — essentially a storage incentive layer bolted onto IPFS — v0.2 reframes the entire effort as "Foundational Infrastructure for the Right to Verify and Right to Fork." The project is no longer just about paying for storage. It is about establishing two foundational digital rights through cryptographic and economic infrastructure.

The problem statement was restructured accordingly. v0.1 organized its critique around data decay, free-riding, QoS degradation, and the limitations of Filecoin and Arweave. v0.2 consolidates these into three interconnected "crises" — verification (proving what existed when), innovation (compensating derivative works), and persistence (ensuring permanent availability) — and frames them as systemic failures rather than isolated technical shortcomings. The "Living Civilization" framing appears for the first time.

Several major architectural concepts were introduced:

The **Metadata Wrapper** is specified as a structured DAG-CBOR object with defined fields for content reference, timestamp proof, provenance chain, creator identity (via DIDs), DAO configuration, and licensing terms. The **Bundle Hash** — a SHA-256 hash of the content CID combined with the metadata — becomes the core cryptographic primitive anchored to Bitcoin via OP_RETURN.

**Per-Content DAO governance** is introduced as a central innovation. Rather than a single protocol-wide DAO, every piece of content gets its own governance structure, scaling from a single creator to millions of stakeholders. Governance weight is tied to income distribution ratios rather than a new token. The document specifies voting mechanisms (simple weighted, quadratic, conviction), proposal lifecycles, and smart contract execution rules.

The **Right to Fork** is formalized as an architectural principle: any content can serve as the foundation for derivative works, with parent-child CID linking creating immutable provenance trees and automatic royalty distribution flowing upstream through the fork chain. This replaces traditional IP exclusion models with attribution and automatic compensation.

The **Lightning Yield Wallet (LYW)** replaces v0.1's more general "yield-backed bounties" concept with a specific economic engine. Liquidity leasing is identified as the primary income stream, with detailed treatment of available platforms, yield calculations, and the relationship between LYW balance and content persistence lifespan.

A **Value-for-Value (V4V) enterprise adaptation** section was added, outlining how physical venues and streaming services could transition from gatekeeping to amplification models — earning voluntary zaps for enhancing experience rather than selling access.

The document was reorganized from v0.1's continuous flow into a multi-part structure (Foundation, Core Protocol, Protocol Specifications) with formal JSON schemas for data structures including the Core Content Object, Application Transaction Proof Object, and Mutable State Accounting Ledger.

Significantly, v0.1's extensive application-layer material was removed or reduced. The cross-platform app architecture (Electron, React Native, Docker), hardware-tiered configurations (mobile, desktop, cloud), server farm features, and the four-phase deployment roadmap are all gone. The specific use case sections (digital intelligence, government data, genealogy, climate science, medical data) were replaced by the V4V enterprise framework and the Right to Fork applications. The focus shifted decisively from "what the downloadable app looks like" to "what the protocol specifies."

This version was still rough — there are visible editorial artifacts (section numbering inconsistencies, working notes left in the governance section) — but it established the conceptual architecture that would be refined into the first "real" version in v0.3.

---

## v0.1 — Initial Concept (2025)

The first draft of IPFS-Sats laid out the core thesis: IPFS has the right architecture for a decentralized web but lacks the economic layer necessary to make it sustainable. Content disappears through garbage collection because no one is paid to keep it, free-riders consume bandwidth without contributing, and retrieval performance degrades without incentives to prioritize requests. Filecoin solved persistence but became an industrial-scale operation inaccessible to ordinary participants. Arweave solved permanence but with rigid, pay-once economics unsuitable for flexible use cases.

The v0.1 white paper proposed a "Dual-Mechanism Protocol" to address this — two interlocking systems built on the Bitcoin Lightning Network rather than a new token:

1. **Atomic Data Retrieval** — a pay-per-block model replacing BitSwap's broken reciprocity with Lightning invoice-conditioned transfers using HTLCs. Hosts generate invoices for each block; payment settles before data is released. No payment, no data.

2. **Yield-Backed Persistence Bounties** — uploaders fund time-bound pinning commitments, and hosts earn ongoing yields from Lightning routing fees and Bitcoin DeFi integrations for keeping content available, verified through periodic signed Merkle proofs.

The document also sketched a dynamic pricing engine with peer-to-peer rate signaling through DHT metadata, a cross-platform application architecture (Electron desktop, React Native mobile, Docker cloud), hardware-tiered configurations from mobile to server farm, and a four-phase deployment roadmap targeting testnet prototypes in Q4 2025 through mainnet launch in Q3 2026.

Use case sections covered digital intelligence, government data archival, public research, genealogy, climate science, cultural heritage, and medical data — establishing the breadth of the protocol's intended applicability.

This version was exploratory and ambitious in scope. It referenced specific market statistics, LN capacity figures, and Filecoin utilization numbers throughout, and proposed detailed implementation specifics (app store distribution, Prometheus monitoring, Kubernetes orchestration) alongside the core protocol concepts. The architectural vision was expansive but had not yet been distilled into the layered stack discipline that would emerge in later versions.
