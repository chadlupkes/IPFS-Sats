# Developer Implementation Guide: LYW Initialization and Content Publication

This guide implements the complete initialization sequence for publishing content to IPFS-Sats: creating the LYW, assembling and publishing the Metadata Bundle, anchoring the Bundle Hash to Bitcoin, and writing the Anchor Record to the Records Database.

**Critical sequencing requirement:** The LYW must be initialized *before* the Metadata Wrapper is assembled, because the `protocol_metadata.wallet_address` field (the LYW's Lightning address) must be included in the Metadata Wrapper before the Bundle Hash is computed. The Bundle Hash must be stable and final before anything touches Bitcoin.

---

## Initialization Sequence

```
Step 1: Initialize LYW                 → lyw_address (Lightning address)
Step 2: Hash content locally           → Content CID
Step 3: Assemble Metadata Wrapper      → Metadata Wrapper (includes lyw_address)
Step 4: Compute Bundle Hash            → Bundle Hash + Metadata Bundle CID (published)
Step 5: Anchor Bundle Hash to Bitcoin  → txid + block_height (asynchronous)
Step 6: Publish Anchor Record          → Records Database entry
```

Steps 1–4 complete before any Bitcoin transaction. Step 5 is asynchronous — it waits for the next natural Lightning channel operation on the LYW. Step 6 follows confirmation.

---

## Step 1: Initialize the LYW

The LYW is a Lightning node. Initialize it first — its Lightning address is needed in the Metadata Wrapper. The three protocol keys are established during initialization.

```javascript
/**
 * Initializes the Lightning Yield Wallet (LYW) for a piece of content.
 * The LYW is a Lightning node — it generates yield through channel
 * deployment activity (liquidity leasing, routing fees), not through
 * passive deposit in an external marketplace.
 *
 * The three protocol keys:
 *   Key 1 (Content Binding): Derived from the Content CID — cryptographically
 *                             binds the wallet to specific content
 *   Key 2 (Human Authority): Creator's public key — governance and override authority
 *   Key 3 (Execution Key):   Derived from Key 1 + contract rules — automated operations
 *
 * @param {string} contentCID - Content CID (from Step 2, passed back here or pre-computed)
 * @param {Object} creator - Creator's keys and DID
 * @param {Object} contractRules - Initial DAO Configuration Object parameters
 * @returns {Object} { lyw_address, key1, key2, key3, state_ledger }
 */
async function initializeLYW(contentCID, creator, contractRules) {
  // Derive Key 1 from the Content CID
  const key1 = deriveKey1FromCID(contentCID);

  // Key 2 is the creator's existing key pair
  const key2 = {
    public: creator.publicKey,
    did:    creator.did
  };

  // Derive Key 3 from Key 1 seed + contract rules hash
  const contractHash = SHA256(JSON.stringify(contractRules));
  const key3 = generateKey3(key1.seed, contractHash);

  // Initialize the LYW as a Lightning node
  const lyw = await lightning.createNode({
    key1: key1.public,
    key2: key2.public,
    key3: key3.public
  });

  // Initialize LYW State Ledger (Section 10.5)
  const stateLedger = {
    last_updated_block: await getCurrentBlockHeight(),
    liquidity_yield: {
      deployed_balance_sats: 0,
      leasing_income_sats:   0,
      routing_fee_income_sats: 0,
      yield_rate_ppm:        0,
      cycle_start_block:     await getCurrentBlockHeight(),
      cycle_income_sats:     0
    },
    access_income: {
      zap_income_sats:          0,
      access_fee_income_sats:   0,
      fork_royalty_income_sats: 0,
      cycle_income_sats:        0
    },
    expenses: {
      host_payments_sats:       0,
      fork_royalty_outflow_sats: 0,
      cycle_expenses_sats:      0,
      drawdown_mode:            true  // True until available_sats covers hosting costs
    },
    distribution: {
      last_distribution_block:  null,
      distributed_sats:         0,
      compound_sats:            0,
      distribution_history_cid: null
    },
    balance: {
      available_sats:         0,
      total_sats:             0,
      sunset_threshold_sats:  contractRules.sunset_threshold_sats || 1000,
      cycles_at_threshold:    0
    }
  };

  await updateLYW({ address: lyw.lightning_address, state_ledger: stateLedger });

  return {
    lyw_address:  lyw.lightning_address,
    key1, key2, key3,
    state_ledger: stateLedger
  };
}
```

---

## Step 2: Hash Content (Local)

```javascript
/**
 * Hashes raw content to produce the Content CID.
 * No network activity required at this step.
 * IPFS is the reference implementation.
 * @param {File} file
 * @returns {string} contentCID
 */
async function hashContent(file) {
  const contentCID = await ipfs.add(file, { onlyHash: true });
  await ipfs.add(file); // Make available to peers
  return contentCID;
}
```

---

## Step 3: Assemble Metadata Wrapper (Local)

All knowable fields — including `lyw_address` from Step 1 — are assembled now. **Bitcoin anchor details are not included.** They do not yet exist, and including them would create a circular dependency: the Bundle Hash cannot be stable until the Metadata Wrapper is complete, but the transaction cannot exist until the Bundle Hash is stable.

```javascript
/**
 * Assembles the Metadata Wrapper. Requires lyw_address from Step 1.
 * @param {string} contentCID - From Step 2.
 * @param {string} lyw_address - From Step 1.
 * @param {string} dao_cid - CID of the initial DAO Configuration Object.
 * @param {Object} params - License, creator, descriptive metadata.
 * @returns {Object} metadataWrapper
 */
function assembleMetadataWrapper(contentCID, lyw_address, dao_cid, params) {
  return {
    content_cid: contentCID,

    timestamp_proof: {
      creation_time: Math.floor(Date.now() / 1000),
      provenance_chain: {
        parent_bundle_hash: params.parentBundleHash || null,
        is_fork:            params.parentBundleHash ? true : false,
        derivative_type:    params.derivativeType || null,
        upstream_percentage: params.upstreamPercentage || null
      }
    },

    // lyw_address MUST be set here — it is part of the Bundle Hash computation
    protocol_metadata: {
      version:             "0.4",
      wallet_address:      lyw_address,
      dao_cid:             dao_cid,
      smart_contract_hash: params.contractHash
    },

    creator: {
      did:        params.creatorDID,
      public_key: params.publicKey
      // signature added in Step 4 after Bundle Hash is computed
    },

    license: {
      type:                 params.licenseType,
      terms_cid:            params.termsCID,
      commercial_use:       params.commercialUse,
      attribution_required: params.attributionRequired
    },

    title:       params.title,
    description: params.description,
    tags:        params.tags || [],
    media_type:  params.mediaType,
    language:    params.language || "en"
  };
}
```

---

## Step 4: Compute Bundle Hash and Publish (Local → Network)

```javascript
/**
 * Computes the Bundle Hash and publishes the Metadata Bundle.
 * Bundle Hash = Hash(Content CID + Metadata Wrapper)
 * This hash is final and stable — it is the value that will be committed to Bitcoin.
 *
 * @param {string} contentCID
 * @param {Object} metadataWrapper
 * @param {Function} sign - Creator's signing function
 * @returns {Object} { bundleHash, metadataBundleCID }
 */
async function computeAndPublish(contentCID, metadataWrapper, sign) {
  const serializedWrapper = dagCBOR.encode(metadataWrapper);

  // Bundle Hash is final — computed before any network activity
  const bundleHash = SHA256(contentCID + serializedWrapper);

  // Add creator signature over the Bundle Hash
  metadataWrapper.creator.signature = await sign(bundleHash);

  // Publish Metadata Bundle
  const metadataBundleCID = await ipfs.dag.put({
    content_cid:      contentCID,
    metadata_wrapper: metadataWrapper
  });

  return { bundleHash, metadataBundleCID };
}
```

---

## Step 5: Fund LYW and Anchor Bundle Hash to Bitcoin (Asynchronous)

The Bundle Hash waits for the next natural Lightning channel operation on the LYW. There is no protocol urgency. The Bundle Hash can wait indefinitely for the right moment.

```javascript
/**
 * Funds the LYW by opening a Lightning channel and embeds the Bundle Hash
 * in the funding transaction's OP_RETURN output.
 *
 * This step is asynchronous — it executes when the LYW performs its next
 * channel operation. Creators requiring immediate finality may initiate a
 * dedicated anchor transaction instead.
 *
 * @param {string} lyw_address - LYW Lightning address from Step 1.
 * @param {number} fundingAmountSats - Initial LYW funding in sats.
 * @param {string} bundleHash - From Step 4.
 * @returns {Object} { txid, blockHeight, blockHash }
 */
async function fundLYWAndAnchor(lyw_address, fundingAmountSats, bundleHash) {
  const tx = new BitcoinTransaction();

  tx.addInput(userUTXO);

  // Output 1: Lightning channel funding — this is the LYW's yield principal
  // The LYW will deploy this capital through channel activity to generate yield
  tx.addOutput(lyw_address, fundingAmountSats);

  // Output 2: OP_RETURN embedding the Bundle Hash
  // 32 bytes — well within the 83-byte OP_RETURN limit
  tx.addOutput(OP_RETURN, Buffer.from(bundleHash, 'hex'));

  tx.addOutput(changeAddress, calculateChange(tx));
  tx.sign(privateKey);

  const txid = await bitcoin.broadcast(tx);
  const block = await waitForConfirmation(txid, { confirmations: 1 });

  // Update LYW State Ledger with funded balance
  const lyw = await getLYW(lyw_address);
  lyw.state_ledger.balance.available_sats       = fundingAmountSats;
  lyw.state_ledger.balance.total_sats            = fundingAmountSats;
  lyw.state_ledger.liquidity_yield.deployed_balance_sats = fundingAmountSats;
  await updateLYW(lyw);

  return {
    txid,
    blockHeight: block.height,
    blockHash:   block.hash
  };
}
```

**After this step:**
- The Bundle Hash is confirmed in a Bitcoin block — the timestamp proof exists
- The LYW has funded capital available for deployment
- `drawdown_mode` remains `true` until the LYW's yield begins covering host costs

---

## Step 6: Publish Anchor Record

```javascript
/**
 * Publishes the Anchor Record to the Records Database.
 * The Anchor Record is a separate document from the Metadata Bundle.
 * It links the Metadata Bundle CID to the Bitcoin proof.
 *
 * @param {string} metadataBundleCID - From Step 4.
 * @param {string} bundleHash - From Step 4.
 * @param {Object} anchorInfo - txid, blockHeight from Step 5.
 * @param {Object} lyw - LYW address and signing function.
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

  const anchorRecordCID = await recordsDatabase.publish(anchorRecord);
  return anchorRecordCID;
}
```

---

## Complete Initialization Orchestration

```javascript
/**
 * Orchestrates the complete content publication and LYW initialization sequence.
 * @param {File} file
 * @param {Object} creator
 * @param {Object} params - License, governance, descriptive metadata
 * @param {number} fundingAmountSats - Initial LYW funding
 * @returns {Object} Publication record
 */
async function publishContent(file, creator, params, fundingAmountSats) {
  // Steps 1–2: Initialize LYW and hash content (order matters — lyw_address needed in Step 3)
  const contentCID = await hashContent(file);
  const { lyw_address, key1, key2, key3 } = await initializeLYW(
    contentCID,
    creator,
    params.contractRules
  );

  // Step 3: Assemble Metadata Wrapper with lyw_address included
  const metadataWrapper = assembleMetadataWrapper(
    contentCID,
    lyw_address,
    params.dao_cid,
    params
  );

  // Step 4: Compute Bundle Hash and publish Metadata Bundle
  const { bundleHash, metadataBundleCID } = await computeAndPublish(
    contentCID,
    metadataWrapper,
    creator.sign
  );

  // Step 5: Fund LYW and anchor Bundle Hash to Bitcoin (asynchronous)
  const anchorInfo = await fundLYWAndAnchor(
    lyw_address,
    fundingAmountSats,
    bundleHash
  );

  // Step 6: Publish Anchor Record to Records Database
  const anchorRecordCID = await publishAnchorRecord(
    metadataBundleCID,
    bundleHash,
    anchorInfo,
    { address: lyw_address, sign: key3.sign }
  );

  return {
    content_cid:         contentCID,
    metadata_bundle_cid: metadataBundleCID,
    bundle_hash:         bundleHash,
    lyw_address,
    anchor_record_cid:   anchorRecordCID,
    block_height:        anchorInfo.blockHeight,
    status:              "active",
    drawdown_mode:       true  // Host payments begin once yield covers hosting costs
  };
}
```

---

## Initialization Summary

| Step | Location | Output | Bitcoin Activity |
|---|---|---|---|
| 1. Initialize LYW | Local + Lightning | `lyw_address`, three keys, State Ledger | None |
| 2. Hash content | Local | Content CID | None |
| 3. Assemble Metadata Wrapper | Local | Metadata Wrapper | None |
| 4. Compute Bundle Hash | Local → Network | Bundle Hash, Metadata Bundle CID | None |
| 5. Fund LYW + anchor | Bitcoin | txid, block height | Funding tx + OP_RETURN |
| 6. Publish Anchor Record | Records Database | Anchor Record CID | None |

Content is live and timestamped after Step 4. Bitcoin proof exists after Step 5. The Anchor Record is the convenience layer that makes the proof queryable — not the proof itself.
