# 5.5 Open Source Software: The Demonstration Case 🔧

Open source software is the invisible infrastructure of the modern world. The operating systems running critical servers, the cryptographic libraries securing financial transactions, the networking tools routing global communications — the overwhelming majority are open source projects maintained by small communities of developers, most of whom receive little or no direct compensation for work that billions of people and trillions of dollars depend on daily.

Software is where the economic argument for IPFS-Sats is most legible, because in software the foundational problem is already formally structured. Dependency chains are explicit and machine-readable. Fork relationships are named conventions. The gap between foundational contribution and commercial capture is documented in every package manifest in the world. When a package manager resolves dependencies, the provenance tree already exists as structured data. IPFS-Sats does not have to infer it — it routes economic value through a graph that is already there.

But the principle at work is not a developer tool. It is a universal economic primitive: **value flows upward through dependency chains and is captured at the commercial layer, with nothing routing back down to the foundational contributors who made that value possible.** This describes academic research, traditional knowledge, cultural heritage, and governance frameworks just as accurately as it describes software packages. Software makes the argument most clearly. The implications reach everywhere.

IPFS-Sats does not change what open source software is. It changes the economics of who gets to sustain it, and how — and in doing so, demonstrates what is possible for every domain of human creative and intellectual work.

---

## 5.5.1 The Open Source Sustainability Crisis

The structural problem of open source funding is not a secret. It has been named, studied, and lamented for decades. It persists because the incentive structure of the current system makes it nearly impossible to solve without centralized intermediaries — and centralized intermediaries introduce the very dependencies the open source ethos was designed to avoid.

### The Tragedy of Critical Infrastructure

When a widely-used library suffers a critical vulnerability, the question that always follows is: how was this maintained by one person working in their spare time? The answer is the same every time: because the economics of open source reward consumption, not contribution.

A developer publishes a library under an MIT or Apache license. Thousands of projects depend on it. Hundreds of companies build products on top of it. The library maintainer receives: goodwill, occasional stars on a code repository, and if they are fortunate, irregular donations through voluntary tip platforms.

The companies building on the library receive: reliable infrastructure, reduced development costs, and commercial revenue. The economic relationship between the people who create foundational software and the people who profit from it is essentially uncoupled.

### The Current Funding Model and Its Limits

The open source ecosystem has developed several partial responses to this problem:

- **Corporate sponsorship and grants:** Companies that depend on open source projects sometimes fund maintainers directly. This is better than nothing, but creates implicit and explicit influence relationships between funders and the people whose independence is essential to the software's integrity.
- **Foundation models:** Organizations like the Linux Foundation and Apache Software Foundation provide organizational infrastructure and some funding. These help but do not scale to the long tail of critical libraries that fall below the threshold of foundation attention.
- **Bounty platforms:** Developers can earn one-time payments for specific bug fixes or features. This funds reactive work but not the sustained maintenance that keeps software reliable over decades.
- **Open Core / dual licensing:** Some projects offer a commercial version alongside the open source version, funding development through enterprise sales. This works for some categories of software but fundamentally changes the project's relationship with its community.

None of these solutions address the root problem: **the value created by open source software is not automatically captured by the people who create it.** Value flows upward through the dependency stack and is captured at the commercial layer, with no mechanism to route compensation back down.

IPFS-Sats provides that mechanism.

---

## 5.5.2 The Dependency Chain: Cascading Value Through the Stack

The most important insight for open source software is not that individual libraries can be funded — it is that **the entire dependency chain can be funded simultaneously**, proportionally, and automatically.

Modern commercial software does not build on one library. It builds on hundreds, stacked ten layers deep. A typical web application might depend on a framework, which depends on a networking library, which depends on a cryptographic primitive, which depends on a mathematical utility written by a researcher fifteen years ago. Every layer of that stack contributes to the commercial product's value. Under the current system, compensation for that contribution is zero at every layer below the visible commercial product.

### Cascading Royalties Through the Dependency Tree

When a commercial product registers as a fork of its dependencies on IPFS-Sats, the Right to Fork mechanism (Section 8) routes royalties automatically through the entire provenance tree:

```
Commercial Product (Child)
    ↓ royalty upstream
Web Framework (Parent)
    ↓ royalty upstream
Networking Library (Grandparent)
    ↓ royalty upstream
Cryptographic Library (Great-Grandparent)
    ↓ royalty upstream
Mathematical Utility (Root)
```

