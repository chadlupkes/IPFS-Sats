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

## 5.2.2 Yield Distribution: Creator/Compound Split ⚖️

The **Yield Distribution** mechanism defines the core economic decision for the Lightning Yield Wallet ($\text{LYW}$). Every unit of yield earned must be strategically allocated between two competing priorities: **Creator compensation** (immediate reward for the artist) and **Compounding** (reinvestment to ensure perpetual availability).

The **split ratio** is encoded in the $\text{DAO}$'s smart contract and is fully configurable via governance vote ($\text{Key 2}$ authority).

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
/**
 * Executes the yield distribution based on the DAO's defined split ratio.
 * This function is executed by Key 3 (Automation).
 */
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
      // Handles proportional payouts for multi-member DAOs
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
  
  // 4. Add to compound pool (Increases the LYW principal)
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

Compounding is the engine of persistence. By reinvesting the compound share, the principal balance grows, leading to higher future yield and greater financial security for the content—the **Snowball Effect** in action.

| Period | Balance Start (50/50 Split) | Yield Earned (12% APY) | Creator Payout | Compounded |
| :--- | :--- | :--- | :--- | :--- |
| **Month 1** | $1,000,000 \text{ sats}$ | $10,000 \text{ sats}$ | $5,000 \text{ sats}$ | $5,000 \text{ sats}$ |
| **Year 1** | $1,000,000 \text{ sats}$ | $123,356 \text{ sats}$ | $61,678 \text{ sats}$ | $61,678 \text{ sats}$ |
| **Year 5** | $\sim 1,293,000 \text{ sats}$ | $\sim 157,000 \text{ sats}/\text{year}$ | $\sim 78,500 \text{ sats}/\text{year}$ | $\sim 78,500 \text{ sats}/\text{year}$ |

The annual yield earned in Year 5 is significantly greater than the Year 1 yield, demonstrating how compounding accelerates the content's financial viability and ensures the content's persistence becomes increasingly robust.

### Dynamic Split Adjustment

The $\text{DAO}$ can use its governance authority ($\text{Key 2}$ signature) to temporarily or permanently adjust the yield split based on real-world needs, requiring a co-signature from $\text{Key 3}$ for execution (see Authorization Matrix).

  * **Temporary Adjustments:** A $\text{DAO}$ proposal can specify a new split that is only active for a set duration (e.g., 6 months), automatically reverting to the original split afterward. This handles situations like emergency funding or short-term incentive programs without permanently altering the long-term plan.
  * **Weighted Payouts:** If the creator is a $\text{DAO}$ with multiple members, the $\text{Creator Share}$ is further divided based on member weights defined in $\text{Key 2}$'s configuration, ensuring fair proportional compensation.

-----

## 5.2.3 The Atomic Persistence Loop: Compensation and Viability ⚙️

The $\text{Lightning Yield Wallet}$ ($\text{LYW}$) creates the Atomic Persistence Loop by ensuring that yield generated translates into verifiable, instantaneous host compensation, while simultaneously calculating the content's long-term financial viability. This loop dictates the overall health and redundancy of the content.

### Automated Host Compensation (Expenditure)

The **compound pool** funds the ongoing payments to hosts who prove they are storing and serving the content. This is a market-driven system where hosts compete on reliability and performance. The payment process is executed periodically by $\text{Key 3}$ (Smart Contract).

#### Proof-of-Storage Verification

Payment is strictly conditional on cryptographic proof of storage ($\text{PoS}$), ensuring compensation is only for active service (referencing $\text{5.1.4}$ details).

1.  **Challenge & Proof:** The system sends a randomized challenge to all claiming hosts. Hosts must respond with a verifiable cryptographic $\text{Merkle proof}$ or equivalent proof-of-retrievability, ensuring they possess the entire content file at the time of the challenge.
2.  **Performance Metrics:** The verification process measures **Response Time** and checks the host's historical **Uptime Score**. Hosts who fail verification are immediately removed from the $\text{DAO}$'s active host registry.
3.  **Insufficent Funds Check:** If the $\text{LYW}$'s compound pool falls below the required `monthlyBudget`, a **Low Balance Alert** is triggered, and payments are suspended until the fund is replenished.

#### Payment Calculation and Distribution Logic

The host compensation process is fully automated by $\text{Key 3}$ via the `payHostsForStorage` function:

