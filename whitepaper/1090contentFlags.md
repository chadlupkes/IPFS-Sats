# 10.9 Content Flag Record Specification

The **Content Flag Record** is the third table in the Records Database (Section 10.2). It answers the accountability query:

> *"Given a Content CID, return any confirmed flag records associated with it, including category, severity, submitting identity, and confirmation status."*

Content Flag Records are the protocol's accountability signaling layer. Any participant — user, application, or designated validator — can submit a flag against a Content CID. The Records Database stores and propagates these signals. What applications do with them is an application-layer decision.

**The protocol is not a content moderator.** It stores claims and serves data. Applications querying the Content Flag Records table are responsible for defining their own confirmation thresholds, validator trust models, and handling policies. A children's educational platform and a general-purpose content archive have legitimately different standards for what constitutes harmful content — the protocol provides the data layer both need without resolving that difference for them.

The full governance context — confirmation paths, host behavior, economic consequences of confirmed flags, and the remediation fork mechanism — is described in Section 6.4. This section specifies the Content Flag Record schema and its operational role within the Records Database.

---

## Key Design Properties

**Associated with Content CID, not Metadata Bundle CID.** Flags follow the content, not the wrapper. A flag written against a Content CID persists regardless of governance updates to the Metadata Bundle, ownership changes, distribution channel changes, or whether the Metadata Bundle CID changes. The content's cryptographic identity is stable; the flag record is anchored to that identity.

**Append-only.** Once written, a flag record is never modified or deleted. Confirmation and dispute messages arrive as separate records that reference the original flag by its `record_cid`. The accumulated state — flag + confirmations + disputes — is the full signal.

**Flags accumulate.** Multiple flags against the same Content CID from different submitters are stored as separate records. A single confirmation-quality flag from a trusted validator and ten independent community flags both exist in the table and are both queryable. Applications define their own aggregation logic.

**The protocol stores permanent records.** A Content CID that has received confirmed flag records remains in the Records Database permanently. The historical record — including the identity trail from LYW and Creator ID fields in the Metadata Wrapper — is preserved and remains queryable regardless of what actions applications take in response.

---

## Flag Categories

The protocol defines a reference vocabulary of three starting categories. These are not a complete taxonomy and carry no protocol-level enforcement weight — they are a common starting point that application operators may adopt, extend, subdivide, or replace entirely with their own classification systems.

| Flag Type | Severity | Description |
|---|---|---|
| `malware_security_threat` | Critical | Content containing code designed to exploit, compromise, or attack client systems |
| `illegal_content` | High | Content determined through confirmation to violate widely accepted international statutes |
| `spam_harmful_content` | Medium | Low-quality, duplicative, or bot-generated content designed to degrade network or user experience |

What any application does when it encounters a confirmed flag of a given category and severity is entirely that application's decision. The protocol stores the signal; the application decides the response.

---

## JSON Schema: Content Flag Record

```json
{
  // REQUIRED FIELDS

  "content_cid": "QmContent...",           // Content CID being flagged
                                            // This is the Content CID, NOT the Metadata Bundle CID
                                            // Flags follow the content across all metadata changes

  "flag_type": "illegal_content",          // Category — reference vocabulary:
                                            // "malware_security_threat" | "illegal_content" | "spam_harmful_content"
                                            // Applications may define additional types as extensions
                                            // or ignore the reference categories entirely

  "severity": "high",                      // Severity level: "critical" | "high" | "medium" | "low"
                                            // The protocol stores this value — what applications
                                            // do with it is their decision

  "submitted_by": "did:key:z6Mk...",       // DID of the submitting participant
                                            // Any DID-bearing participant may submit
                                            // The submitter's identity is permanently associated
                                            // with this flag record

  "submitted_at_block": 875100,             // Bitcoin block height at time of submission
                                            // Establishes when the flag was filed

  "description": "...",                    // Human-readable description of the claim
                                            // Required — provides context for confirmation and dispute

  "confirmation_status": "pending",        // Current status: "pending" | "confirmed" | "disputed"
                                            // "pending": submitted, not yet confirmed
                                            // "confirmed": confirmation threshold reached per querying
                                            //   application's standards, or validator confirmation received
                                            // "disputed": active dispute has been filed against this flag

  "signature": "ed25519:...",              // Submitter's cryptographic signature over the flag record fields
                                            // Verifiable against the public key of submitted_by DID

  // OPTIONAL FIELDS

  "evidence_cid": "QmEvidence...",         // CID pointing to supporting evidence (screenshot, analysis,
                                            // legal notice, etc.) stored as a content-addressed document

  "jurisdiction": ["US", "EU"],            // Relevant jurisdiction(s) for jurisdictional claims
                                            // Array of ISO 3166-1 alpha-2 country codes or regional identifiers
                                            // Relevant for applications with jurisdiction-specific filtering

  // CONFIRMATION RECORDS (append-only array — grows as confirmations arrive)
  // Confirmation records reference the flag by the CID assigned when it was published —
  // that CID is computed from the record's contents by the content-addressed storage layer
  // and exists outside the record, not within it.

  "confirmations": [
    {
      "flag_cid": "QmFlag...",               // CID of the flag record being confirmed
                                              // Assigned by the storage layer on publication —
                                              // not a field within the flag record itself
      "confirmed_by": "did:key:validator...",
      "confirmed_at_block": 875200,
      "confirmation_weight": 1.0,            // Weight assigned by the application's trust model
                                              // 1.0 for standard community confirmation
                                              // Higher values for application-designated validators
                                              // Protocol does not enforce weight values — this is
                                              // application-layer configuration
      "signature": "ed25519:..."             // Confirming party's signature over the confirmation fields
    }
  ],

  // DISPUTE RECORDS (append-only array — grows as disputes arrive)

  "disputes": [
    {
      "flag_cid": "QmFlag...",               // CID of the flag record being disputed
      "disputed_by": "did:key:...",
      "disputed_at_block": 875210,
      "dispute_evidence_cid": "QmDispute...", // Optional — CID of counter-evidence
      "description": "...",                  // Human-readable grounds for dispute
      "signature": "ed25519:..."
    }
  ]
}
```

