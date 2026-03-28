# 6.4 DAO Governance and Accountability ⚖️

The framework for dispute resolution and content accountability prioritizes transparency, decentralized signaling, and the right to exit over centralized censorship. The protocol is content-agnostic by design — it provides the data infrastructure for accountability signals, and applications built on that infrastructure decide how to act on them.

---

## 6.4.1 Protocol-Level Content Flagging

The IPFS-Sats protocol does not moderate content. It provides a neutral, distributed mechanism for recording and propagating accountability signals about content — signals that applications can query, act on, and build filtering systems around. The home for these signals is the Records Database (Section 3.5), which stores Content Flag Records alongside Host Registry Records and Anchor Records as the third table of the distributed data layer.

### Content Flag Records

A Content Flag Record is written to the Records Database when a participant — any user, application, or designated validator — identifies a Content CID as potentially harmful. The flag is associated with the Content CID itself, not the Metadata Bundle, which means it persists regardless of what governance updates occur to the wrapper or what distribution channels the content travels through.

Flag records carry a category, a severity level, the submitting identity, and a confirmation status that updates as other participants independently verify or dispute the flag. The protocol stores and serves this data. What applications do with it is their decision.

The protocol defines a reference vocabulary of three starting categories:

| Flag Category | Severity | Description |
|---|---|---|
| **Malware / Security Threat** | Critical | Content containing code designed to exploit, compromise, or attack client systems |
| **Illegal Content** | High | Content determined through confirmation to violate widely accepted international statutes |
| **Spam / Harmful Content** | Medium | Low-quality, duplicative, or bot-generated content designed to degrade network or user experience |

These categories are a starting vocabulary, not a complete taxonomy. Application operators may define additional categories, subdivide existing ones, or ignore the reference categories entirely in favor of their own classification systems. The schema is extensible by design. An adult content platform, a children's educational service, and a legal document archive will have legitimately different classification needs — the protocol accommodates all of them without privileging any.

### Confirmation and Validation

A submitted flag enters the Records Database as pending. Confirmation occurs through one of two paths:

- **Community confirmation:** Other participants independently submit flags against the same Content CID. When confirmed flags reach a threshold defined by the querying application, the flag becomes active in that application's context.
- **Validator confirmation:** Application operators may designate validators — individuals or organizations whose flag submissions carry confirmation weight without requiring additional community verification. Who those validators are, how they are selected, and what authority they carry is entirely an application-layer decision. The protocol provides the infrastructure; the brand operating a streaming service, a marketplace, or a distribution platform is responsible for defining its own trust model.

This design is deliberate. A children's educational platform and a general-purpose content archive have legitimately different standards for what constitutes harmful content. The protocol does not resolve that difference — it gives both platforms the data layer they need to resolve it themselves.

### Why Harmful Use Is Structurally Unwise

The protocol does not need to police harmful content because its architecture makes harmful use structurally inadvisable without any enforcement action.

Every Content CID carries its provenance chain — the Creator ID and LYW addresses are permanently associated with the content at the protocol layer. Content Flag Records are written against the Content CID and follow it regardless of what metadata wrapper it travels under, what distribution channel carries it, or whether the original creator attempts to obscure the relationship. Even pseudonymous identities leave queryable on-chain trails through the LYW and Creator ID fields.

The result is that anyone attempting to use the system for harmful purposes is simultaneously creating a permanent, distributed, cryptographically verifiable record of their identity and distribution network — one that is queryable by white hat researchers, application operators, and law enforcement without requiring any centralized authority to act as an intermediary. The system does not need to stop them. It simply makes the attempt a matter of permanent public record.

### Application Layer Responsibility

| Layer | Responsibility | Action on Flagged Content |
|---|---|---|
| **Protocol Layer** | Data provision and signal storage | Records and serves Content Flag Records; does not censor, delete, or restrict hosting |
| **Application Layer** | Filtering and moderation | Expected to query flag status and apply appropriate handling based on their platform's standards and legal obligations |

### Host Behavior and Economic Incentives

Hosts are not directly penalized for serving content that carries an active Content Flag Record. The protocol does not slash earnings or impose compliance penalties. However, the economic gradient naturally discourages serving flagged content:

Applications that implement content filtering route retrieval requests away from hosts serving flagged Content CIDs. Those hosts complete fewer AtomicSats exchanges, earn less from the affected content's LYW, and fall in the Host Discovery Layer's performance ranking for that content. Hosts that update their behavior return to full participation.

