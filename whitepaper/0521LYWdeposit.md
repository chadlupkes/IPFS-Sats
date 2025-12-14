## 5.2 The Self-Sustaining Model ⚙️

The Lightning Yield Wallet creates a perpetual motion machine for content persistence—not in the thermodynamic sense, but in economic terms. Once set in motion with an initial deposit, the system generates enough yield to cover its own operating costs indefinitely, with surplus compounding back to increase future yield.

This section details the operational mechanics: how the system starts, how it runs, how it self-corrects, and what happens when conditions change.

### 5.2.1 Initial Deposit: Bootstrapping the Economic Engine

The initial deposit must be large enough to generate sufficient yield to cover hosting costs while building a compounding surplus. The minimum viable deposit depends on three factors:

1.  **Content size** (storage requirements)
2.  **Expected yield rate** (market conditions)
3.  **Desired runway** (margin of safety)

#### Calculation Formula

The protocol uses the following logic to determine the required capital:

```javascript
function calculateMinimumDeposit(contentSizeGB, hostCount, safetyMultiplier = 2) {
  // Monthly hosting cost per GB per host (market rate)
  const costPerGBPerHost = 100; // sats
  
  // Total monthly hosting cost
  const monthlyHostCost = contentSizeGB * hostCount * costPerGBPerHost;
  
  // Conservative yield rate (low estimate for safety)
  const conservativeYieldAPY = 0.10; // 10% annual
  const monthlyYieldRate = conservativeYieldAPY / 12;
  
  // Minimum deposit to cover costs
  const minimumDeposit = monthlyHostCost / monthlyYieldRate;
  
  // Apply safety multiplier (2x = 100% margin)
  const recommendedDeposit = minimumDeposit * safetyMultiplier;
  
  return {
    minimumDeposit: Math.ceil(minimumDeposit),
    recommendedDeposit: Math.ceil(recommendedDeposit),
    monthlyHostCost: monthlyHostCost,
    assumedYield: conservativeYieldAPY
  };
}

// Example: 5GB content, 5 hosts
const deposit = calculateMinimumDeposit(5, 5);
console.log(deposit);

/* Output:
{
  minimumDeposit: 300000,  // 300k sats minimum
  recommendedDeposit: 600000,  // 600k sats recommended (2x safety)
  monthlyHostCost: 2500,
  assumedYield: 0.10
}
*/
```

#### Deposit Size Guidelines by Content Type

*Assumptions: 10% APY conservative yield, 100 sats/GB/host/month, 2x safety margin.*

| Content Type | Size | Hosts | Min Deposit | Recommended | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Text Document** | 1 MB | 3 | 3,600 sats | 10,000 sats | Minimal hosting cost |
| **Image/Photo** | 5 MB | 3 | 18,000 sats | 50,000 sats | Standard redundancy |
| **Audio Track** | 10 MB | 5 | 60,000 sats | 150,000 sats | Higher availability |
| **Research Dataset** | 1 GB | 5 | 600,000 sats | 1,500,000 sats | Long-term archive |
| **Video (HD)** | 5 GB | 5 | 3,000,000 sats | 7,500,000 sats | High bandwidth needs |
| **Software Release** | 500 MB | 7 | 2,100,000 sats | 5,000,000 sats | Critical availability |

#### Deposit Process

The initialization process atomically links the content, the wallet, and the yield generation mechanism.

```javascript
async function initializeLYW(contentCID, depositAmount) {
  // 1. Create metadata structure
  const metadata = {
    content_cid: contentCID,
    // ... other metadata fields
  };
  
  // 2. Generate three-key multi-sig wallet
  const wallet = await createMultiSigWallet({
    key1: deriveFromCID(contentCID),
    key2: creator.publicKey,
    key3: await generateSmartContractKey()
  });
  
  // 3. Open Lightning channel with deposit
  // This transaction also anchors content hash via OP_RETURN
  const channelTx = await openLightningChannel({
    amount: depositAmount,
    op_return: hash(contentCID + JSON.stringify(metadata)),
    wallet: wallet.address
  });
  
  // 4. Wait for Bitcoin confirmation and extract timestamp
  await waitForConfirmation(channelTx.txid);
  const block = await getBlockForTx(channelTx.txid);
  
  metadata.bitcoin_anchor = {
    tx_id: channelTx.txid,
    block_height: block.height,
    block_hash: block.hash,
    block_timestamp: block.timestamp
  };
  
  // 5. Initialize LYW structure
  const lyw = {
    wallet_address: wallet.lightning_address,
    balance: depositAmount,
    compound_pool: 0,
    created_at: Date.now(),
    last_distribution: null,
    yield_sources: []
  };
  
  // 6. Set up liquidity lease (Yield Generation)
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
  
  // 7. Finalize metadata and upload to IPFS
  metadata.ipfs_sats_metadata.wallet_address = lyw.wallet_address;
  const metadataCID = await ipfs.dag.put(metadata);
  
  // 8. System is now live
  return {
    content_cid: contentCID,
    metadata_cid: metadataCID,
    lyw: lyw,
    status: "active",
    estimated_runway: calculateRunway(depositAmount, lyw)
  };
}
```

#### Initial State Example

Upon completion, the system state reflects the funded wallet and projected financials.