Each layer receives compensation proportional to its position in the dependency chain. The root library — the foundational work that everything else builds on — receives a royalty from every commercial product that ultimately descends from it, across the entire ecosystem, automatically, without any action required from the original maintainer.

This is the direct application of the parent-child CID linking and cascading royalty distribution defined in Section 8. Open source software is the use case where this mechanism has the highest leverage, because dependency chains are deep, the foundational work is often old, and the maintainers are most economically vulnerable.

### What the Dependency Signal Reveals

The Host Discovery Layer query logs described in Section 3.5.4 take on additional significance in the OSS context. Every time a compiled binary or deployed service retrieves a dependency's CID, that query is a signal. Aggregate query volume across the dependency tree reveals:

- Which libraries are most critical to the ecosystem (highest query volume)
- Which foundational works are most widely depended upon (deepest in the most dependency trees)
- Which maintainers are doing the most load-bearing work (CIDs with the highest downstream dependency counts)

This signal is currently invisible. The open source ecosystem has no native way to measure how much of the world actually depends on a given piece of code. IPFS-Sats makes that visible, and routes economic value in proportion to it.

---

## 5.5.3 DAO Governance for Maintainer Teams

Open source projects have developed their own governance traditions over decades — benevolent dictators, core committer groups, steering committees, foundation-governed projects. These map cleanly onto the per-content DAO structures defined in Section 3.4, with some OSS-specific considerations worth naming explicitly.

### Common OSS Governance Configurations

**Solo Maintainer (Benevolent Dictator)**

The most common model for smaller libraries. One developer makes all decisions. The DAO configuration mirrors the Solo Creator example in Section 3.4.2 — single member, 100% weight, auto-approve for routine operations. The maintainer retains full sovereignty over licensing decisions, fork approvals, and yield distribution.

A library with no direct audience to receive zaps might default to a higher compound ratio — building the LYW balance to ensure long-term persistence rather than prioritizing immediate income:

```json
"yield_split": {
  "creator": 20,
  "compound": 80
}
```

**Core Committer Group (Collaborative Mode)**

Projects with multiple active maintainers configure Key 2 as a multi-member DAO with weights reflecting contribution history, commit volume, or community vote. Routine operations — dependency updates, minor releases — can be auto-approved by Key 3. Major decisions — licensing changes, API breaks, fork approvals for commercial use — require Key 2 consensus.

**Foundation-Governed Projects**

Large projects governed by a foundation can represent the foundation as a high-weight DAO member while distributing smaller weights to individual maintainers. The foundation's institutional weight governs major strategic decisions; individual maintainers govern day-to-day technical work within their domains.

### Yield Distribution for Multi-Maintainer Projects

Commercial fork royalties flowing into a multi-maintainer DAO are distributed according to the weighted membership model used for any collaborative DAO. Maintainers who have contributed more — measured by whatever metrics the DAO configures — receive proportionally larger shares of the royalty stream.

Contribution-weighted compensation has been proposed many times in open source circles. What IPFS-Sats adds is **automatic enforcement** — the weights are encoded in the DAO, the royalties flow through the LYW, and distribution happens via Lightning without requiring anyone to manually calculate, invoice, or transfer funds.

---

## 5.5.4 Bootstrapping an OSS Project on IPFS-Sats

The bootstrapping path for an open source project is identical to the path described in Section 5.2.1 for any creator — and worth stating explicitly, because the OSS community has historically assumed that economic infrastructure requires capital to start.

It does not.

A maintainer publishes their library's CID to the network. Their node is the first host. The library is discoverable immediately. Developers who use the library and find value in it can zap the LYW address embedded in the Metadata Bundle — directly, without any platform intermediary, with no signup required.

As the wallet balance grows through zaps and accumulated royalties from downstream commercial use, the LYW begins attracting external hosts. The codebase becomes more redundantly available. When the wallet reaches the threshold for sustainable yield generation, host payments begin automatically and the library's persistence becomes self-funding.

For projects with an existing user community, the zap pathway can be remarkably fast. A library used by thousands of developers, each sending even 100 sats, accumulates meaningful capital quickly. A library used by a commercial product begins receiving cascading royalties the moment that product registers its dependency chain.

The minimum viable launch for an OSS project on IPFS-Sats is the same as for any other content: **a node, a CID, and a willingness to share it.**

---

## 5.5.5 License Compatibility and Transition Path