This is the correct model for a decentralized network: not a penalty imposed from outside, but an economic signal that makes correct behavior the rational choice.

---

## 6.4.2 Dispute Resolution: Economic and Philosophical

Conflict resolution for internal DAO disputes prioritizes maintaining stability or providing a transparent mechanism for participants to exit.

### Deadlock Resolution — Status Quo Bias

When a governance proposal results in a tied vote or fails to reach the required quorum:

- **Default outcome:** The proposal is rejected.
- **Rationale:** The protocol operates on a status quo bias. Stability is the default in the absence of consensus. A rejected proposal enters a 7-day cooldown before resubmission is permitted.

This bias protects minority participants. A majority that cannot achieve supermajority consensus on a distribution or membership change cannot simply wear down opposition through repeated proposals — each failed attempt resets the clock.

### The Right to Exit — Content Forking

The ultimate resolution for philosophical or economic disputes that cannot be resolved within a DAO is the ability for any participant or group of participants to fork the content and establish a new DAO under new terms.

1. **New Content CID:** The departing group publishes a new version of the content — even a minimal change generates a new Content CID — with a new Metadata Bundle reflecting their preferred terms.
2. **New DAO Deployment:** A new DAO is initialized against the new Content CID with the membership and distribution configuration the departing group chooses.
3. **Market Decision:** Both versions exist. Users and applications choose which CID to interact with. The original DAO continues operating under its original terms; the fork operates under the new terms. Neither can compel the other.

This process enforces clarity. There is no ambiguity about which version carries which terms, because the terms are encoded in the Metadata Bundle and anchored to Bitcoin for each CID independently.

---

## 6.4.3 Application-Layer Response Options

The protocol provides the signaling infrastructure. How applications respond to confirmed flag records is their decision, shaped by their platform standards, user base, and legal obligations. No response is mandated at the protocol level.

The following options illustrate the range of actions available to application operators when a Content Flag Record reaches confirmed status in their context. These are design patterns, not requirements.

### Economic Response Options

An application may choose to act on confirmed flags by adjusting the economic flows it routes or surfaces:

- **Payment routing suspension:** Suspend routing of payments through the flagged content's LYW for users of that application. Sats may continue to accumulate in the LYW — the application simply stops directing payments toward it.
- **Host deprioritization:** Route retrieval requests away from hosts serving flagged Content CIDs, reducing their AtomicSats exchange frequency for that content within that application's context.
- **Revenue display suppression:** Omit flagged Content CIDs from earnings dashboards, recommendation systems, or monetization surfaces the application controls.

### Governance Response Options

An application may choose to restrict governance activity around flagged content:

- **Proposal suspension:** Decline to process or surface new governance proposals submitted against a flagged CID until the flag is resolved or disputed.
- **DAO state freeze:** Decline to execute Key 3 operations for the flagged CID's DAO while the flag is active in that application's context.
- **Participant notification:** Notify DAO members that a confirmed flag is active and allow a review period before applying further restrictions.

### Remediation Fork Support

The remediation fork is a mechanism available to any content creator regardless of application-layer policy. It does not require application permission — it is a protocol-level right.

When a creator wishes to restore economic activity after their content has attracted confirmed flags in one or more application contexts:

1. **Content modification:** The creator modifies the flagged element, generating a new Content CID through re-hashing.
2. **New DAO deployment:** A new DAO is deployed against the remediated Content CID with the creator's preferred membership and distribution configuration.
3. **Clean slate:** The new CID begins with no flag record. Applications that implement flag-based filtering will treat it as unflagged until new flags are submitted and confirmed against it.

The original flagged CID remains in the Records Database permanently — available for historical, legal, and investigative reference. The creator's identity trail through the LYW and Creator DID fields remains queryable. The remediation fork restores economic participation; it does not erase history.

### Why the Protocol Stays Out

A protocol that hardcodes consequences for specific flag categories is making content moderation decisions on behalf of every application built on top of it — including applications in jurisdictions with different legal frameworks, platforms serving audiences with different standards, and use cases the protocol designers never anticipated.

The transparency of the Records Database is the protocol's contribution to accountability. The consequences are the application's contribution. This division is not a weakness — it is what allows the protocol to serve a global, permissionless network without becoming a censorship layer wearing different clothes.
