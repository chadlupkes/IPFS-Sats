# 5.2 The Self-Sustaining Model ⚙️

The Lightning Yield Wallet creates a perpetual motion machine for content persistence — not in the thermodynamic sense, but in economic terms. Once set in motion with an initial deposit, the system generates enough yield to cover its own operating costs indefinitely, with surplus compounding back to increase future yield.

This section details the operational mechanics: how the system starts, how it runs, how it self-corrects, and what happens when conditions change.

---

## 5.2.1 Initial Deposit: Bootstrapping the Economic Engine

The initial deposit must be large enough to generate sufficient yield to cover hosting costs while building a compounding surplus. The minimum viable deposit depends on three factors:

1. **Content size** (storage requirements)
2. **Expected yield rate** (market conditions)
3. **Desired runway** (margin of safety)

### Calculation Formula

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
  minimumDeposit: 300000,     // 300k sats minimum
  recommendedDeposit: 600000, // 600k sats recommended (2x safety)
  monthlyHostCost: 2500,
  assumedYield: 0.10
}
*/
```

### Deposit Size Guidelines by Content Type

Assumptions: 10% APY conservative yield, 100 sats/GB/host/month, 2x safety margin.

| Content Type | Size | Hosts | Min Deposit | Recommended | Notes |
|---|---|---|---|---|---|
| **Text Document** | 1 MB | 3 | 3,600 sats | 10,000 sats | Minimal hosting cost |
| **Image/Photo** | 5 MB | 3 | 18,000 sats | 50,000 sats | Standard redundancy |
| **Audio Track** | 10 MB | 5 | 60,000 sats | 150,000 sats | Higher availability |
| **Research Dataset** | 1 GB | 5 | 600,000 sats | 1,500,000 sats | Long-term archive |
| **Video (HD)** | 5 GB | 5 | 3,000,000 sats | 7,500,000 sats | High bandwidth needs |
| **Software Release** | 500 MB | 7 | 2,100,000 sats | 5,000,000 sats | Critical availability |

### Deposit Process

The initialization process atomically links the content, the wallet, and the yield generation mechanism.

```javascript
async function initializeLYW(contentCID, depositAmount) {
  // 1. Create Metadata Wrapper structure
  const metadataWrapper = {
    content_cid: contentCID,
    // ... other metadata fields
  };

  // 2. Compute Bundle Hash from Content CID + Metadata Wrapper
  const bundleHash = hash(contentCID + JSON.stringify(metadataWrapper));

  // 3. Generate three-key multi-sig wallet
  const wallet = await createMultiSigWallet({
    key1: deriveFromCID(contentCID),
    key2: creator.publicKey,
    key3: await generateSmartContractKey()
  });

  // 4. Open Lightning channel with deposit
  // Bundle Hash embedded via OP_RETURN at near-zero marginal cost
  const channelTx = await openLightningChannel({
    amount: depositAmount,
    op_return: bundleHash,
    wallet: wallet.address
  });

  // 5. Wait for Bitcoin confirmation and extract timestamp
  await waitForConfirmation(channelTx.txid);
  const block = await getBlockForTx(channelTx.txid);

  // 6. Write Anchor Record to Records Database after confirmation
  const anchorRecord = {
    metadata_bundle_cid: null, // set after bundle is published
    bundle_hash: bundleHash,
    wallet_address: wallet.lightning_address,
    tx_id: channelTx.txid,
    block_height: block.height,
    published_by: creator.nodeId,
    signature: creator.sign(bundleHash)
  };

  // 7. Publish Metadata Bundle to the network
  const metadataBundleCID = await network.publish({
    content_cid: contentCID,
    metadata_wrapper: metadataWrapper
  });

  anchorRecord.metadata_bundle_cid = metadataBundleCID;
  await recordsDatabase.writeAnchor(anchorRecord);

  // 8. Initialize LYW structure
  const lyw = {
    wallet_address: wallet.lightning_address,
    balance: depositAmount,
    compound_pool: 0,
    created_at: Date.now(),
    last_distribution: null,
    yield_sources: []
  };

  // 9. Set up liquidity lease (yield generation)
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

  // 10. System is now live
  return {
    content_cid: contentCID,
    metadata_bundle_cid: metadataBundleCID,
    lyw: lyw,
    status: "active",
    estimated_runway: calculateRunway(depositAmount, lyw)
  };
}
```

### Initial State Example

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

---

## 5.2.2 Yield Distribution: Creator/Compound Split ⚖️

The **Yield Distribution** mechanism defines the core economic decision for the LYW. Every unit of yield earned must be strategically allocated between two competing priorities: **Creator compensation** (immediate reward for the creator) and **Compounding** (reinvestment to ensure perpetual availability).

The split ratio is encoded in the DAO's smart contract and is fully configurable via governance vote (Key 2 authority).

### Common Split Strategies

The split determines the content's financial trajectory, balancing short-term income with long-term persistence.

| Strategy | Split (Creator/Compound) | Use Case | Outcome |
|---|---|---|---|
| **Growth Priority** | 20 / 80 | Long-term archival, public goods, foundational research | Maximize persistence runway — balance grows rapidly for multi-decade availability |
| **Balanced** | 50 / 50 | Standard content, music, articles, commercial software | Balance income with sustainability — healthy creator income and stable compounding |
| **Income Priority** | 80 / 20 | Independent creators needing immediate income | Maximize short-term returns — high creator payout at the cost of slower balance growth |
| **Full Compound** | 0 / 100 | Open-source codebases, community datasets | Maximize perpetual availability — exponential growth with zero creator payout |

The split configuration is represented in the metadata:

```json
"yield_split": {
  "creator": 50,
  "compound": 50
}
```

### Distribution Cycle and Logic

The automated distribution is executed by Key 3 periodically (e.g., monthly, quarterly) or immediately upon receiving a liquidity lease premium.

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
      // Handles proportional payouts for multi-member DAOs
      const memberShare = Math.floor((creatorAmount * member.weight) / 100);

      if (memberShare > 0) {
        // Sends payment instantly using Key 3 signature
        await lightning.send({
          to: member.lightning_address,
          amount: memberShare
        });
      }
    }
  }

  // 4. Add to compound pool (increases the LYW principal)
  lyw.compound_pool += finalCompound;
  lyw.balance += finalCompound;

  // 5. Record and publish report for transparency and audit
  const distributionRecord = { /* ... data ... */ };
  lyw.distribution_history.push(distributionRecord);
  await updateLYW(lyw);

  return distributionRecord;
}
```