Existing open source licenses — MIT, Apache 2.0, GPL, LGPL, and their variants — are contractual instruments that govern code use through legal agreement. IPFS-Sats does not replace them. It adds **cryptographic economic enforcement** of the terms that voluntary licenses can only express as aspirations.

### How IPFS-Sats Complements Existing Licenses

| License Type | Current Limitation | IPFS-Sats Addition |
|---|---|---|
| **MIT / Apache (Permissive)** | Commercial use permitted with no compensation mechanism | DAO configures royalty terms for commercial forks; automatically enforced at the economic layer |
| **GPL (Copyleft)** | Derivative works must be open source — enforced only through litigation | Fork approval workflow in DAO can require public CID registration of derivatives, making compliance verifiable rather than litigable |
| **LGPL** | Library linking permitted; modification requires open source release | Compliance becomes a verifiable on-chain condition rather than a legal assertion |
| **Creative Commons** | Attribution required; some commercial use restricted | Attribution is cryptographically encoded in the Metadata Bundle; commercial use triggers automatic royalty flow |

### The Transition Path for Existing Projects

A project does not need to change its existing license to adopt IPFS-Sats. The two systems operate in parallel:

1. **Register the codebase** — publish the current version's CID and Metadata Bundle, establishing the Bitcoin timestamp and the LYW address
2. **Configure the DAO** — define maintainer weights, yield split, and fork approval rules
3. **Communicate the change** — add the LYW address to the project README, enabling direct zap support from the developer community
4. **Let the royalty chain build** — as downstream projects register their dependency relationships, royalties begin flowing automatically

Existing users of the library are unaffected. The license terms are unchanged. The only new element is an economic layer that routes value back to the people doing the work — which the license alone was never able to do.

---

## 5.5.6 Major Ecosystem Case Studies: Two Sides of the Same Problem 🔐

The open source sustainability problem manifests differently depending on the resources available to a project. Bitcoin Core and IPFS / Protocol Labs represent opposite ends of the funding spectrum — one chronically under-resourced, one well-resourced but structurally centralized. Both have the same underlying vulnerability. Both are transformed by the same mechanism.

They are presented here as case studies, not as unique situations. The same analysis applies to the Linux kernel, OpenSSL, curl, SQLite, Python, Node.js, and every other foundational codebase the world depends on. The template is universal.

### Case Study A: Bitcoin Core — The Under-Resourced End

Bitcoin is among the most consequential open source software projects in the world by the economic measure that matters most: the value that depends on its correct operation. Hundreds of billions of dollars in stored value, millions of daily transactions, and a growing layer of financial infrastructure all depend on code maintained by a relatively small community of developers.

The current funding model reflects the broader open source sustainability problem at the highest possible stakes. Core developers are compensated through a patchwork of corporate grants, foundation salaries, and individual sponsorships from exchanges, custodians, and other commercial entities that have significant financial interests in how the protocol evolves. The developers themselves are deeply committed to Bitcoin's integrity — but the **structural dependency** on external patrons creates influence vectors that are invisible to the protocol itself.

A well-resourced actor who wants to shape a protocol's development does not need to attack the code. They fund the people who write it. They offer grants, salaries, conference invitations, and research partnerships. Over time, developers whose compensation depends on these relationships may find their independence subtly constrained — not through explicit instruction, but through the ordinary human dynamics of gratitude, access, and financial dependency. The open source community has no structural defense against this attack vector under the current model — only the personal integrity of individual developers, which is a fragile foundation for infrastructure of global importance.

**How IPFS-Sats transforms Bitcoin development funding:**

When Bitcoin Core is registered as a codebase on IPFS-Sats, the funding model inverts structurally. The LYW is funded by the economic activity of the network the code maintains — automatically, proportionally, without any patron deciding who deserves support.

Every commercial entity building on Bitcoin — exchanges, custodians, wallet providers, payment processors, Lightning service providers — registers its software as a downstream fork of the Bitcoin Core codebase. The cascading royalty mechanism routes a percentage of each entity's revenue back up the dependency chain to the Bitcoin Core DAO automatically:

```
Exchange Revenue
    ↓ royalty upstream
Exchange Software (Child)
    ↓ royalty upstream
Lightning Implementation (Parent)
    ↓ royalty upstream
Bitcoin Core (Root)
    → LYW balance grows
    → DAO distributes to maintainers by contribution weight
    → No patron required
```

