# Pitch to Application Developers

## The Protocol Has No Interface. That's the Opportunity.

IPFS-Sats is infrastructure. It handles content identity, Bitcoin timestamping, Lightning micropayments, and per-content governance. It has no user interface, no discovery experience, no creator dashboard, no analytics layer, no marketplace. Every one of those things is an application waiting to be built — and the protocol is designed so that building them is straightforward.

If you have been waiting for a backend that solves content monetization without platform intermediaries, this is it.

---

## What the Protocol Gives You

**A content identity layer.** Every piece of content published to the protocol has a content-addressed identifier (CID), a Bitcoin-timestamped Metadata Bundle, and a publicly queryable Anchor Record. Your application can verify provenance, check authorship, and query the full fork lineage of any piece of content — without asking anyone's permission and without trusting any intermediary.

**A discovery and data layer.** The Records Database is fully transparent and publicly queryable. Three tables: Host Registry Records (who is serving what content, at what price, with what reliability), Anchor Records (when was this content anchored to Bitcoin, what is its fork provenance), and Content Flag Records (community-reported concerns). A well-designed query engine on top of this data is a valuable application on its own. A content discovery experience, a provenance explorer, a rights management dashboard, a host reputation tracker — all of these are Records Database applications.

**A payment layer.** The protocol API (Section 12 of the white paper) exposes AtomicSats exchange initiation, LYW status queries, and DAO governance functions. Your application does not need to implement Lightning Network payment handling from scratch — it calls the protocol API and payments flow directly between participants in sats. No payment processor. No 30% platform fee. No monthly settlement cycle.

**A governance layer.** Each piece of content has its own Per-Content DAO with configurable membership, voting, and revenue distribution. Your application can expose governance interfaces for creators to manage their DAO, for collaborators to submit proposals and cast votes, and for licensees to request derivative work approval — all backed by smart contract execution, not platform policy.

---

## What You Can Build

The white paper's Use Cases document (github.com/chadlupkes/IPFS-Sats) describes the full landscape. A few starting points:

**Decentralized media platform.** Creators publish content, initialize LYWs, set access prices. Users pay per access in sats via AtomicSats. The platform application handles discovery, playback, and creator dashboards — the protocol handles identity, payment, and persistence. The platform takes no cut from creator revenue; its business model is its own service fees, paid directly by users.

**Provenance and attribution explorer.** Query the Anchor Records table to show the full fork lineage of any piece of content — who built on whose work, what royalty flows are configured, what upstream creators have earned. This is a journalism tool, a research tool, and an IP management tool simultaneously.

**Immutable document repository.** Legal agreements, research data, journalistic source documents, government records — any document hashed, bundled, anchored to Bitcoin, and stored with a funded LYW becomes permanently available and cryptographically timestamped. The application layer handles submission, search, and access control. The protocol handles permanence and provenance.

**Open-source sustainability dashboard.** Query the Records Database for software dependency relationships encoded in fork provenance fields. Show maintainers what downstream projects are building on their work, what royalty flows are configured, and what their LYW is generating. This is the missing economic layer that the open-source ecosystem has needed for thirty years.

**Creator DAO management interface.** A governance front-end that lets creators configure their Per-Content DAO, manage membership, review and approve fork requests, and track yield distribution — without needing to understand the underlying smart contract mechanics.

---

## What Support Is Available

The protocol is released as a public good. There is no central organization controlling access, no application approval process, and no platform terms of service to comply with. You build what you want to build.

Ecosystem support takes the form available to open-source infrastructure projects: grants from Bitcoin and Lightning ecosystem funds, direct community contribution, and the reputational value of being an early builder on infrastructure-level technology. The white paper's Implementation Roadmap (Section 14) describes the reference applications that will be open-sourced as blueprints — a decentralized media platform and an immutable document repository. Application developers who want to build in a specific vertical before those reference implementations exist are encouraged to engage through the project repository.

The protocol API is specified in Section 12 of the white paper. It is complete enough to build against now.

---

## Where to Start

Read the white paper. Start with the Abstract and Section 3 (Technical Architecture) to understand the protocol stack. Section 12 (API Specifications) is the interface surface your application will build against. Section 13 (Use Cases) describes the application landscape in detail.

The repository is at github.com/chadlupkes/IPFS-Sats. Issues, pull requests, and forks are welcome. If you are building something on the protocol, open an issue and say so — that conversation is how the ecosystem starts.