```javascript
async function payHostsForStorage() {
  const dao = await getDAO();
  const lyw = await getLYW();
  const content_cid = dao.content_cid;
  
  // 1. Get configured monthly budget and check funds
  const monthlyBudget = dao.smart_contract.host_payments.monthly_budget;
  if (lyw.compound_pool < monthlyBudget) {
    await triggerLowBalanceAlert(dao.cid, { pool_balance: lyw.compound_pool, required: monthlyBudget });
    return { status: "insufficient_funds" };
  }
  
  // 2. Verify all claiming hosts via proof-of-storage
  const hosts = await getHostsForContent(content_cid);
  const verifiedHosts = [];
  
  for (const host of hosts) {
    const challenge = { nonce: generateNonce(), timestamp: Date.now(), content_cid: content_cid };
    const proof = await requestStorageProof(host.did, challenge);
    
    // Key 3 verifies the proof and calculates performance metrics
    if (await verifyMerkleProof(proof, content_cid, challenge)) {
      verifiedHosts.push({
        did: host.did,
        lightning_address: host.lightning_address,
        response_time: proof.timestamp - challenge.timestamp,
        uptime_score: await calculateUptimeScore(host.did, content_cid)
      });
    } else {
      await removeHostFromRegistry(host.did, content_cid);
    }
  }
  
  // 3. Calculate payment per host (Equal or Performance-Weighted)
  let paymentDistribution = [];
  // (Logic for Performance-Weighted and Equal Distribution as previously defined)
  
  // 4. Execute payments via Lightning
  let totalPaid = 0;
  for (const payment of paymentDistribution) {
    try {
      // Instant, atomic micropayment executed by Key 3
      const tx = await lightning.send({
        to: payment.host.lightning_address,
        amount: payment.amount,
        memo: `Host payment - ${content_cid.slice(0, 12)}...`,
        metadata: { proof_cid: payment.host.proof_cid }
      });
      totalPaid += payment.amount;
    } catch (error) {
      // Handle payment failure, schedule retry
    }
  }
  
  // 5. Deduct from compound pool and record transaction
  lyw.compound_pool -= totalPaid;
  await updateLYW(lyw);
  // (Recording payment batch to DAO history)
  
  return { status: "payments_executed", totalPaid: totalPaid };
}
```

#### Host Economics and Incentives

The compensation model ensures host participation is driven by transparent economic signals:

| Host Incentives | Mechanism | Benefit to Host |
| :--- | :--- | :--- |
| **Consistent Payments** | Proof-of-Storage verification | Reliability of $\text{sats}$ income stream. |
| **Performance Bonuses** | Performance-Weighted split | Financial reward for low latency and high uptime. |
| **Stacked Revenue** | Hosting multiple $\text{CIDs}$ | High potential for passive income from existing hardware/infrastructure. |

### Perpetual Storage Funding (Viability Model)

The system's core function is to maintain a state of **Perpetual Viability** by mathematically ensuring that the yield generated is greater than the monthly costs.

#### The Self-Sustaining Equation

Perpetual persistence occurs when:

$$\text{Yield Generated} \geq \text{Host Payments} + \text{Network Fees}$$

If a surplus remains, the surplus compounds back into the $\text{LYW}$ balance, increasing the principal and generating more future yield.

#### Mathematical Model for Persistence Runway

The `calculatePerpetualViability` function determines whether the system is self-sustaining or depleting and provides the creator with a clear persistence timeline.

```javascript
/**
 * Calculates the content's financial viability (indefinite vs. depleting).
 * @param {number} deposit - Current LYW balance (sats).
 * @param {number} yieldAPY - Annual percentage yield.
 * @param {number} monthlyCost - Total monthly host payments + fees (sats).
 */
function calculatePerpetualViability(deposit, yieldAPY, monthlyCost) {
  const monthlyYield = (deposit * yieldAPY) / 12;
  const monthlySurplus = monthlyYield - monthlyCost;
  
  if (monthlySurplus > 0) {
    // System is sustainable: runway is indefinite
    const compoundingRate = monthlySurplus / deposit;
    const doublingTime = Math.log(2) / Math.log(1 + compoundingRate); // Rule of 72 applied
    
    return {
      viable: true,
      monthly_surplus: monthlySurplus,
      annual_growth_rate: compoundingRate * 12,
      balance_doubles_in_months: doublingTime,
      runway: "indefinite"
    };
  } else {
    // System is depleting: calculate months until zero
    const monthlyDeficit = Math.abs(monthlySurplus);
    const monthsUntilDepleted = deposit / monthlyDeficit;
    
    return {
      viable: false,
      monthly_deficit: monthlyDeficit,
      months_until_depleted: monthsUntilDepleted,
      runway: `${monthsUntilDepleted.toFixed(1)} months`
    };
  }
}
```

-----

## 5.2.4 Operational Mechanics: Compensation, Viability, and Failsafes ⚙️🛡️

The operational phase of the Lightning Yield Wallet ($\text{LYW}$) is governed by a series of automated, on-chain functions that ensure continuous, verifiable compensation for hosts while protecting the long-term viability of the content.

### Automated Host Compensation (Expenditure)

The **compound pool** funds the ongoing payments to hosts who prove they are storing and serving the content. This is a market-driven system where hosts compete on reliability and performance. The payment process is executed periodically by $\text{Key 3}$ (Smart Contract).

