# Pitch to Protocol Developers

## The Problem Is Defined. The Specification Is Written. The Implementation Needs You.

IPFS-Sats is a protocol that combines CID-based content addressing, Bitcoin timestamping via OP_RETURN, Lightning Network micropayments, and per-content DAO governance to create self-sustaining infrastructure for permanent content availability and fair creator compensation. No new token. No ICO. No proprietary consensus mechanism. Bitcoin is the timestamping layer. Lightning is the payment layer. The protocol is the coordination layer that makes them work together for content.

The white paper is complete. The specifications — AtomicSats exchange messages, Records Database wire protocol, Metadata Bundle schemas, Host Registry Records, Anchor Records, DAO Configuration Objects — are written and internally consistent. What does not yet exist is a working implementation. That is what we are looking for help to build.

---

## The Technical Problem

Three things need to be built, in dependency order.

**1. The AtomicSats Node**

AtomicSats is a four-message atomic block-for-sats exchange protocol — WANT, QUOTE, PAYMENT_HASH, BLOCK. A requesting node sends a WANT for a content block. A delivering node responds with a QUOTE and a BOLT11 Lightning invoice. The requester pays and sends the PAYMENT_HASH. The delivering node releases the block with the Lightning preimage. The HTLC settles atomically.

That is the complete protocol. A Go developer with Lightning Network experience — LND or Core Lightning — can build a conforming AtomicSats node from the specification in Section 10.6 of the white paper. The implementation is a Lightning node that also serves content blocks. Not a Lightning wallet attached to a content node. A single unified implementation where payment settlement is native.

This is the foundational primitive. Everything else depends on it working.

**2. The Records Database Node**

The Records Database is a distributed, permissionless data layer storing three tables: Host Registry Records, Anchor Records, and Content Flag Records. The wire protocol is modeled on Nostr relay architecture with libp2p Kademlia peer discovery. The schema validation, replication model, and conflict resolution rules are specified in Section 10.2 of the white paper.

A developer familiar with distributed systems — Nostr relay implementation, libp2p, OrbitDB, or BitTorrent DHT — will find the architecture familiar. The novel work is the three-table schema and the query interface that the Host Discovery Layer sits on top of.

**3. Metadata Bundle Tooling**

Command-line tools for creating, signing, anchoring, and querying Metadata Bundles. This includes: generating the Bundle Hash from a Content CID and Metadata Wrapper, committing the Bundle Hash to Bitcoin via OP_RETURN, publishing the resulting Anchor Record to the Records Database, and querying the Records Database for existing Anchor Records by content CID or creator DID.

This is the tooling that lets creators interact with the protocol without building their own implementation. It is also the tooling that application developers use to integrate protocol functions into their applications before the full API layer is built.

---

## The Technical Scope in Detail

**Lightning Network integration.** The AtomicSats node requires HTLC creation, invoice generation, payment verification, and preimage management. LND's gRPC API and Core Lightning's JSON-RPC API are both viable integration surfaces. The implementation must handle the payment-in-flight verification step — confirming a PAYMENT_HASH corresponds to a valid in-flight HTLC before releasing a block — without exposing the preimage prematurely.

**Content-addressed block store.** The AtomicSats node requires a CID-based block store — IPFS is the reference implementation, go-ipfs provides the block store interface directly. The block store interface is: `Put(cid, data)`, `Get(cid) → data`, `Has(cid) → bool`. Any implementation satisfying this interface is conforming.

**Host Discovery Layer.** The AtomicSats node queries the Records Database for Host Registry Records matching a requested CID. This requires a DHT query interface against the Records Database peer network. The query returns a ranked list of hosts by uptime score and price, from which the requesting node selects counterparties for parallel WANT dispatch.

**Records Database replication.** The Records Database nodes gossip records to peers using a protocol modeled on Nostr relay-to-relay replication. Records are append-only, content-addressed, and signed by their publisher's DID. Conflict resolution is last-write-wins per record type, with Anchor Records treated as immutable once published.

**Bitcoin OP_RETURN commitment.** The Bundle Hash commitment to Bitcoin is a standard OP_RETURN output in a Bitcoin transaction — 32 bytes, provably unspendable, permanent. The tooling needs to construct, sign, and broadcast this transaction, then record the resulting txid and block height in the Anchor Record published to the Records Database.

---

## Compensation and Attribution

The protocol is released as a public good. There is no central organization, no protocol treasury, and no milestone-based payment system controlled by anyone. Compensation takes the forms available to open-source infrastructure contributors: ecosystem grants from Bitcoin and Lightning Network development funds, direct community contribution, and the reputational value of being a foundational architect of infrastructure-level technology.

There is also something more durable, built into the protocol itself: the Right to Fork applies to the reference implementation.

If you build the reference AtomicSats node and release it under a license that encodes fork provenance — and the protocol provides exactly the mechanism to do that — then every commercial application built on your implementation owes you an upstream royalty, automatically, enforced by the Child DAO's smart contract, indefinitely. You do not need to negotiate licenses. You do not need to pursue infringers. You do not need a legal team. The protocol handles it.

The developer who writes foundational Bitcoin infrastructure and releases it as a public good, and earns from every downstream commercial deployment automatically — that is a different relationship to open-source contribution than the one the current ecosystem offers.

---

## Why This Project

The technical problems here are real and well-defined. Atomic block-for-sats exchange via Lightning HTLC is a solved cryptographic primitive applied to a new context. Distributed permissionless databases with content-addressed schemas are an active area of implementation in the Nostr and libp2p ecosystems. Bitcoin OP_RETURN commitment is standard tooling. The novel work is the integration — making these primitives work together as a coherent protocol stack.

The protocol has no venture funding to protect, no token price to defend, no platform business model to optimize around. It is released in the same spirit as the Bitcoin white paper: here is the architecture, here are the specifications, build it.

If you are a developer who wants to write foundational code that serves the same function for twenty years without being acquired, pivoted, or shut down — this is that project.

---

## Where to Start

The white paper is at github.com/chadlupkes/IPFS-Sats.

Start with Section 10.6 (AtomicSats Exchange Message Spec) and the standalone AtomicSats Protocol Specification in the repository. That is the first implementation target and the critical path dependency for everything else.

Section 10.2 (Records Database Specification) is the second implementation target.

The Bitcoin and Lightning developer communities — including groups like Seattle BitDevs and contributors to the broader Lightning ecosystem — are where this conversation belongs. If you are a developer who sees the architecture and wants to build it, open an issue in the repository and say so. That is how this starts.
