# 6.4 DAO Governance and Accountability ⚖️

The framework for dispute resolution and content accountability prioritizes transparency, decentralized signaling, and the right to exit over centralized censorship. The protocol is content-agnostic by design — it provides the data infrastructure for accountability signals, and applications built on that infrastructure decide how to act on them.

---

## 6.4.1 Protocol-Level Content Flagging

The IPFS-Sats protocol does not moderate content. It provides a neutral, distributed mechanism for recording and propagating accountability signals about content — signals that applications can query, act on, and build filtering systems around. The home for these signals is the Records Database (Section 3.5), which stores Content Flag Records alongside Host Registry Records and Anchor Records as the third table of the distributed data layer.

### Content Flag Records

A Content Flag Record is written to the Records Database when a participant — any user, application, or designated validator — identifies a Content CID as potentially harmful. The flag is associated with the Content CID itself, not the Metadata Bundle, which means it persists regardless of what governance updates occur to the wrapper or what distribution channels the content travels through.

Flag records carry a category, a severity level, the submitting identity, and a confirmation status that updates as other participants independently verify or dispute the flag. The protocol stores and serves this data. What applications do with it is their decision.

| Flag Category | Severity | Description |
|---|---|---|
| **Malware / Security Threat** | Critical | Content containing code designed to exploit, compromise, or attack client systems |
| **Illegal Content** | High | Content determined through confirmation to violate widely accepted international statutes |
| **Spam / Harmful Content** | Medium | Low-quality, duplicative, or bot-generated content designed to degrade network or user experience |

### Confirmation and Validation

A submitted flag enters the Records Database as pending. Confirmation occurs through one of two paths:

- **Community confirmation:** Other participants independently submit flags against the same Content CID. When confirmed flags reach a threshold defined by the querying application, the flag becomes active in that application's context.
- **Validator confirmation:** Application operators may designate validators — individuals or organizations whose flag submissions carry confirmation weight without requiring additional community verification. Who those validators are, how they are selected, and what authority they carry is entirely an application layer decision. The protocol provides the infrastructure; the brand operating a streaming service, a marketplace, or a distribution platform is responsible for defining its own trust model.

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

Applications that implement content filtering route retrieval requests away from hosts serving flagged Content CIDs. Those hosts complete fewer SatSwap exchanges, earn less from the affected content's LYW, and fall in the Host Discovery Layer's performance ranking for that content. Hosts that update their behavior return to full participation.

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

## 6.4.3 Enforcement and Remediation Forking

When a high-severity Content Flag is confirmed against a Content CID, the protocol's response is economic isolation of the flagged content's revenue flows — not deletion or technical blocking, which would be inconsistent with the protocol's content-agnostic design.

### Protocol-Level Response

When a confirmed high-severity flag is written to the Records Database:

- **LYW payment suspension:** Outgoing payments from the flagged content's LYW are suspended. Sats continue to accumulate but do not distribute to the Creator or host pool while the flag is active.
- **DAO operations freeze:** No new governance proposals can be submitted or executed against the flagged CID's DAO while the freeze is in effect.
- **Participant protection:** Participants in the flagged content's DAO — hosts, initial depositors, and any other revenue recipients — are given a grace period to review their participation and adjust their position before the freeze becomes permanent.

### Path to Resolution — Remediation Fork

The Content Creator's mechanism for restoring economic activity under a confirmed high-severity flag is a remediation fork:

1. **Economic suspension:** All sats distributions for the flagged Content CID are permanently suspended. The content remains on the network and its flag record remains queryable — the historical record is preserved.
2. **Content modification:** The Creator modifies the flagged element, generating a new Content CID through re-hashing.
3. **New DAO deployment:** A new DAO is deployed against the remediated Content CID. Participants may migrate their involvement to the new DAO. The new CID begins with no flag record.

The incentive structure is aligned: the only path back to economic participation runs through producing content that does not attract confirmed high-severity flags. The original flagged CID remains permanently visible in the Records Database — available for historical, legal, and investigative reference — but generates no further economic activity.