### Compounding Effect Over Time

Compounding is the engine of persistence. By reinvesting the compound share, the principal balance grows, leading to higher future yield and greater financial security for the content — the Snowball Effect in action.

| Period | Balance Start (50/50 Split) | Yield Earned (12% APY) | Creator Payout | Compounded |
|---|---|---|---|---|
| **Month 1** | 1,000,000 sats | 10,000 sats | 5,000 sats | 5,000 sats |
| **Year 1** | 1,000,000 sats | 123,356 sats | 61,678 sats | 61,678 sats |
| **Year 5** | ~1,293,000 sats | ~157,000 sats/year | ~78,500 sats/year | ~78,500 sats/year |

The annual yield earned in Year 5 is significantly greater than Year 1 yield, demonstrating how compounding accelerates financial viability and makes persistence increasingly robust over time.

### Dynamic Split Adjustment

The DAO can use its governance authority (Key 2 signature, co-executed by Key 3) to temporarily or permanently adjust the yield split based on real-world needs.

- **Temporary Adjustments:** A DAO proposal can specify a new split active only for a set duration (e.g., 6 months), automatically reverting to the original split afterward. This handles situations like emergency funding or short-term incentive programs without permanently altering the long-term plan.
- **Weighted Payouts:** If the creator is a DAO with multiple members, the Creator Share is further divided based on member weights defined in Key 2's configuration, ensuring fair proportional compensation.

---

## 5.2.3 The Atomic Persistence Loop: Host Compensation, Viability, and Failsafes ⚙️🛡️

The LYW creates the Atomic Persistence Loop by ensuring that yield generated translates into verifiable, instantaneous host compensation, while simultaneously calculating the content's long-term financial viability. This loop dictates the overall health and redundancy of the content.

### Automated Host Compensation

The **compound pool** funds ongoing payments to hosts who prove they are storing and serving the content. This is a market-driven system where hosts compete on reliability and performance. The payment process is executed periodically by Key 3.

**Proof-of-Storage Verification:**

Payment is strictly conditional on cryptographic proof of storage:

1. **Challenge and Proof:** The system sends a randomized challenge to all claiming hosts. Hosts must respond with a verifiable cryptographic Merkle proof, ensuring they possess the entire content at the time of the challenge.
2. **Performance Metrics:** The verification process measures response time and checks the host's historical uptime score. Hosts who fail verification are immediately removed from the DAO's active host registry.
3. **Insufficient Funds Check:** If the LYW's compound pool falls below the required `monthlyBudget`, a Low Balance Alert is triggered and payments are suspended until the fund is replenished.

**Payment Calculation and Distribution:**

Host payments can be distributed based on two governance-configurable strategies:

- **Equal Distribution:** The `monthlyBudget` is split evenly among all verified hosts. This promotes stable, foundational storage capacity.
  ```
  Payment Per Host = floor(Monthly Budget / Verified Host Count)
  ```
