# IPFS-Sats
## Foundational Infrastructure for the Right to Verify and the Right to Fork

IPFS-Sats is a protocol that combines CID-based content addressing, Bitcoin blockchain timestamping, Lightning Network micropayments, and per-content DAO governance to create trustless, self-sustaining infrastructure for permanent content availability and fair creator compensation. It is released as a public good — no company, no token, no central authority.

---

## The Problem

The decentralized web faces three interconnected crises that no existing protocol has solved simultaneously.

**The Verification Crisis.** There is no universal, trustless mechanism to prove what existed when. Truth has become a matter of institutional authority — who controls the servers, the timestamps, the archives. Deepfakes, AI-generated content, and platform-controlled historical records have made provable truth effectively unavailable to individuals and small organizations.

**The Persistence Crisis.** Distributed storage without native economic incentives degrades rapidly. Studies show over 90% of IPFS content becomes unreachable within six months. Without payment for storage, node operators have no reason to keep data alive. Users are forced back to centralized pinning services that reintroduce subscription dependency, censorship risk, and single points of failure — everything IPFS was designed to eliminate.

**The Innovation Crisis.** Derivative works generate no automatic compensation for foundational contributors. Open-source developers, researchers, and creative commons contributors bear the cost of producing foundational work while the value flows entirely to those who build on top of it. The result is a structural underfunding of the knowledge layer that every application depends on.

---

## Why Existing Solutions Fall Short

**Centralized pinning services** (Pinata, Infura) restore the trust model IPFS was designed to eliminate. Persistence is guaranteed by a billing contract with a vendor, not by a protocol mechanism. Vendors can censor, deplatform, or shut down.

**Filecoin** addresses persistence through cryptographic proofs but imposes industrial-scale barriers — specialized hardware, FIL token collateral, complex deal-making — and operates adjacent to the retrieval layer rather than integrated into it. It solves permanence at the cost of accessibility.

**Arweave** provides one-time permanent storage but offers no flexibility for dynamic data, no native retrieval incentives, and high upfront costs that prohibit casual use.

**Storj** is the closest comparable in economic model — incentivized hosts, distributed storage — but uses a proprietary token rather than Bitcoin, fragmenting liquidity away from the most established monetary network available.

None of these solutions address all three crises. None provide cryptographic timestamping, self-sustaining persistence economics, and automated creator compensation in a single accessible protocol.

---

## The IPFS-Sats Solution

IPFS-Sats resolves all three crises through four integrated components.

**SatSwap — Atomic Block-for-Sats Exchange**

SatSwap is the protocol's foundational exchange primitive. Any node can request any content block. Any host can serve it. Payment settles atomically with delivery via Lightning HTLC — the block is released only when payment confirms, and payment returns if the block is not delivered. The exchange is the verification step: a host that delivers a valid block has proven it holds the block. No separate proof-of-storage mechanism. No trusted intermediary. No free-riding.

SatSwap replaces BitSwap's reciprocity model — which fails in practice because nodes consume data without contributing — with direct bilateral payment. Serve a block, earn sats. Stop serving, earn nothing. The economic gradient enforces availability without commanding it.

**Bitcoin Timestamping via Records Database**

Every Metadata Bundle — the combination of a content identifier and its governance rules — is committed to the Bitcoin blockchain as a Bundle Hash via OP_RETURN. This creates a permanent, globally verifiable proof of existence anchored to Bitcoin block height, verifiable by anyone with a Bitcoin node, requiring no protocol-specific infrastructure.

These commitments are recorded in a distributed, permissionless Records Database alongside Host Registry Records and Content Flag Records — a fully transparent, publicly queryable discovery and provenance layer. Anyone can query which hosts serve a given block, when a piece of content was anchored to Bitcoin, and the full fork provenance chain of any derivative work.

**Lightning Yield Wallet — Self-Sustaining Persistence**

A Lightning Yield Wallet bonded to each piece of content generates passive income through Lightning Network liquidity participation — routing fees and channel leasing. That yield automatically funds SatSwap payments to hosts, making content persistence self-sustaining without ongoing manual funding, subscription payments, or platform dependency.

The LYW is simultaneously a savings account with yield built in, a Bitcoin timestamping service, a self-sustaining persistence engine, and a programmable distribution instrument. A creator can hash any document — a research dataset, a family archive, a legal agreement — fund a LYW, and that LYW begins generating Lightning yield immediately, independent of whether the content is ever commercially accessed.

**Per-Content DAO — Automated Attribution and Compensation**

