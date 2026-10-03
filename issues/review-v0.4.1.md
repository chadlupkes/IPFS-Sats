# IPFS-Sats v0.4.1 — Technical Review

**Reviewed version:** 0.4.1 (OpenTimestamps anchor, block 942,688)
**Review date:** 2026-08-02
**Target:** v0.5.0
**Scope:** Full repository — white paper, AtomicSats specification, `primitive.md`, implementation scaffolding
**Reviewer note:** This is an adversarial read. It assumes the architecture is sound and looks for what a hostile technical reviewer in the Bitcoin, Lightning, or IPFS communities would attack first. Strengths are noted only where they bear on a finding.

---

## Summary

| # | Finding | Severity | Affected |
|---|---|---|---|
| 1 | LYW's purpose contradicts AtomicSats' central claim; proof-of-storage reintroduced and insufficient | **Blocker** | `atomicsats.md`, `051LYWeconomics.md` §5.1.4, `052LYWmodel.md` §5.2.3 |
| 2 | HTLC atomicity claim overstated — standard invoices auto-settle; preimage not bound to block data | **Blocker** | `atomicsats.md` §4, §5, §8, §9 |
| 3 | Yield assumptions optimistic and structurally inverted against adoption | **Major** | `051LYWeconomics.md`, `052LYWmodel.md` §5.2.1 |
| 4 | Key 3 is an unspecified trusted third party | **Major** | `041threeKeyArchitecture.md`, all LYW automation |
| 5 | OP_RETURN cost claim inaccurate; anchoring does not scale as specified | Minor | `primitive.md`, `README.md`, `052LYWmodel.md` §5.2.1 |
| 6 | Channel funding transaction cannot carry the anchor | Minor | `052LYWmodel.md` — `initializeLYW` step 4 |
| 7 | Load-bearing availability statistic uncited and contradicted by published measurement | Minor | `01abstract.md`, `README.md`, `atomicsats.md` §1.1 |
| 8 | Implementation scaffolding is empty; `lnd` pin is a stale release candidate | Minor | `implementation/atomicsats/` |

Findings 1 and 2 are marked Blocker because each invalidates a claim the specification makes explicitly and repeatedly. Neither is fatal to the architecture — both have resolutions proposed below — but shipping v0.5.0 without addressing them means shipping a document whose headline claims do not survive first contact with a Lightning developer.

---

## 1. The LYW's purpose contradicts AtomicSats' central claim

**Severity: Blocker**

### The contradiction

`atomicsats.md` states the position without qualification:

> The exchange is the verification step. A host that delivers a block whose hash matches the requested CID has proven it holds that block. **There is no separate proof-of-storage mechanism. There is no challenge-response verification.** The four-message handshake is sufficient.

`051LYWeconomics.md` §5.1.4 then specifies a proof-of-storage mechanism:

> 1. **Proof Generation:** The storage host provides a cryptographic **Proof-of-Storage** (e.g., a challenge/response signature) for the content specified by the content CID

And `052LYWmodel.md` §5.2.3 specifies it in code — `requestStorageProof()`, `verifyMerkleProof()`, randomized nonces, removal from registry on failure.

These documents contradict each other directly. A reader who reads both will not know which describes the protocol.

### Why the contradiction exists

This is not an editing oversight. It is a structural consequence of what the LYW is for.

Retrieval-as-proof is elegant and correct **for content that is being retrieved**. The CID *is* the receipt; no additional machinery is needed. But the LYW's stated purpose is funding persistence of content nobody is requesting — `051LYWeconomics.md` is explicit that a LYW generates yield "independent of whether the content is ever commercially accessed," and the archival, legal, and family-record use cases in Part 5 depend on exactly that.

For un-retrieved content there is no exchange, therefore no self-proving delivery, therefore nothing to pay against. The proof-of-storage mechanism in §5.1.4 was introduced to fill that gap — which means the gap is real, and the AtomicSats abstract's claim is scoped more narrowly than it appears.

### Why the current mechanism does not close the gap

A randomized challenge answered with a Merkle proof does not demonstrate storage. It demonstrates *access at the moment of challenge*. A host that deleted the block can satisfy the challenge by fetching the block from another host, answering, and discarding it again.

