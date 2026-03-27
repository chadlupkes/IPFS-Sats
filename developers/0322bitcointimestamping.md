# Developer Implementation Guide: Bitcoin Timestamping Anchor

This guide implements the six-step Metadata Bundle creation and anchoring sequence described in Section 3.2 of the IPFS-Sats white paper. The sequence separates local computation from network publication, and separates the stable core record from the eventually consistent anchor proof.

**Critical architectural note:** The Bundle Hash is computed before any network activity occurs and before any Bitcoin transaction exists. The Anchor Record — which contains the Bitcoin transaction details — is a separate document published to the Records Database after confirmation. The Metadata Wrapper never contains its own anchor details. This separation eliminates the circular dependency present in earlier versions of the protocol.

---

## The Six-Step Sequence

```
Step 1: Hash content locally          → Content CID
Step 2: Assemble Metadata Wrapper     → Metadata Wrapper (local)
Step 3: Compute Bundle Hash           → Bundle Hash + Metadata Bundle CID (published)
Step 4: Anchor to Bitcoin             → txid + block height (asynchronous)
Step 5: Publish Anchor Record         → Records Database entry
Step 6: Verify                        → Independent verification by anyone
```

Steps 1–3 are local computation with no network dependency. Step 4 is asynchronous — the Bundle Hash waits for the next natural Lightning channel operation on the creator's LYW. Steps 5 and 6 follow confirmation.

---

## Step 1: Content Hashing (Local)

Hash the raw content to produce the Content CID. No network activity occurs at this step.

```javascript
/**
 * Hashes raw content to produce a Content CID.
 * IPFS is the reference implementation — any CID-compatible
 * content-addressed storage system is conforming.
 * @param {File} file - The raw content file.
 * @returns {string} contentCID - The content identifier.
 */
async function hashContent(file) {
  // IPFS reference implementation
  const contentCID = await ipfs.add(file, { onlyHash: true });
  
  // Make content available to the network
  await ipfs.add(file);
  
  return contentCID;
}
```

---

## Step 2: Metadata Wrapper Assembly (Local)

Assemble all knowable fields into the Metadata Wrapper. **Do not include Bitcoin transaction details at this step — they do not yet exist.** Including them would create a circular dependency: the Bundle Hash cannot be computed until the Metadata Wrapper is complete, but the transaction cannot exist until the Bundle Hash is computed.

```javascript
/**
 * Assembles the Metadata Wrapper from all knowable fields.
 * Bitcoin anchor details are NOT included here — they live in
 * the Anchor Record, published separately after confirmation.
 *
 * @param {string} contentCID - From Step 1.
 * @param {Object} params - Creator, license, governance, descriptive metadata.
 * @returns {Object} metadataWrapper
 */
function assembleMetadataWrapper(contentCID, params) {
  return {
    // 1. Content reference
    content_cid: contentCID,

    // 2. Timestamp proof (creation time only — Bitcoin anchor added later via Anchor Record)
    timestamp_proof: {
      creation_time: Math.floor(Date.now() / 1000),
      provenance_chain: {
        parent_bundle_hash: params.parentBundleHash || null,
        is_fork: params.parentBundleHash ? true : false,
        derivative_type: params.derivativeType || null,
        upstream_percentage: params.upstreamPercentage || null
      }
    },

    // 3. Protocol metadata
    protocol_metadata: {
      version: "0.4",
      lyw_address: params.lywAddress,        // Lightning address for payments
      dao_cid: params.daoCID,                // DAO Configuration Object CID
      smart_contract_hash: params.contractHash
    },

    // 4. Creator identity and signature (signed over Bundle Hash in Step 3)
    creator: {
      did: params.creatorDID,
      public_key: params.publicKey
      // signature added in Step 3 after Bundle Hash is computed
    },

    // 5. License terms
    license: {
      type: params.licenseType,
      terms_cid: params.termsCID,
      commercial_use: params.commercialUse,
      attribution_required: params.attributionRequired
    },

    // 6. Descriptive metadata
    title: params.title,
    description: params.description,
    tags: params.tags || [],
    media_type: params.mediaType,
    language: params.language || "en"
  };
}
```

---

## Step 3: Bundle Hash Computation and Publication (Local → Network)

Compute the Bundle Hash from the Content CID and the Metadata Wrapper. This hash is final and stable — it will not change. Add the creator's signature over the Bundle Hash. Publish the Metadata Bundle to the network.