Each piece of content has its own Per-Content DAO, structured around a three-key architecture: a Content Binding Key establishing creator authority and governance constraints, a Human Authority Key representing the DAO's voting membership, and an Execution Key automating revenue distribution, host payments, and fork royalty routing without requiring human action on every transaction.

When a derivative work is created, the fork relationship is encoded in the Metadata Bundle's provenance fields. When the child DAO receives payment — from any source — its smart contract automatically routes the upstream royalty percentage to the parent content's LYW address before distributing the remainder to its own members. Attribution and compensation are enforced by code, not legal contract, not platform policy, not goodwill.

---

## What's in This Repository

**White Paper** — The complete protocol specification for IPFS-Sats v0.4. Organized in five parts:
- <a href="whitepaper/01abstract.md">Part 1</a>: Foundation — Abstract, the three crises, requirements for a native solution
- <a href="whitepaper/03technicalArchitecture.md">Part 2</a>: Technical Architecture — Content addressing, Metadata Bundle, economic layer, DAO governance, host discovery, swarm delivery, competitive economics
- <a href="whitepaper/041threeKeyArchitecture.md">Part 3</a>: Rights Infrastructure — Three-key architecture, LYW economics, DAO governance operations, Right to Verify, Right to Fork, IP management
- <a href="whitepaper/1010corecontent.md">Part 4</a>: Protocol Specifications — All schemas: Metadata Wrapper, Records Database, DAO Configuration, Fork Relationships, LYW State Ledger, SatSwap exchange messages, Host Registry Records, Anchor Records, Content Flag Records; Smart Contract Operations, API Specifications
- <a href="whitepaper/1300usecases.md">Part 5</a>: Ecosystem — Use Cases, Implementation Roadmap, Economic Model, Why This Matters, Getting Involved

**Use Cases** — Extended use case documentation across creator monetization, academic and research, legal and evidentiary, open-source software, journalism, archival, and enterprise applications.

**SatSwap Specification** — The four-message handshake protocol (WANT, QUOTE, PAYMENT_HASH, BLOCK) in standalone reference format for implementers.

---

## Who This Is For

**Protocol Developers** — The most important immediate need is a Go developer with Lightning Network and content-addressed storage experience to build the reference SatSwap node and Records Database implementation. The SatSwap four-message handshake is minimal and well-defined. A conforming implementation is weeks of work, not months. See the white paper Part 4 for complete specifications.

**Content Creators** — Publish content, initialize a LYW, and earn sats directly through access payments, zaps, and fork royalties — without platform intermediaries. Early creators who demonstrate the economic loop closing are the proof of concept the ecosystem needs.

**Hosts** — Store content blocks and serve them via SatSwap exchanges. Earn sats per block delivered. No minimum scale. No staking requirement. No specialized hardware. Serve a valid block, receive payment. See the white paper Section 3.5 for host discovery and Section 10.7 for the Host Registry Record schema.

**Application Developers** — Build on the protocol API to create decentralized media platforms, provenance explorers, rights management dashboards, immutable document repositories, content discovery engines, or any application that needs permanent content identity, Bitcoin-verified provenance, or direct micropayment monetization. The protocol has no application-layer functionality of its own — every useful experience is an opportunity for an application developer.

---

## Key Design Decisions

**No protocol-level fees.** Every payment is bilateral and direct — requester to host, creator to host, child DAO to parent DAO. There is no central treasury, no shared pool, no protocol take rate. The absence of protocol-level fees is not a gap in the economic model. It is the economic model.

**IPFS is a reference implementation, not a requirement.** The core primitive is CID-based content addressing. Any system that produces CID-compatible identifiers and participates in the SatSwap exchange and Records Database layers is a conforming participant.

**SatSwap is not a modification of BitSwap.** SatSwap replaces BitSwap's reciprocity model with direct payment. It is a distinct protocol that happens to solve the same routing problem BitSwap was designed for, through a fundamentally different economic mechanism.

**No new token.** All payments are denominated in sats — Bitcoin. The protocol routes economic value through the deepest, most liquid monetary network available rather than creating a new one.

---

## Get Involved

The project repository is open. Pull requests, issues, and forks are welcome.

The Bitcoin and Lightning developer communities are the natural home for this conversation. If you are a developer who sees the architecture and wants to build it, start with the SatSwap specification and the Records Database wire protocol in Part 4 of the white paper.

For community engagement, find the project on Nostr and at Seattle BitDevs meetups.

*The protocol does not build the future. It creates the conditions from which the future can emerge.*

## Current Version

The IPFS Sats white paper is currently on version 0.4, available on IPFS itself using CID QmbDuLbp71iU39NMaqKwvX2fF9QPDyoqj1Fo1kSUouFsF9