This is the **outsourcing attack**, and defending against it is the entire reason Filecoin's Proof-of-Replication is as heavy as it is: PoRep forces a slow, physically-committed, uniquely-encoded copy so that regenerating it on demand costs more than storing it. Any scheme that merely proves the prover can *produce* the data — rather than that it *retained a distinct copy* — is vulnerable.

The specification cannot simultaneously claim to avoid Filecoin's complexity and use a mechanism that Filecoin's complexity exists to replace.

### Proposed resolution — synthetic retrieval audits

Delete §5.2.3's challenge-response entirely and replace it with a mechanism built from the primitive the protocol already has.

**Mechanism.** Key 3 periodically issues genuine AtomicSats exchanges — real `WANT` messages for randomly-selected blocks of the content, at prevailing market price, paid from the LYW. A host that serves the block earns the retrieval fee. A host that cannot serve it earns nothing and accumulates a negative delivery signal in its Host Registry Record.

**Properties this gains:**

- **No new cryptography.** The audit is an ordinary exchange. Hosts need no code they do not already have; the audit is indistinguishable from organic demand.
- **Self-proving, same as every other exchange.** `hash(data) == cid` remains the only verification.
- **Unifies two mechanisms into one.** Payment for storage and payment for retrieval become the same payment. §5.1.4 and §5.2.3 collapse into a paragraph.
- **Removes the "unpopular content" special case.** Every piece of content in the network receives retrieval demand — organic, synthetic, or both — and hosts respond to a single undifferentiated signal.
- **Preserves the economic-gradient framing of `primitive.md`.** Nothing is commanded. A host that stops serving simply stops earning.

**On the outsourcing attack.** Synthetic audits do not eliminate outsourcing; they price it. A host that deleted the block must buy it back at market rate to answer each audit. The audit is profitable to defend against only when:

```
E[audits per period] × retrieval_price  <  storage_cost_per_period
```

Key 3 sets audit frequency to invert that inequality. Because the LYW knows both the storage cost it is paying and the retrieval price it is offering, it can compute a sufficient audit rate directly. Outsourcing becomes a losing trade rather than an impossible one — which is a weaker guarantee than PoRep, and an honest one.

**Additional note.** Audit blocks must be selected unpredictably and Key 3 must not signal which exchanges are audits. If a host can distinguish an audit from organic demand it can outsource only for audits. Selection should be pseudorandom over the block set, with a seed the host cannot compute in advance.

### Action items

- [ ] Rewrite `atomicsats.md` abstract to scope the "no proof-of-storage" claim to retrieval, or to reference synthetic audits as the persistence case
- [ ] Delete `051LYWeconomics.md` §5.1.4 proof-of-storage flow; replace with synthetic audit description
- [ ] Delete `052LYWmodel.md` §5.2.3 `requestStorageProof` / `verifyMerkleProof` logic; rewrite `payHostsForStorage()` as audit dispatch
- [ ] Add an audit-frequency derivation to the economic model, with worked example
- [ ] Specify audit unpredictability requirements

---

## 2. The HTLC atomicity claim is stronger than the mechanism supports

**Severity: Blocker**

Two distinct defects in the four-message handshake. Both are fixable; the first is a specification gap, the second is a claim that must be weakened.

### 2a. Standard BOLT11 invoices settle on arrival

`atomicsats.md` §4.2 specifies that `QUOTE` carries a standard BOLT11 invoice, and §5 asserts:

> The delivering node releases the block and receives no payment: revealing the preimage in the BLOCK message is what causes the payment to settle — withholding the block means withholding the preimage means no payment

This is not how a standard invoice behaves. When the host is the final hop, the host's node settles the HTLC automatically on arrival and reveals the preimage into the Lightning network as part of normal operation. The host is paid the moment the payment lands, whether or not it ever transmits `BLOCK`.

An implementer following §4.2 literally will build a node that pays out on `WANT` and can be drained by any counterparty that never delivers.

**Resolution.** The specification requires **hold invoices** — `AddHoldInvoice` in LND's `invoicesrpc`, or the equivalent in Core Lightning. Under a hold invoice the host generates the preimage, issues an invoice against its hash, and the incoming HTLC is *accepted but not settled* until the host explicitly calls settle. That is the behavior §5 describes, and it must be stated normatively rather than assumed.

This also has consequences the spec should acknowledge:

