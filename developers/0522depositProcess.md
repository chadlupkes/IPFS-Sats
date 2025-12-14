### 5.2.2 Deposit Process: Atomic Initialization Flow

The initialization process atomically links the content, the wallet, and the yield generation mechanism through a multi-step, anchored transaction process.

```javascript
/**
 * Initializes the LYW, creates the multi-sig wallet, anchors to Bitcoin, and starts yield generation.
 * @param {string} contentCID - The Content ID of the data being made persistent.
 * @param {number} depositAmount - The initial sats deposit for the LYW.
 */
async function initializeLYW(contentCID, depositAmount) {
  // 1. Create metadata structure (DAO policies, initial rules)
  const metadata = {
    content_cid: contentCID,
    // ... other metadata fields
  };
  
  // 2. Generate three-key multi-sig wallet
  const wallet = await createMultiSigWallet({
    key1: deriveFromCID(contentCID), // Content Key (K1)
    key2: creator.publicKey,         // Human Control Key (K2)
    key3: await generateSmartContractKey() // Execution Key (K3)
  });
  
  // 3. Open Lightning channel with deposit (anchors funds and starts yield principal)
  // This transaction also anchors content hash via OP_RETURN
  const channelTx = await openLightningChannel({
    amount: depositAmount,
    op_return: hash(contentCID + JSON.stringify(metadata)),
    wallet: wallet.address // The channel UTXO is controlled by the multi-sig
  });
  
  // 4. Wait for Bitcoin confirmation
  await waitForConfirmation(channelTx.txid);
  
  // 5. Extract timestamp from Bitcoin block (Worst-Case Sovereignty Proof)
  const block = await getBlockForTx(channelTx.txid);
  metadata.bitcoin_anchor = {
    tx_id: channelTx.txid,
    block_height: block.height,
    block_hash: block.hash,
    block_timestamp: block.timestamp
  };
  
  // 6. Initialize LYW structure
  const lyw = {
    wallet_address: wallet.lightning_address,
    balance: depositAmount,
    compound_pool: 0,
    created_at: Date.now(),
    last_distribution: null,
    yield_sources: []
  };
  
  // 7. Set up liquidity lease (Yield Generation)
  // Key 3 automatically executes the liquidity leasing transaction
  const lease = await createLiquidityLease({
    amount: depositAmount,
    duration: 30, // days
    marketplace: "Lightning Pool"
  });
  
  lyw.yield_sources.push({
    type: "liquidity_lease",
    amount: depositAmount,
    expected_apy: lease.rate,
    started_at: Date.now()
  });
  
  // 8. Finalize metadata with LYW info
  metadata.ipfs_sats_metadata.wallet_address = lyw.wallet_address;
  
  // 9. Upload metadata to IPFS
  const metadataCID = await ipfs.dag.put(metadata);
  
  // 10. System is now live
  return {
    content_cid: contentCID,
    metadata_cid: metadataCID,
    lyw: lyw,
    wallet: wallet,
    status: "active",
    estimated_runway: calculateRunway(depositAmount, lyw)
  };
}
```