#### Proof-of-Storage Verification

Payment is strictly conditional on cryptographic proof of storage ($\text{PoS}$).

1.  **Challenge & Proof:** The system sends a randomized challenge to all claiming hosts. Hosts must respond with a verifiable cryptographic Merkle proof, ensuring they possess the entire content file at the time of the challenge.
2.  **Performance Metrics:** The verification process measures **Response Time** and checks the host's historical **Uptime Score**. Hosts who fail verification are immediately removed from the DAO's active host registry.
3.  **Insufficent Funds:** If the $\text{LYW}$'s compound pool falls below the required `monthlyBudget`, a **Low Balance Alert** is triggered, and payments are suspended until the fund is replenished.

#### Payment Calculation and Distribution

Host payments can be distributed based on two governance-configurable strategies:

  * **Equal Distribution:** The `monthlyBudget` is split evenly among all verified hosts. This promotes stable, foundational storage capacity.
    $$\text{Payment Per Host} = \lfloor \frac{\text{Monthly Budget}}{\text{Verified Hosts Count}} \rfloor$$
  * **Performance-Weighted Distribution:** The `monthlyBudget` is weighted by a host's performance score (inverse response time $\times$ uptime score). This incentivizes faster retrieval and higher quality of service, increasing content redundancy at the edge.

After calculating the amounts, $\text{Key 3}$ executes **instant, atomic micropayments** over the Lightning Network, deducting the total paid from the $\text{LYW}$ compound pool.

### Perpetual Storage Funding (Viability Model)

The system's core function is to maintain a state of **Perpetual Viability** by ensuring that the yield generated is greater than the monthly costs.

#### The Self-Sustaining Equation

Perpetual persistence occurs when:

$$\text{Yield Generated} \geq \text{Host Payments} + \text{Network Fees}$$

If a monthly surplus ($\text{Yield} - \text{Costs}$) remains, that surplus compounds back into the $\text{LYW}$ balance. This increases the principal, which in turn generates more yield, making the system more resilient over time (a virtuous cycle).

#### Mathematical Model for Runway

The system calculates its long-term viability based on the net monthly flow:

  * **Viable System:** If $\text{Monthly Surplus} > 0$, the runway is **indefinite**. The system calculates the projected compounding rate and the time it would take for the balance to double.
  * **Depleting System:** If $\text{Monthly Deficit} < 0$, the system calculates the exact **Months Until Depleted** ($\text{Deposit} / \text{Monthly Deficit}$), providing a clear, measurable **Persistence Runway**.

<!-- end list -->

```javascript
/* Calculation for Depleting System */
const monthlyDeficit = Math.abs(monthlySurplus);
const monthsUntilDepleted = deposit / monthlyDeficit;
```

### Health Monitoring and Failsafe Mechanics (Risk Management)

To prevent data loss when the system is depleting, the $\text{LYW}$ implements a transparent, tiered **Health Monitoring** system based on the calculated **Persistence Runway**.

| State | Runway | Action Triggered by Key 3 | Creator Action/System Response |
| :--- | :--- | :--- | :--- |
| **Healthy** | $\text{>12 months}$ | None | System is self-sustaining. |
| **Warning** | $\text{6-12 months}$ | Periodic (30-day) email alerts. | Creator notified to consider a **top-up** or switch to **Growth Priority Split**. |
| **Critical** | $\text{3-6 months}$ | Urgent (7-day) alerts. | Creator prompted with **Top Up** or **Pin to Own Node** options. |
| **Emergency** | $\text{<3 months}$ | Daily alerts. | **Automatic Failsafe Activation:** System attempts to **self-pin** content to the creator's IPFS node as backup. |
| **Depleted** | $\text{0 sats}$ | **30-day Grace Period** initiated. | Hosts are informed of depletion but remain obligated to store for 30 days. |

#### Automatic Failsafe: Creator Node Self-Pinning

In the **Emergency** state, the system automatically checks if the creator's IPFS node is online. If so, it uses the creator's identity/credentials to remotely execute a pin command, making the creator the **host of last resort**. This ensures that the content remains safe, even if the $\text{LYW}$ fails financially.

#### Grace Period and Final Release

Upon reaching the **Depleted** state:

1.  **30-Day Obligation:** Hosts are notified that the $\text{LYW}$ is empty but are obligated to continue serving the content for a **30-day grace period**. This provides a final window for the creator to replenish the wallet.
2.  **Host Release:** If the $\text{LYW}$ is not replenished within the 30 days, the grace period expires. All compensated hosts are **released from their payment obligations** and may unpin the content to free up disk space, completing the **Economic Degradation Protocol (5.1.5)**.

This entire mechanism ensures that content persistence is a function of verifiable economic viability, while providing layers of transparent risk mitigation to the creator.