- Held HTLCs consume channel capacity and slot count for the hold duration; a host running many concurrent exchanges can exhaust its HTLC slots (483 per direction under current channel limits)
- `expires_at` in `QUOTE` must be set well inside the HTLC's CLTV expiry, or the host risks a force-close while holding
- The requester's funds are locked for the hold duration, which bounds practical exchange concurrency on the requesting side too

### 2b. The preimage is not bound to the block data

The deeper problem. `BLOCK` carries `data` and `preimage` in the same message. Once the preimage is released, settlement proceeds on the Lightning Network independently of whether `hash(data) == cid`.

§8 claims otherwise:

> | Block fails CID verification | Corrupted or fraudulent delivery | Retry with different host; record failed delivery as negative uptime signal |

and §9.1:

> | **Invalid block delivery** | Host delivers data that does not hash to the requested CID | Requester verifies CID before preimage propagates; payment fails |

The requester has no such veto. Settlement is initiated by the host releasing the preimage; the requester is the payer and cannot retract an accepted HTLC. A host can settle and transmit arbitrary bytes, or settle and transmit nothing at all.

**The claim as written is false.** "Atomic by construction" and "either party is defrauded through normal protocol operation — cannot happen" do not hold.

### Resolution options

**Option A — cryptographic binding (correct, expensive).** Bind the payment secret to the data. The established constructions:

- *Encrypt-then-reveal-key.* Host encrypts the block under a random key `K`, transmits the ciphertext first, and sets the HTLC preimage to `K`. Settlement reveals `K`, which decrypts the block. Requires a proof that the ciphertext decrypts under `K` to something hashing to `cid` — otherwise the host substitutes garbage and the problem recurs one level down.
- *Zero-Knowledge Contingent Payment (ZKCP).* Provides exactly that proof. Cryptographically sound, well-studied, and far too heavy for a $0.0026 block transfer — proof generation would dominate the cost of the exchange by orders of magnitude.

Option A is not recommended at this block size. It is worth a paragraph in the spec explaining why it was considered and rejected, because reviewers will ask.

**Option B — economic irrelevance (recommended).** Stop claiming cryptographic atomicity. Claim instead that fraud is economically pointless.

At the reference pricing in §6.1, a 256 KB block costs 2,560 msats — roughly $0.0026 at $100k BTC. A defrauding host gains a quarter of a cent and loses its `uptime_score`, which is the asset that brings it future `WANT` messages. The requester retries with a different host and is out a rounding error.

This is a legitimate and defensible design. It is how most low-value micropayment systems work in practice. It simply requires the specification to say so:

- Rewrite §5 "Atomicity Guarantee" as "Settlement and Fraud Economics"
- State plainly that atomicity is enforced against *non-delivery* by the HTLC timelock, and against *invalid delivery* by economics and reputation, not by cryptography
- Correct the §8 and §9.1 table rows
- Add the bounded-loss argument explicitly: maximum loss per fraudulent exchange is one block's price, and requesters SHOULD cap per-host exposure across an exchange session

**Recommended combination.** Option B for the claim, plus a normative note that implementations SHOULD prefer hosts with established `uptime_score` for large multi-block retrievals, so that aggregate exposure to an unknown host stays bounded.

### Action items

- [ ] Add normative hold-invoice requirement to §4.2, with LND/CLN API references
- [ ] Document HTLC slot exhaustion and CLTV/`expires_at` interaction as implementation constraints
- [ ] Rewrite §5 as "Settlement and Fraud Economics"; remove "atomic by construction"
- [ ] Correct the invalid-delivery rows in §8 and §9.1
- [ ] Add bounded-exposure guidance for multi-block retrieval
- [ ] Add a short subsection explaining why ZKCP was considered and rejected

---

## 3. Yield assumptions are optimistic and structurally inverted

**Severity: Major**

### 3a. The rate is not conservative

`052LYWmodel.md` §5.2.1 describes 10% APY as a "conservative yield rate (low estimate for safety)." `051LYWeconomics.md` states a 6–18% range for liquidity leasing and models 12%.

Observed returns for Lightning liquidity provision have run substantially below this — routing income for most nodes falls well under 2% annualized, and channel-leasing marketplaces have historically been thin, with premiums that do not approach the modeled figures. Any number used this way needs a citation to observed market data, and the citation should be recent.