```javascript
/**
 * Computes the Bundle Hash and publishes the Metadata Bundle.
 * The Bundle Hash is the value that will be committed to Bitcoin.
 * The Metadata Bundle CID is the primary identifier for all future interactions.
 *
 * Bundle Hash = Hash(Content CID + Metadata Wrapper)
 *
 * @param {string} contentCID - From Step 1.
 * @param {Object} metadataWrapper - From Step 2.
 * @param {Function} sign - Creator's signing function (signs over Bundle Hash).
 * @returns {Object} { bundleHash, metadataBundleCID }
 */
async function computeAndPublish(contentCID, metadataWrapper, sign) {
  // Serialize the Metadata Wrapper deterministically (dag-cbor recommended)
  const serializedWrapper = dagCBOR.encode(metadataWrapper);

  // Compute Bundle Hash: Hash(Content CID + Metadata Wrapper)
  const bundleHash = SHA256(contentCID + serializedWrapper);

  // Add creator signature over the Bundle Hash
  metadataWrapper.creator.signature = await sign(bundleHash);

  // Publish Metadata Bundle to the network
  // The CID is deterministic — publishing the same Metadata Wrapper
  // always produces the same Metadata Bundle CID
  const metadataBundleCID = await ipfs.dag.put({
    content_cid: contentCID,
    metadata_wrapper: metadataWrapper
  });

  return { bundleHash, metadataBundleCID };
}
```

**At the end of Step 3:**
- The `bundleHash` is ready to be committed to Bitcoin
- The `metadataBundleCID` is the permanent identifier for this content
- Both are stable and will not change regardless of what happens next

---

## Step 4: Bitcoin Anchoring (Asynchronous)

Embed the Bundle Hash in a Bitcoin transaction via OP_RETURN. This step is **asynchronous** — the Bundle Hash waits for the next natural Lightning channel operation on the creator's LYW. There is no protocol urgency. Creators requiring immediate finality may initiate a dedicated anchor transaction.

```javascript
/**
 * Embeds the Bundle Hash in a Bitcoin transaction via OP_RETURN.
 * This may piggyback on a Lightning channel operation (zero marginal cost)
 * or be a dedicated anchor transaction.
 *
 * @param {string} bundleHash - From Step 3.
 * @param {string} lywChannelAddress - The LYW Lightning channel funding address.
 * @param {number} fundingAmountSats - Channel funding amount (if channel operation).
 * @returns {Object} { txid, blockHeight, blockHash }
 */
async function anchorToBitcoin(bundleHash, lywChannelAddress, fundingAmountSats) {
  const tx = new BitcoinTransaction();

  // Input: creator's UTXO
  tx.addInput(userUTXO);

  // Output 1: Lightning channel funding (if this is a channel operation)
  // Omit if this is a dedicated anchor-only transaction
  if (fundingAmountSats > 0) {
    tx.addOutput(lywChannelAddress, fundingAmountSats);
  }

  // Output 2: OP_RETURN embedding the Bundle Hash
  // 32 bytes — well within the 83-byte OP_RETURN limit
  tx.addOutput(OP_RETURN, Buffer.from(bundleHash, 'hex'));

  // Output 3: Change
  tx.addOutput(changeAddress, calculateChange(tx));

  tx.sign(privateKey);
  const txid = await bitcoin.broadcast(tx);

  // Wait for confirmation
  // 1 block is sufficient for most use cases
  // 6 blocks for high-value institutional content
  const block = await waitForConfirmation(txid, { confirmations: 1 });

  return {
    txid,
    blockHeight: block.height,
    blockHash: block.hash
  };
}
```

---

## Step 5: Anchor Record Publication

After Bitcoin confirmation, publish the Anchor Record to the Records Database. The Anchor Record is the lookup mechanism that makes the on-chain proof conveniently queryable — it is not the proof itself. The proof is the Bundle Hash in the Bitcoin block.

```javascript
/**
 * Publishes the Anchor Record to the Records Database.
 * This is a separate document from the Metadata Bundle.
 * It links the Metadata Bundle CID to the Bitcoin transaction proof.
 *
 * @param {string} metadataBundleCID - From Step 3.
 * @param {string} bundleHash - From Step 3.
 * @param {Object} anchorInfo - txid, blockHeight from Step 4.
 * @param {Object} lyw - LYW wallet address and signing function.
 * @returns {string} anchorRecordCID
 */
async function publishAnchorRecord(metadataBundleCID, bundleHash, anchorInfo, lyw) {
  const anchorRecord = {
    metadata_bundle_cid: metadataBundleCID,
    bundle_hash:         bundleHash,
    wallet_address:      lyw.address,
    tx_id:               anchorInfo.txid,
    block_height:        anchorInfo.blockHeight,
    published_by:        nodeID,
    signature:           await lyw.sign(bundleHash)
  };

  // Publish to the Records Database
  // The Records Database is a distributed permissionless layer —
  // any conforming Records Database node will accept and replicate this record
  const anchorRecordCID = await recordsDatabase.publish(anchorRecord);

  return anchorRecordCID;
}
```