```json
{
  "lyw": {
    "wallet_address": "lnbc1...",
    "balance": 1000000,
    "compound_pool": 0,
    "yield_sources": [
      {
        "type": "liquidity_lease",
        "platform": "Lightning Pool",
        "amount": 1000000,
        "expected_apy": 0.12,
        "expected_monthly": 10000,
        "lease_started": 1735094400,
        "lease_expires": 1737686400
      }
    ]
  },
  "smart_contract": {
    "yield_split": {
      "creator": 50,
      "compound": 50
    },
    "host_payments": {
      "monthly_budget": 5000,
      "hosts_count": 5,
      "payment_per_host": 1000
    }
  },
  "financial_projection": {
    "monthly_yield": 10000,
    "monthly_costs": 5000,
    "net_monthly": 5000,
    "runway": "indefinite (yield > costs)"
  }
}
```
## Yield Distribution: Creator/Compound Split ⚖️

The **Yield Distribution** mechanism defines the core economic decision for the Lightning Yield Wallet ($\text{LYW}$). Every unit of yield earned must be strategically allocated between two competing priorities: **Creator compensation** (immediate reward for the artist) and **Compounding** (reinvestment to ensure perpetual availability).

The **split ratio** is encoded in the DAO's smart contract and is fully configurable via governance vote ($\text{Key 2}$ authority).

### Common Split Strategies

The split determines the content's financial trajectory, balancing short-term income with long-term persistence.

| Strategy | Split (Creator/Compound) | Use Case | Outcome & Goal |
| :--- | :--- | :--- | :--- |
| **Growth Priority** | **20 / 80** | Long-term archival, public goods, foundational research. | **Maximize persistence runway**; balance grows rapidly for multi-decade availability. |
| **Balanced** | **50 / 50** | Standard content, music, articles, commercial software. | **Balance income with sustainability**; healthy creator income and stable compounding. |
| **Income Priority** | **80 / 20** | Independent artists, freelancers needing immediate income. | **Maximize short-term returns**; high creator payout at the cost of slower balance growth. |
| **Full Compound** | **0 / 100** | Open-source codebases, community datasets. | **Maximize perpetual availability**; exponential growth with zero creator payout. |

The split configuration is represented in the metadata:

```json
"yield_split": {
  "creator": 50,
  "compound": 50
}
```

### Distribution Cycle and Logic

The automated distribution is executed by **$\text{Key 3}$ (Smart Contract)** periodically (e.g., monthly, quarterly) or immediately upon receiving a liquidity lease premium.

```javascript
async function executeYieldDistribution() {
  // 1. Calculate yield earned for the period
  const yieldEarned = await calculateYieldForPeriod(lyw, period);
  
  // 2. Calculate distributions based on DAO split
  const split = dao.smart_contract.yield_split;
  
  const creatorAmount = Math.floor((yieldEarned * split.creator) / 100);
  const compoundAmount = Math.floor((yieldEarned * split.compound) / 100);
  
  // All rounding remainder goes to the compound pool for stability
  const remainder = yieldEarned - (creatorAmount + compoundAmount);
  const finalCompound = compoundAmount + remainder;
  
  // 3. Distribute to creator(s) via Lightning Network
  if (creatorAmount > 0) {
    for (const member of dao.members) {
      const memberShare = Math.floor((creatorAmount * member.weight) / 100);
      
      if (memberShare > 0) {
        // Sends payment instantly using Key 3 signature
        await lightning.send({
          to: member.lightning_address,
          amount: memberShare,
        });
      }
    }
  }
  
  // 4. Add to compound pool
  lyw.compound_pool += finalCompound;
  lyw.balance += finalCompound; // Principal balance increases
  
  // 5. Record and publish report (for transparency/audit)
  const distributionRecord = { /* ... data ... */ };
  lyw.distribution_history.push(distributionRecord);
  await updateLYW(lyw);

  return distributionRecord;
}
```

### Compounding Effect Over Time

Compounding is the engine of persistence. By reinvesting the compound share, the principal balance grows, leading to higher future yield and greater financial security for the content.

| Period | Balance Start (50/50 Split) | Yield Earned (12% APY) | Creator Payout | Compounded |
| :--- | :--- | :--- | :--- | :--- |
| **Month 1** | $1,000,000 \text{ sats}$ | $10,000 \text{ sats}$ | $5,000 \text{ sats}$ | $5,000 \text{ sats}$ |
| **Year 1** | $1,000,000 \text{ sats}$ | $123,356 \text{ sats}$ | $61,678 \text{ sats}$ | $61,678 \text{ sats}$ |
| **Year 5** | $\sim 1,293,000 \text{ sats}$ | $\sim 157,000 \text{ sats}/\text{year}$ | $\sim 78,500 \text{ sats}/\text{year}$ | $\sim 78,500 \text{ sats}/\text{year}$ |

The annual yield earned in Year 5 is significantly greater than the Year 1 yield, demonstrating how compounding accelerates the content's financial viability.

### Dynamic Split Adjustment

The DAO can use its governance authority ($\text{Key 2}$ signature) to temporarily or permanently adjust the yield split based on real-world needs.

  * **Temporary Adjustments:** A DAO proposal can specify a new split that is only active for a set duration (e.g., 6 months), automatically reverting to the original split afterward. This handles situations like emergency funding or short-term incentive programs without permanently altering the long-term plan.
  * **Weighted Payouts:** If the creator is a $\text{DAO}$ with multiple members, the $\text{Creator Share}$ is further divided based on member weights defined in $\text{Key 2}$'s configuration, ensuring fair proportional compensation.