**Bitcoin's maintainers are compensated by Bitcoin's economy, not by actors within that economy who have interests in the outcome.** The attack surface for patron capture — the gap between who does the work and who pays for it — is closed by making the work itself the source of payment.

| Current Model | IPFS-Sats Model |
|---|---|
| Developers compensated by grants from commercial entities | Developers compensated by automatic royalties from commercial activity |
| Funding decisions made by patrons with financial interests | Funding determined by contribution weight set by the developer community |
| Influence purchased through financial dependency | No financial dependency to purchase |
| Grant relationships are private and opaque | Royalty flows are on-chain and publicly auditable |
| Individual developer integrity is the only defense | Structural separation of funding from patron interest |

The Bitcoin developer community did not create this vulnerability. They built the best model available to them with the tools that existed. The structural fix was not available until now.

### Case Study B: IPFS and Protocol Labs — The Over-Centralized End

Protocol Labs built IPFS as a genuinely open protocol — the content-addressed, peer-to-peer file system that serves as the reference implementation layer of IPFS-Sats itself. The work is important, the technology is sound, and the team's commitment to open infrastructure is real. But IPFS's development, roadmap, and governance have historically lived inside a single private company. That is not a criticism of the people involved — it is the inevitable consequence of funding ambitious infrastructure work through venture capital, which requires centralized ownership and control as the price of investment.

The result is a structural tension that no amount of goodwill can fully resolve: a decentralized protocol whose direction is set by a centralized organization with investors, employees, and commercial interests. Community contributors participate, but ultimate authority rests with the company. The protocol is open; the governance is not.

IPFS-Sats offers the exit ramp — and the symmetry is worth naming directly. A protocol built on IPFS, designed to make decentralized infrastructure economically self-sustaining, can do exactly that for IPFS itself.

**How the transition would work:**

When the IPFS specification and reference implementation are registered on IPFS-Sats, Protocol Labs participates as a high-weight founding member of the DAO — appropriately, given the magnitude of their contribution. But they participate alongside the broader contributor community, with governance weights that reflect actual contribution history across the project's lifetime. Their authority derives from their work, not from corporate ownership.

Every commercial implementation built on IPFS — gateways, pinning services, storage networks, applications — registers its dependency relationship. Royalties flow back to the DAO automatically. Protocol Labs receives its proportional share; so does every significant outside contributor. The protocol's development is no longer funded by venture capital with an exit expectation — it is funded by the commercial activity of the ecosystem it enables.

The governance of IPFS becomes what its technology always promised: genuinely decentralized, with decisions made by contributors and enforced by code rather than by the authority of a founding company.

This is not a criticism of what Protocol Labs built. It is a recognition of what becomes possible when better tools exist. They were building with what was available. IPFS-Sats is what becomes available next. The fact that IPFS-Sats itself runs on IPFS — and that its adoption would feed back into IPFS's own sustainability — is not irony. It is the system working as designed.

---

## 5.5.7 The Bitcoin Improvement Proposal Process: Evolution, Not Replacement 📋

The Bitcoin Improvement Proposal (BIP) process is one of the most thoughtfully designed governance systems in open source software. It provides numbered, authored, formally staged documents with a clear lifecycle from draft through final. Authorship is attributed. Discussion history is preserved. The provenance record of Bitcoin's technical evolution is genuinely strong — the result of a community that understood the importance of doing this right and built the best system they could with the tools available.

The problems with the BIP process are not design failures. They are structural limitations of a system built on voluntary participation, informal authority, and tooling that predates the economic primitives IPFS-Sats provides.

### The Current Structural Limitations

**Uncompensated authorship:** Writing a BIP that gets adopted can represent months of research, drafting, revision, and community engagement. When that BIP is implemented commercially — as the basis of a wallet, an exchange feature, a Lightning service — the author receives nothing. The contribution is acknowledged in the document; the economic value it generates flows entirely to the implementers.

**Review bottleneck:** BIP review depends on the availability of a small number of respected technical contributors who have both the expertise and the standing to move proposals through the process. These reviewers are volunteers. Their time is finite. The result is a queue that moves slowly and inconsistently — not because the reviewers lack dedication, but because there is no economic signal telling the ecosystem how much it values their time.

**Repository governance contention:** Questions about who has authority to merge BIPs, move them to Final status, or reject proposals have been persistent sources of community friction. The authority is informal — it rests on reputation and community trust rather than on transparent, auditable rules. When the community disagrees about how that authority is being exercised, there is no objective ground to stand on.