- **Performance-Weighted Distribution:** The `monthlyBudget` is weighted by a host's performance score (inverse response time × uptime score). This incentivizes faster retrieval and higher quality of service, increasing content redundancy at the edge.

After calculating amounts, Key 3 executes instant, atomic micropayments over the Lightning Network, deducting the total paid from the LYW compound pool.

```javascript
async function payHostsForStorage() {
  const dao = await getDAO();
  const lyw = await getLYW();
  const content_cid = dao.content_cid;

  // 1. Check funds against monthly budget
  const monthlyBudget = dao.smart_contract.host_payments.monthly_budget;
  if (lyw.compound_pool < monthlyBudget) {
    await triggerLowBalanceAlert(dao.cid, {
      pool_balance: lyw.compound_pool,
      required: monthlyBudget
    });
    return { status: "insufficient_funds" };
  }

  // 2. Verify all claiming hosts via proof-of-storage
  const hosts = await getHostsForContent(content_cid);
  const verifiedHosts = [];

  for (const host of hosts) {
    const challenge = {
      nonce: generateNonce(),
      timestamp: Date.now(),
      content_cid: content_cid
    };
    const proof = await requestStorageProof(host.did, challenge);

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

  // 3. Calculate and execute payments via Lightning
  let totalPaid = 0;
  for (const payment of calculatePaymentDistribution(verifiedHosts, monthlyBudget)) {
    try {
      await lightning.send({
        to: payment.host.lightning_address,
        amount: payment.amount,
        memo: `Host payment - ${content_cid.slice(0, 12)}...`
      });
      totalPaid += payment.amount;
    } catch (error) {
      // Handle payment failure, schedule retry
    }
  }

  // 4. Deduct from compound pool and record transaction
  lyw.compound_pool -= totalPaid;
  await updateLYW(lyw);

  return { status: "payments_executed", totalPaid: totalPaid };
}
```

**Host Incentive Summary:**

| Incentive | Mechanism | Benefit to Host |
|---|---|---|
| **Consistent Payments** | Proof-of-Storage verification | Reliable sats income stream |
| **Performance Bonuses** | Performance-weighted split | Financial reward for low latency and high uptime |
| **Stacked Revenue** | Hosting multiple CIDs | High potential for passive income from existing infrastructure |

### Perpetual Viability Model

The system's core function is to maintain **Perpetual Viability** by ensuring yield generated is greater than or equal to monthly costs:

```
Yield Generated >= Host Payments + Network Fees
```

If a monthly surplus remains, it compounds back into the LYW balance, increasing the principal and generating more future yield — a virtuous cycle.

```javascript
function calculatePerpetualViability(deposit, yieldAPY, monthlyCost) {
  const monthlyYield = (deposit * yieldAPY) / 12;
  const monthlySurplus = monthlyYield - monthlyCost;

  if (monthlySurplus > 0) {
    // System is sustainable: runway is indefinite
    const compoundingRate = monthlySurplus / deposit;
    const doublingTime = Math.log(2) / Math.log(1 + compoundingRate);

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

### Health Monitoring and Failsafe Mechanics

To prevent data loss when the system is depleting, the LYW implements a transparent, tiered **Health Monitoring** system based on the calculated persistence runway.

| State | Runway | Action Triggered by Key 3 | Creator Response |
|---|---|---|---|
| **Healthy** | >12 months | None | System is self-sustaining |
| **Warning** | 6–12 months | Periodic (30-day) alerts | Creator notified to consider a top-up or switch to Growth Priority split |
| **Critical** | 3–6 months | Urgent (7-day) alerts | Creator prompted with top-up or self-hosting options |
| **Emergency** | <3 months | Daily alerts | Automatic failsafe activation — system attempts to self-host content on creator's node as backup |
| **Depleted** | 0 sats | 30-day grace period initiated | Hosts informed of depletion but remain obligated to store for 30 days |

**Automatic Failsafe: Creator Node Self-Hosting**

In the Emergency state, the system automatically checks if the creator's node is online. If so, it uses the creator's identity and credentials to self-host the content, making the creator the **host of last resort**. This ensures content remains safe even if the LYW fails financially.

**Grace Period and Final Release:**

Upon reaching the Depleted state:

1. **30-Day Obligation:** Hosts are notified that the LYW is empty but are obligated to continue serving the content for a 30-day grace period. This provides a final window for the creator to replenish the wallet.
2. **Host Release:** If the LYW is not replenished within 30 days, all compensated hosts are released from their payment obligations and may remove the content to free up storage, completing the Economic Degradation Protocol (Section 5.1.5).

This entire mechanism ensures that content persistence is a function of verifiable economic viability, while providing layers of transparent risk mitigation to the creator.