Every figure in the deposit-guideline table derives from this rate. If the true rate is 2% rather than 10%, the recommended deposit for a 1 GB research dataset moves from 1,500,000 sats to roughly 7,500,000 — which changes who can afford to use the protocol, and therefore who its users are.

**Action:** replace the assumed rate with a sourced range, and present the deposit table as a sensitivity matrix across rates (2% / 5% / 10%) rather than a single column derived from the most favorable assumption.

### 3b. The yield source scales inversely with adoption

This is the more serious problem, and it is structural rather than parametric.

Liquidity leasing income derives from **demand for inbound capacity from routing nodes**. That demand is bounded by the payment volume of the Lightning Network. It does not grow because more LYWs exist.

The protocol proposes that every piece of content in the network holds capital and leases it into that market. If IPFS-Sats succeeds at the scale the white paper envisions, LYW capital floods a fixed-size market and the leasing premium collapses toward zero.

The failure shape is the worst available: **the model works in a pilot and fails at scale.** Early adopters observe yields consistent with the projections, the projections appear validated, and the mechanism degrades precisely as adoption grows. A reviewer who spots this will treat the entire economic section as unserious, whatever its other merits.

### 3c. A philosophical inconsistency reviewers will feel

`primitive.md` grounds the protocol in wealth-based rather than debt-based first principles, and `051LYWeconomics.md` §5.1.2 draws the distinction sharply — "true dividend" versus "debt-based, leveraged, or fractional reserve systems."

A sustained 12% risk-free real yield denominated in the hardest available money is precisely the kind of return that, under those same first principles, should not exist. If it did, capital would flow to it until it did not. Presenting it as the low-risk baseline invites the reader to conclude that either the yield is not risk-free or the framework's principles are not being applied to its own mechanism.

The L3 DAO stream in §5.1.2 compounds this: 15–30%+ APY from "growth-phase" DAOs is venture-class return being modeled as infrastructure funding, on infrastructure that §5.1.2's own timeline says will not be evaluated until 2028.

### Proposed resolution

Demote yield from primary to supplementary and promote what already works.

`052LYWmodel.md` §5.2.1 already contains the stronger model — the bootstrapping section, where the creator's node is the first host, content is live and discoverable from publication, and the wallet grows through zaps and access income. That is a funding mechanism whose capacity scales *with* adoption rather than against it: more users means more zaps and more paid retrievals.

Recommended restructuring:

1. **Access income and zaps become the primary funding mechanism.** They already have a section; give them the economic modeling currently spent on yield.
2. **Liquidity yield becomes a supplementary stream**, presented with sourced rates and an explicit note that premiums are expected to compress as LYW participation grows.
3. **L3 DAO allocation moves to an appendix** as speculative future work, clearly marked, with the 2028 timeline retained.
4. **Retire "perpetual motion machine" and "runway: indefinite"** framing. It requires yield > costs to hold permanently, which finding 3b says it will not. "Self-sustaining while demand persists" is defensible; "indefinite" is not.

### Action items

- [ ] Source the leasing yield rate; replace single-point assumptions with a range
- [ ] Convert the deposit guideline table to a sensitivity matrix
- [ ] Add an explicit section on premium compression under protocol growth
- [ ] Restructure Part 3 to lead with access income and zaps
- [ ] Move L3 DAO strategy to an appendix
- [ ] Remove "indefinite runway" and "perpetual motion machine" claims

---

## 4. Key 3 is an unspecified trusted third party

**Severity: Major**

Across the specification, Key 3 — the Execution Key — is assigned the following responsibilities:

- Verifying proofs of storage against DAO policy (§5.1.4)
- Signing Lightning payments to hosts (§5.1.4)
- Adjusting the storage bid according to runway health (§5.1.5)
- Running the rate oracle feed and daily/weekly payout adjustment (§5.1.4)
- Executing yield distribution splits (§5.2.2)
- Triggering low-balance alerts and failsafe self-hosting (§5.2.3)
- Routing fork royalties to ancestor LYWs (§4, README)

Bitcoin has no execution environment for any of this. Key 3 is therefore software running on some machine, holding a signing key, executing policy.

**The unanswered question is who operates it.**