---

## Field Reference

**The flag record's CID** — The unique identifier for a published flag record is assigned by the content-addressed storage layer when the record is published — computed from the record's serialized contents, not stored as a field within the record itself. This is the same principle as the Bundle Hash and Metadata Bundle CID: the identifier cannot be included in the data it identifies without creating a circular dependency. Confirmation and dispute records reference a flag using the `flag_cid` field, which holds the CID the storage layer assigned on publication.

**`content_cid`** — The Content CID being flagged. This is the raw content identifier — not the Metadata Bundle CID. This design ensures the flag follows the content through any metadata updates, governance changes, or distribution channel changes. A new Metadata Bundle pointing to the same Content CID inherits the existing flag records.

**`confirmation_status`** — Updated by the Records Database when confirmation or dispute messages arrive referencing this flag by its published CID. The transition from `pending` to `confirmed` is defined by the querying application's threshold logic — the protocol does not enforce a universal threshold. A flag is confirmed in a given application's context when that application's confirmation criteria are satisfied.

**`confirmations` array** — Grows as confirmation messages arrive. The protocol stores every valid confirmation it receives. Applications aggregate this array using their own threshold logic: a simple application might require three independent community confirmations; a regulated platform might require a single confirmation from a designated validator with `confirmation_weight >= 10.0`. Both models are valid — both use the same protocol-level data structure.

**`disputes` array** — Grows as dispute messages arrive. A dispute does not automatically change `confirmation_status` — it is a signal that the flag is contested. Applications decide how to weight disputes against confirmations in their filtering logic.

---

## Confirmation Paths

Two paths exist for transitioning a flag from `pending` to `confirmed`:

**Community confirmation:** Other participants independently submit confirmations referencing the original flag by its published CID. Applications set their own threshold — number of confirmations, cumulative `confirmation_weight`, or both — for treating a flag as active in their context.

**Validator confirmation:** Application operators may designate validators whose DID-signed confirmations carry elevated `confirmation_weight`. Who those validators are, how they are selected, and what weight they are assigned is entirely an application-layer decision. The protocol provides the infrastructure; the platform defines its trust model.

Neither path requires the original submitter to take any further action after filing the flag. Confirmation is an independent process driven by other participants and validators.

---

## Application-Layer Response Options

The protocol does not define or enforce consequences for confirmed flags. What an application does when it encounters a confirmed flag record is entirely that application's decision, shaped by its platform standards, user base, and legal obligations.

Section 6.4.3 describes a range of response options available to application operators — from economic routing adjustments to governance restrictions to remediation fork support. The full menu of options is documented there.

The one protocol-level guarantee is permanence: confirmed flag records, confirmation history, and the content's identity trail remain in the Records Database permanently. Applications may act on this data in any way they choose. They cannot remove it.

---

## Why Harmful Use Is Structurally Inadvisable

The protocol does not need to police harmful content because its architecture makes harmful use strategically unwise without any enforcement action.

Every Content CID carries its provenance chain permanently — the Creator DID and LYW addresses are associated with the content at the protocol layer through the Metadata Wrapper. Content Flag Records follow the Content CID regardless of what wrapper it travels under. Even pseudonymous identities leave queryable on-chain trails.

Anyone attempting to use the system for harmful purposes is simultaneously creating a permanent, distributed, cryptographically verifiable record of their identity and distribution network — queryable by researchers, application operators, and investigators without requiring any centralized authority to act as intermediary. The system does not stop them. It makes the attempt a matter of permanent public record.

---

## Replication Behavior

Content Flag Records are append-only. A node stores every valid flag it receives and forwards it to peers. Flags accumulate — multiple flags from different submitters for the same Content CID are stored as separate records. Confirmation and dispute records arrive as separate messages referencing the original flag by `flag_cid` (the CID assigned by the storage layer when the flag was published); the Records Database updates the `confirmations` and `disputes` arrays and recalculates `confirmation_status` when they arrive.

Deduplication: a duplicate flag from the same submitter for the same Content CID (identical `content_cid` + `submitted_by` + `flag_type`) is stored once.

The economic incentive for Content Flag Record persistence is the same as for all Records Database tables: participation in the discovery layer earns revenue through AtomicSats exchanges, and that incentive covers the full database without requiring a separate economic wrapper per record type.
