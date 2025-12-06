This guide outlines the four primary steps for implementing the hybrid timestamping mechanism described in Section 3.2.2.

-----

# 🛠️ Developer Implementation Guide: Bitcoin Timestamping Anchor

This guide details the JavaScript functions and logic required to anchor content and metadata to the Bitcoin blockchain using a **Lightning Channel Funding Transaction** and maintain an **Application-Level Hash Chain**.

## Step 1: Content Upload & Initial Metadata Creation

This function handles uploading the raw content, creating the initial metadata bundle, and computing the cryptographic hash required for the on-chain anchor.

```javascript
/**
 * Uploads content and computes the anchor hash for timestamping.
 * @param {File} file - The raw content file.
 * @param {Object} metadata - Creator, license, and other descriptive data.
 * @returns {Object} { bundle, anchorHash }
 */
async function uploadToIPFSSats(file, metadata) {
  // 1. Upload raw content to IPFS
  const contentCID = await ipfs.add(file);
  
  // 2. Create the initial metadata bundle
  const bundle = {
    content_cid: contentCID,
    parent_bundle_hash: metadata.parentHash || null, // Links to previous work
    creator: metadata.creator,
    license: metadata.license,
    // ... other application-specific fields
  };
  
  // 3. Compute combined hash for blockchain anchor
  // NOTE: This SHA256 ensures both content and metadata structure are immutably timestamped.
  const anchorData = contentCID + JSON.stringify(bundle);
  const anchorHash = SHA256(anchorData); 
  
  return { bundle, anchorHash };
}
```

-----

## Step 2: Open Lightning Channel with OP\_RETURN

This function constructs the Bitcoin transaction, embedding the `anchorHash` into the $OP\_RETURN$ output while simultaneously funding the Lightning Yield Wallet (LYW).

```javascript
/**
 * Funds the LYW via a Bitcoin transaction and embeds the anchor hash.
 * @param {number} amountSats - Amount to fund the Lightning channel (in sats).
 * @param {string} anchorHash - The SHA256 hash computed in Step 1.
 * @returns {Object} Bitcoin transaction confirmation details.
 */
async function fundLYWWithTimestamp(amountSats, anchorHash) {
  // Construct a standard Bitcoin transaction object
  const tx = new BitcoinTransaction(); 
  
  // Input: User's Unspent Transaction Output (UTXO)
  tx.addInput(userUTXO);
  
  // Output 1: Lightning channel funding output
  tx.addOutput(channelAddress, amountSats);
  
  // Output 2: OP_RETURN output with the timestamp hash
  // This is the core anchoring step.
  tx.addOutput(
    OP_RETURN,  
    Buffer.from(anchorHash, 'hex')
  );
  
  // Output 3: Change back to the user
  tx.addOutput(changeAddress, changeAmount);
  
  // Sign and broadcast the transaction
  tx.sign(privateKey);
  const txid = await bitcoin.broadcast(tx);
  
  // Wait for network confirmation (6 blocks for high finality)
  const block = await waitForConfirmation(txid);
  
  return {
    tx_id: txid,
    block_height: block.height,
    block_hash: block.hash,
    block_timestamp: block.timestamp
  };
}
```

-----

## Step 3: Update Metadata with Anchor Info

After the Bitcoin transaction is confirmed, the confirmed anchor details are written back into the metadata bundle, and the final bundle is uploaded to IPFS.

```javascript
/**
 * Finalizes the metadata bundle by adding the confirmed Bitcoin anchor details.
 * @param {Object} bundle - The initial metadata bundle from Step 1.
 * @param {Object} anchorInfo - Confirmation details from Step 2.
 * @param {string} anchorHash - The hash embedded in the OP_RETURN.
 * @returns {string} The final Metadata CID (QmMetadata...).
 */
async function finalizeMetadata(bundle, anchorInfo, anchorHash) {
  // Append the permanent blockchain record to the bundle
  bundle.bitcoin_anchor = {
    tx_id: anchorInfo.tx_id,
    block_height: anchorInfo.block_height,
    block_hash: anchorInfo.block_hash,
    block_timestamp: anchorInfo.block_timestamp,
    op_return_hash: anchorHash, // Storing the hash used for easy verification
    anchor_type: "channel_funding"
  };
  
  // Upload the final, complete metadata bundle to IPFS/IPNS
  const metadataCID = await ipfs.dag.put(bundle);
  
  return metadataCID;
}
```

-----

## Step 4: Verification Function

This function allows any user to independently verify the content's timestamp and integrity against the Bitcoin blockchain.

```javascript
/**
 * Verifies the timestamp of a content's metadata bundle.
 * @param {string} metadataCID - The CID of the final metadata bundle.
 * @returns {boolean} True if the hashes match and the timestamp is valid.
 */
async function verifyTimestamp(metadataCID) {
  // 1. Retrieve the full metadata bundle from IPFS
  const bundle = await ipfs.dag.get(metadataCID);
  
  // 2. Reconstruct the anchor hash locally
  const anchorData = bundle.content_cid + JSON.stringify(bundle);
  const recomputedHash = SHA256(anchorData);
  
  // 3. Query the Bitcoin blockchain using the stored transaction ID
  const tx = await bitcoin.getTransaction(bundle.bitcoin_anchor.tx_id);
  
  // 4. Extract the hash from the OP_RETURN output
  const opReturnOutput = tx.outputs.find(o => o.script.startsWith('OP_RETURN'));
  const blockchainHash = opReturnOutput.data.toString('hex');
  
  // 5. Verify match and report
  if (recomputedHash === blockchainHash) {
    console.log("✓ Timestamp verified!");
    console.log(`Content existed at block ${bundle.bitcoin_anchor.block_height}`);
    return true;
  } else {
    console.log("✗ Timestamp verification failed - data may be tampered");
    return false;
  }
}
```