**No link between adoption and compensation:** A BIP that becomes the basis of a protocol upgrade adopted by every major implementation generates no direct economic return to its author. The link between the work and its value to the ecosystem is acknowledged but not enforced.

### How IPFS-Sats Enhances the BIP Process

IPFS-Sats does not replace the BIP process. It provides the infrastructure layer that allows the process to fulfill its own intentions more completely.

**Cryptographic timestamping at submission:** Every BIP gets a CID and a Bitcoin timestamp at the moment of publication — stronger, more universal provenance than a repository commit history alone. The existence and content of the proposal is anchored to the Bitcoin blockchain, making the authorship record irrefutable and permanent regardless of what happens to the repository hosting it.

**DAO-governed lifecycle transitions:** The informal authority currently vested in repository maintainers is replaced by transparent DAO governance. The rules for moving a BIP from Draft to Proposed to Final are encoded in the DAO and executed by Key 3. Community members with governance weight vote on transitions according to published criteria. The process is auditable; the authority is distributed; the outcome is on-chain.

**Author compensation through adoption royalties:** When a BIP is implemented commercially, the implementing software registers its dependency relationship with the BIP's CID. Royalties flow automatically to the author's LYW. A BIP that becomes a foundational protocol standard — adopted by dozens of implementations across the ecosystem — generates a passive income stream for its author proportional to its actual adoption. The economic link between contribution and value is enforced by the protocol rather than left to goodwill.

**Reviewer compensation from the same pool:** BIP reviewers designated as DAO members with governance weight receive a proportional share of the royalty stream. Their time reviewing proposals is compensated by the same mechanism that compensates authors. The review bottleneck eases because the economic signal reflects how much the ecosystem values thorough, timely review.

### A BIP's Lifecycle Under IPFS-Sats

```
Author drafts BIP
    → CID generated, Bitcoin timestamp anchored
    → Author's DID linked as Key 1
    → BIP DAO initialized: author weight + reviewer weights

Community review period
    → Governance-weighted discussion recorded on-chain
    → Amendment proposals require Key 2 majority

DAO votes: Draft → Proposed
    → Supermajority threshold required
    → On-chain record of vote weights and outcome

Implementations adopt the BIP
    → Each implementation registers dependency on BIP CID
    → Cascading royalties flow to BIP DAO automatically
    → Author and reviewers receive proportional compensation

DAO votes: Proposed → Final
    → Evidence of adoption submitted as on-chain proposal
    → Final status recorded permanently against Bitcoin timestamp
    → Royalty stream continues for lifetime of implementations
```

### What the BIP Community Gains

The BIP process already has what most governance systems lack: a strong culture of attribution, careful documentation, and genuine commitment to technical rigor. IPFS-Sats does not ask that community to abandon any of that. It asks them to accept an economic layer that makes it possible to sustain the work indefinitely, compensate the people doing it fairly, and resolve governance disputes through transparent rules rather than social authority.

The community that built the BIP process was doing the best they could with the tools available. These are better tools. The values are the same.

---

## 5.5.8 The Universal Principle

Software made the argument most clearly. But we return, at the close, to where we began.

The foundational problem — value flowing upward through dependency chains and being captured at the commercial layer, with nothing routing back to the people who built the foundation — is not a software problem. It is a structural feature of how economic systems have historically treated public goods, foundational knowledge, and creative work that cannot be enclosed behind a gate or locked behind a door.

A paper published in 2003 becomes the foundational citation for a drug development program worth billions. A musical tradition developed by a culture over centuries becomes the basis of a commercial recording catalog. A governance framework written by volunteers becomes the template for national policy. A protocol designed by a small team becomes the infrastructure for a global financial system. In every case, the people who did the foundational work receive nothing from the commercial value that built on it — unless they had the resources to negotiate licensing agreements before the value was apparent, which they almost never did.

IPFS-Sats provides the infrastructure to close this gap, for any domain where creative and intellectual work compounds into value over time. The mechanism is the same regardless of the content type: a CID that anchors the work, a Metadata Bundle that records the creator, a DAO that governs the economics, a LYW that routes value, and a cascading royalty chain that ensures foundational contributors participate in the value they made possible.

Software is the demonstration case. Everything else is the application.

The goal is not a better software funding model. The goal is an economy where the people who build foundations are not required to do so as an act of charity — where foundational work is recognized, attributed, and compensated as automatically and as reliably as the commercial work that depends on it.

That is a better world. And the tools to build it are here.