- If the **creator** operates it, the DAO is not autonomous, execution stops when the creator's machine is offline, and every claim about automation becomes a claim about the creator's uptime.
- If a **third-party service** operates it, that service holds signing authority over creator funds and decides which hosts get paid. This is custody with extra steps — structurally the Pinata dependency the README identifies as the problem IPFS-Sats exists to solve.
- If it is **distributed across DAO members**, the specification needs to say how: threshold signatures, quorum rules, liveness assumptions, behavior under member unavailability.

This is the first question a competent reviewer will ask, and the repository does not currently answer it. The three-key architecture is presented as a separation of *authority* — creator, governance, execution — but a separation of authority is not a separation of *trust* unless the execution role is constrained to actions it cannot abuse.

### Directions worth specifying

- **Threshold signatures across DAO members** (FROST or equivalent). Removes the single operator. Introduces liveness requirements that must be stated.
- **Policy-constrained signing** in the manner of Validating Lightning Signer — Key 3 holds a key but a separate validator enforces that it can only sign payments matching published DAO policy. Constrains abuse without removing the operator.
- **Covenant-based constructions** if and when Bitcoin gains the relevant opcodes. Speculative; mark as such.
- **Explicit acknowledgement of the trust assumption.** If v0.5.0 cannot resolve this, saying so plainly — "Key 3 requires a trusted execution environment; eliminating this is open work" — is far stronger than leaving the reader to discover it. Every honest protocol document has a trust-assumptions section. This one needs one.

### Action items

- [ ] Add a "Trust Assumptions" section to `041threeKeyArchitecture.md` enumerating what each key can do and what each requires the holder to be trusted for
- [ ] State explicitly who is expected to operate Key 3 in the reference deployment
- [ ] Specify behavior when Key 3 is offline for each automated function
- [ ] Evaluate threshold signing and policy-constrained signing; document the choice and its liveness implications

---

## 5. OP_RETURN cost claim and anchoring scalability

**Severity: Minor — resolution already in hand**

`README.md` and `052LYWmodel.md` describe Bundle Hash anchoring as occurring "at near-zero marginal cost." Each OP_RETURN commitment is a distinct Bitcoin transaction requiring a fee that is not near zero, and the cost is unbounded during fee spikes. Anchoring one transaction per piece of content does not scale to the volumes described in Part 5.

The resolution is already in use elsewhere in the project: the CHANGELOG records that v0.4.1 was anchored via **OpenTimestamps** at block 942,688. OTS aggregates many commitments into a Merkle tree and anchors the root in a single transaction, with each participant receiving an inclusion proof.

Applying the same technique to Bundle Hashes makes the "near-zero marginal cost" claim true rather than aspirational: cost per anchor falls to (transaction fee ÷ batch size), and the Anchor Record in the Records Database carries the Merkle inclusion path alongside the txid and block height.

Trade-off to document: batched anchoring introduces latency between publication and confirmation (OTS aggregation intervals), and either a dependency on public calendar servers or a requirement that the protocol run its own aggregator. Both are acceptable; both should be stated.

### Action items

- [ ] Replace per-content OP_RETURN with Merkle-batched anchoring
- [ ] Extend the Anchor Record schema (§10.8) with a `merkle_path` field
- [ ] Document aggregation latency and calendar-server dependency
- [ ] Correct "near-zero marginal cost" language to specify the batching that makes it true

---

## 6. The channel funding transaction cannot carry the anchor

**Severity: Minor**

`052LYWmodel.md`, `initializeLYW()` step 4, embeds the Bundle Hash as an OP_RETURN on the Lightning channel-opening transaction:

```javascript
const channelTx = await openLightningChannel({
  amount: depositAmount,
  op_return: bundleHash,
  wallet: wallet.address
});
```

LND exposes no such parameter, and a channel funding transaction has a defined output structure. Beyond the API problem, coupling the provenance anchor to channel lifecycle is fragile by design — the anchor is meant to be permanent, while channels close, splice, and reopen.

**Resolution.** Separate the two operations. Anchoring is an independent transaction (batched per finding 5); channel opening is an independent Lightning operation. The Anchor Record links them by reference, not by sharing a transaction.

### Action items

- [ ] Rewrite `initializeLYW()` to separate anchoring from channel opening
- [ ] Verify remaining pseudocode against actual LND API surface

