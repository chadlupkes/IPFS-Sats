# 6.2 Proposal Types and Validation Thresholds 🗳️

Governance actions within the Per-Content DAO are categorized by their potential impact on the content's economic structure and technical integrity. Different proposal types carry corresponding validation thresholds to ensure stability and protect all participants.

A note on scope: the protocol defines governance **primitives**, not governance **policies**. The proposal types and thresholds described here are the protocol-level mechanisms. The specific policies a DAO applies within those mechanisms — which actions require which approvals, how membership transitions are handled, what constitutes valid grounds for offboarding — are application layer concerns, shaped by the DAO's configuration and the legal and jurisdictional context surrounding it. The protocol's responsibility is to ensure the mechanisms are sound and the structural protections against capture are in place. Everything else is configuration.

---

## 1. Distribution Reallocation (Constitutional)

A proposal to alter the income distribution ratio is the most consequential action available to a DAO, because changing the distribution simultaneously changes the voting weights of all subsequent proposals. The two cannot be separated — they are the same operation.

- **Scope:** Adjusting the percentage of incoming sats allocated among any current DAO members, including the Content Creator, initial depositors, and the host pool.
- **Implication:** Any change to the distribution ratio immediately updates the voting weights of all members for all future proposals. A participant who gains share gains governance power; a participant who loses share loses it. This is why the threshold is the highest in the system.
- **Default behavior:** Distribution reallocation is a valid DAO action in the default unlocked configuration. The Key 1 lock option (Section 6.1) exists precisely for cases where participants require a permanent guarantee that these terms will never change.
- **Guardrail:** Supermajority (66.7%) of participating voting power. This threshold is the structural defense against a voting majority using a distribution change to extract value from or eliminate minority participants.

---

## 2. Membership Changes (Constitutional)

Membership changes — adding or removing participants from the DAO — are governed at the same constitutional level as distribution reallocation, because any membership change that includes a revenue share is effectively a distribution change. The same risks apply: altered voting weights, shifted economic stakes, and the potential for a majority to use the mechanism against minority participants.

- **Scope:** Onboarding a new member with a defined income share; offboarding an existing member with or without a buyout calculation; adjusting the composition of the host pool.
- **Mechanism:** Upon a successful vote, Key 3 automatically executes the updated distribution schedule, replacing the prior one. The new schedule takes effect at the next distribution cycle.
- **Default behavior:** Membership changes are a valid DAO action in the default unlocked configuration. The same Key 1 lock option that governs distribution reallocation applies here — a creator who wants a permanently fixed membership structure can configure Key 1 to prohibit these changes, with forking as the only path to a different composition.
- **Guardrail:** Supermajority (66.7%) of participating voting power, for the same reasons as distribution reallocation. The protocol treats a change as a change — the specific policy implications of different membership change types are application layer concerns.

---

## 3. Smart Contract Updates (Technical)

These proposals address the underlying code governing the content's financial logic and security, separate from the economic parameters.

- **Scope:** Logic upgrades (patching bugs, improving execution efficiency), security patches addressing protocol vulnerabilities, and migration to a new version of the IPFS-Sats protocol.
- **Risk profile:** High. A malicious or poorly constructed code update could lock funds, break content access, or alter the economic behavior of the DAO in ways participants did not approve.
- **Guardrail:** Supermajority (66.7%) threshold with an extended execution delay of 48 hours, giving all stakeholders time to review the proposed change and adjust their participation before it takes effect.

---

## 4. Licensing and Commercial Decisions (Operational)

These are operational proposals that affect how content is consumed and monetized, without altering the internal distribution structure or membership composition.

- **Access pricing:** Adjusting the sats cost required for a user to view, retrieve, or download the content.
- **Rights management:** Toggling content between view-only and remixable, updating copyright status (e.g., moving to Creative Commons or CC0), or authorizing specific commercial use cases for third parties.
- **Fork approval:** Formally authorizing a derivative work to register a parent-child CID relationship, enabling cascading royalty flows from the derivative back to this DAO.
- **Guardrail:** Simple majority (51%) of participating voting power. These are business decisions with reversible or adjustable outcomes, and do not carry the structural risk of the constitutional categories above.

---

## 5. Emergency Actions

Emergency proposals address time-sensitive situations where the normal governance timeline would cause harm — active security exploits, compromised member keys, or critical bugs requiring immediate response.

- **Scope:** Temporarily pausing Key 3 automation, replacing a compromised Key 2 member credential, initiating an emergency security patch, or freezing the LYW pending investigation of anomalous activity.
- **Guardrail:** Reduced quorum (20%) applies to allow action when normal participation levels cannot be assembled quickly. Supermajority (66.7%) of participating voting power is still required to pass, ensuring emergency authority cannot be exercised by a small faction. A full DAO vote at standard quorum is required to ratify or reverse any emergency action within 7 days of its execution.

---

## Summary of Proposal Thresholds

| Proposal Category | Impact Level | Quorum | Threshold | Execution Delay |
|---|---|---|---|---|
| **Licensing / Commercial** | Operational | 35% | 51% Simple Majority | 24 hours |
| **Smart Contract Update** | Technical Risk | 35% | 66.7% Supermajority | 48 hours |
| **Membership Change** | Constitutional | 35% | 66.7% Supermajority | 24 hours |
| **Distribution Reallocation** | Constitutional | 35% | 66.7% Supermajority | 72 hours |
| **Emergency Action** | Critical / Time-Sensitive | 20% | 66.7% Supermajority | Immediate + 7-day ratification |
