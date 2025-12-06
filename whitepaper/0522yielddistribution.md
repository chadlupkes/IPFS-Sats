## 5.2.2 Yield Distribution: Creator/Compound Split ⚖️

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