---

## 7. The availability statistic needs a citation

**Severity: Minor — high reputational exposure**

Load-bearing in three places:

- `01abstract.md`: "over 90% of content becoming unreachable within six months"
- `README.md`: "Studies show over 90% of IPFS content becomes unreachable within six months"
- `atomicsats.md` §1.1: "~70% of peers become unavailable within minutes of uploading content" and "Over 90% of peers are unreachable after six months"

No citation appears in the repository. The README attributes the claim to "studies" without naming one.

The principal peer-reviewed measurement of IPFS in the wild — Trautwein et al., *Design and Evaluation of IPFS: A Storage Layer for the Decentralized Web*, SIGCOMM 2022 — reports considerably better availability characteristics than these figures suggest. If the numbers come from a different source, that source must be named. If they are extrapolated or informal, the language must be softened accordingly.

Note also that §1.1 conflates two different claims: **peer** availability and **content** availability. They are not the same measurement, and content can remain reachable while individual peers churn. The distinction matters and the current phrasing elides it.

This is the first number a hostile reviewer will check, and the persistence crisis — one of the three crises the entire protocol is built to address — rests on it. An uncited figure here does disproportionate damage.

### Action items

- [ ] Locate and cite the source, or replace with figures from published measurement work
- [ ] Separate peer-churn claims from content-availability claims
- [ ] Add a references section to the white paper

---

## 8. Implementation scaffolding

**Severity: Minor — high strategic leverage**

`implementation/atomicsats/` currently contains `go.mod`, `README_DEV.html`, and six `.gitkeep` files. `go.mod` pins:

```
github.com/lightningnetwork/lnd v0.18.0-beta.rc3 // or latest stable
```

A release candidate, now well behind current. The trailing comment indicates the pin was never resolved.

More consequentially: `atomicsats.md` §13 asks Go developers to build a conforming implementation and states the timeline is "weeks, not months." That ask is materially harder to accept against an empty directory. A developer evaluating the project sees a specification and no evidence that anyone has tried to build against it.

**Highest-leverage change available before v0.5.0:** a minimal working `WANT` → `QUOTE` handshake against regtest — two nodes, hold invoices, a stubbed in-memory block store, one sat moving. Perhaps 200–300 lines. It converts the recruiting pitch from *"read this specification"* to *"clone this, run `make demo`, watch a payment settle against a block delivery."*

It would also validate finding 2 empirically: building it against a standard invoice will demonstrate the auto-settle problem in about an hour, and building it against a hold invoice will demonstrate the fix.

### Action items

- [ ] Pin `lnd` to a current stable release
- [ ] Build a minimal two-node regtest handshake demo
- [ ] Add `make demo` and a README section showing expected output

---

## Suggested v0.5.0 sequencing

1. **Build the regtest demo first** (finding 8). It empirically validates or refutes finding 2 before any prose is rewritten, and it is the cheapest item on this list.
2. **Resolve finding 2** using what the demo teaches. Hold invoices become normative; the atomicity claim becomes an economic claim.
3. **Resolve finding 1** — the synthetic-audit mechanism. This is the largest structural rewrite and touches three documents, but it *removes* specification surface rather than adding it.
4. **Restructure the economics** (finding 3). Depends on nothing above; can proceed in parallel.
5. **Add the trust-assumptions section** (finding 4). Even an honest statement of the open problem substantially strengthens the document.
6. **Sweep the minors** — 5, 6, 7. Mechanical.

Findings 1 and 3 both make the specification shorter. Finding 1 deletes two mechanisms and replaces them with one; finding 3 moves speculative material to an appendix. v0.5.0 should be a smaller document than v0.4.1, and a more defensible one.

---

## Closing note

The central insight — that delivery against a content hash is self-proving, and that this makes a retrieval market cheaper to build than a storage market — is correct and worth defending. Nearly every finding above sits at the boundary where retrieval *is not* happening: the LYW, Key 3, the yield model, the persistence guarantee for unread content. That is one problem wearing four costumes.

The synthetic-audit mechanism in finding 1 is proposed specifically because it dissolves that boundary. If every piece of content receives retrieval demand — organic or synthetic — then the retrieval market is the only market the protocol needs, and the architecture reduces to the thing it is actually good at.
