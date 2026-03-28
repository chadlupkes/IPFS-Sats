# 10.8 Anchor Record Specification

The **Anchor Record** is the second table in the Records Database (Section 10.2). It answers the Bitcoin timestamp query:

> *"Given a Metadata Bundle CID, return the Bitcoin transaction that proves the Bundle Hash existed at a specific block height."*

The Anchor Record is the convenience layer that makes the on-chain timestamp proof queryable without requiring every verifier to scan the Bitcoin blockchain. The proof itself is the Bundle Hash in the confirmed Bitcoin block — the Anchor Record simply makes that proof accessible.

The full two-stage process by which Bundle Hashes are computed and committed to Bitcoin is described in Section 3.2. This section specifies the Anchor Record schema and its operational role within the Records Database.

---

## The Trust Hierarchy

Understanding what the Anchor Record is — and what it is not — is essential to correctly implementing verification.

**The authoritative proof** is the Bundle Hash in the Bitcoin block. Immutable, globally verifiable, requiring no intermediary. Anyone with a Bitcoin node can verify it independently.

**The Anchor Record** is a lookup mechanism. It is published by the node that performed the channel operation, signed by that node's LYW, and replicated across the Records Database. It is not independently verifiable without querying Bitcoin — it points to the verification. The trust model is: verify the Anchor Record by checking it against Bitcoin, not by trusting the node that published it.

---

## JSON Schema: Anchor Record

```json
{
  // REQUIRED FIELDS

  "metadata_bundle_cid": "QmBundle...",    // CID of the Metadata Bundle being anchored
                                            // Primary lookup key: given a Metadata Bundle CID,
                                            // retrieve this record

  "bundle_hash":         "0xABCDEF...",    // SHA-256 hash of (Content CID + Metadata Wrapper)
                                            // This is the value embedded in the Bitcoin OP_RETURN output
                                            // Recompute locally to verify: Hash(content_cid + metadata_wrapper)

  "wallet_address":      "lnbc...",        // Lightning address of the LYW that performed the channel operation
                                            // Critical linking field: must match protocol_metadata.wallet_address
                                            // in the Metadata Wrapper, proving the anchoring node is the
                                            // same LYW managing the content's economics

  "tx_id":               "a1b2c3...",      // Bitcoin transaction ID containing the OP_RETURN output
                                            // Use this to retrieve the transaction from any Bitcoin full node

  "block_height":        875432,            // Bitcoin block height where the transaction was confirmed
                                            // This is the timestamp — content existed no later than this block

  "published_by":        "node_id...",     // Node ID of the Records Database participant that published
                                            // this Anchor Record. May be different from the LYW node
                                            // in cases where a relay node publishes on behalf of the LYW.

  "signature":           "ed25519:...",    // LYW's cryptographic signature over the Anchor Record fields
                                            // Verifiable against the public key of wallet_address

  // OPTIONAL EXTENSION FIELDS

  "op_return_data":      "0xABCDEF...",    // Raw hex of the OP_RETURN output data — enables
                                            // verification without fetching the full transaction

  "anchor_type":         "channel_funding" // Type of Bitcoin transaction used for anchoring
                                            // Valid values: "channel_funding" (zero marginal cost,
                                            // piggybacked on LYW channel operation),
                                            // "dedicated_anchor" (standalone OP_RETURN transaction
                                            // initiated for immediate finality)
}
```

---

## Field Reference

**`metadata_bundle_cid`** — The CID of the Metadata Bundle being anchored. This is the primary lookup key for the Anchor Records table. A query by `metadata_bundle_cid` returns all Anchor Records for that bundle — there may be more than one if the content has been anchored multiple times (see Multiple Anchors below).

**`bundle_hash`** — The value embedded in the Bitcoin OP_RETURN output. Computed as `SHA-256(Content CID + Metadata Wrapper)` and finalized before any Bitcoin transaction exists. Verification requires recomputing this hash locally from the Metadata Wrapper (without any anchor details — those live in the Anchor Record, not the Metadata Wrapper) and confirming it matches the OP_RETURN data in the referenced transaction.

**`wallet_address`** — The linking field that ties the Anchor Record to the content's economic layer. It must match the `protocol_metadata.wallet_address` field in the Metadata Wrapper, proving that the same LYW managing the content's yield and host payments is the one that committed the Bundle Hash to Bitcoin. The signature on the Anchor Record is verifiable against this address's public key.

**`tx_id`** — The Bitcoin transaction containing the OP_RETURN output. Retrieve this transaction from any Bitcoin full node using the standard `getrawtransaction` RPC call, then extract the OP_RETURN output and compare the data against `bundle_hash`.

**`block_height`** — The block height at which the transaction was confirmed. This is the timestamp bound: the content existed, in its exact form encoded by the Bundle Hash, no later than this block. Bitcoin block timestamps are within ~2 hours of real time; block height is the canonical, manipulation-resistant measure.

**`published_by`** — The node that wrote this Anchor Record to the Records Database. The anchoring LYW and the publishing node are typically the same, but a LYW may delegate publication to a relay node. The `signature` over the record is always from `wallet_address`, not `published_by`.

---

## Verification Sequence

The six-step verification process for a timestamp claim:

```
1. Retrieve the Metadata Bundle using metadata_bundle_cid
2. Extract the Metadata Wrapper (without anchor details)
3. Recompute: bundle_hash = SHA-256(content_cid + serialized_metadata_wrapper)
4. Query Records Database for Anchor Record by metadata_bundle_cid
5. Retrieve Bitcoin transaction using tx_id from any Bitcoin full node
6. Extract OP_RETURN data and compare against recomputed bundle_hash
```

If the hashes match, the content existed no later than `block_height`. No trust in any service is required — the verification requires only a Bitcoin node and the content itself.

---

## Multiple Anchors

A Metadata Bundle may have more than one Anchor Record. This occurs when:

- The creator reanchors the same Bundle Hash in a later channel operation (valid — additional proofs strengthen the timestamp claim)
- Multiple nodes independently anchor the same Bundle Hash (valid — independent corroboration)

The Records Database stores all valid Anchor Records for a given `metadata_bundle_cid`. The earliest `block_height` across all records is the binding timestamp claim. Deduplication applies only to exact duplicates (same `metadata_bundle_cid` + same `tx_id`).

---

## Intermediate State

An Anchor Record does not exist immediately after a Metadata Bundle is published. The Bundle Hash waits for the next natural Lightning channel operation on the creator's LYW before being committed to Bitcoin. This is a valid intermediate state — the Metadata Bundle exists and is queryable, and content is fully live and payable, but has not yet received its Bitcoin timestamp proof.

Applications should handle a `404` response from the Anchor Records query gracefully. The correct response is not to treat the content as unverified — it is to treat the timestamp proof as pending. The content's existence is still provable by its Metadata Bundle CID; only the Bitcoin timestamp is absent.

---

## Replication Behavior

Anchor Records are append-only. A node stores every valid Anchor Record it receives and forwards it to peers. There are no conflicts — each Anchor Record is uniquely identified by its `metadata_bundle_cid` and `tx_id`. Duplicate records received from multiple peers are deduplicated by this composite key and stored once.

The economic incentive for Anchor Record persistence is the same as for all Records Database tables: participation in the discovery layer earns revenue through AtomicSats exchanges, and that incentive covers the full database without requiring a separate economic wrapper per record type.

---