**What the Anchor Record is and is not:**
- ✓ A lookup mechanism: given a Metadata Bundle CID, retrieve the Bitcoin proof
- ✓ Eventually consistent: settles at its own pace, driven by economic conditions
- ✗ Not the proof itself: the proof is the Bundle Hash in the confirmed Bitcoin block
- ✗ Not part of the Metadata Wrapper: the Metadata Wrapper never contains its own anchor details

---

## Step 6: Verification

Independent verification requires only a Bitcoin node and access to the Records Database. No trust in any intermediary is required.

```javascript
/**
 * Verifies the timestamp of a Metadata Bundle.
 * Can be performed by anyone with a Bitcoin node and Records Database access.
 *
 * Verification checks two things:
 * 1. The Bundle Hash in the Anchor Record matches a recomputed hash
 *    of the Metadata Bundle content
 * 2. That Bundle Hash exists in the referenced Bitcoin transaction's OP_RETURN output
 *
 * @param {string} metadataBundleCID - The CID of the Metadata Bundle to verify.
 * @returns {Object} { verified: boolean, blockHeight: number, message: string }
 */
async function verifyTimestamp(metadataBundleCID) {
  // 1. Retrieve the Metadata Bundle
  const metadataBundle = await ipfs.dag.get(metadataBundleCID);
  const { content_cid, metadata_wrapper } = metadataBundle;

  // 2. Recompute the Bundle Hash locally
  // Hash(Content CID + Metadata Wrapper) — same computation as Step 3
  // NOTE: Hash the Metadata Wrapper WITHOUT any anchor details,
  // because anchor details live in the Anchor Record, not the Metadata Wrapper
  const serializedWrapper = dagCBOR.encode(metadata_wrapper);
  const recomputedBundleHash = SHA256(content_cid + serializedWrapper);

  // 3. Retrieve the Anchor Record from the Records Database
  const anchorRecord = await recordsDatabase.getByMetadataBundleCID(metadataBundleCID);
  if (!anchorRecord) {
    return {
      verified: false,
      message: "No Anchor Record found — content may not yet be anchored to Bitcoin"
    };
  }

  // 4. Verify the Bundle Hash in the Anchor Record matches recomputed hash
  if (recomputedBundleHash !== anchorRecord.bundle_hash) {
    return {
      verified: false,
      message: "Bundle Hash mismatch — Metadata Bundle may have been tampered with"
    };
  }

  // 5. Retrieve the Bitcoin transaction
  const tx = await bitcoin.getTransaction(anchorRecord.tx_id);

  // 6. Extract the Bundle Hash from the OP_RETURN output
  const opReturnOutput = tx.outputs.find(o => o.script.startsWith('OP_RETURN'));
  if (!opReturnOutput) {
    return {
      verified: false,
      message: "No OP_RETURN output found in referenced Bitcoin transaction"
    };
  }
  const onChainHash = opReturnOutput.data.toString('hex');

  // 7. Verify the on-chain hash matches
  if (recomputedBundleHash !== onChainHash) {
    return {
      verified: false,
      message: "On-chain hash does not match Bundle Hash — anchor may be fraudulent"
    };
  }

  return {
    verified: true,
    blockHeight: anchorRecord.block_height,
    message: `✓ Verified. Content existed at Bitcoin block height ${anchorRecord.block_height}`
  };
}
```

---

## Summary

| Step | Location | Output | Network Activity |
|---|---|---|---|
| 1. Hash content | Local | Content CID | Content published to peers |
| 2. Assemble Metadata Wrapper | Local | Metadata Wrapper | None |
| 3. Compute Bundle Hash | Local → Network | Bundle Hash + Metadata Bundle CID | Metadata Bundle published |
| 4. Anchor to Bitcoin | Bitcoin network | txid + block height | Bitcoin transaction broadcast |
| 5. Publish Anchor Record | Records Database | Anchor Record CID | Records Database write |
| 6. Verify | Any Bitcoin node + Records Database | Verification result | Read-only queries |

**The two proofs are distinct:**
- **Bitcoin proof:** The Bundle Hash exists in a confirmed Bitcoin block — proves the content existed at that block height. Verifiable by any Bitcoin node. Cannot be forged.
- **Availability proof:** The content is currently retrievable via AtomicSats exchange — proves the content is live. Verifiable by initiating a WANT message.

Both proofs together constitute the Right to Verify.
