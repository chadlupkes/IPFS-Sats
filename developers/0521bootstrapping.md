## 5.2 The Self-Sustaining Model: Bootstrapping and Persistence ⚙️

The $\text{IPFS}$-$\text{Sats}$ protocol is designed for two modes of launch: **Zero-Cost Bootstrapping** (leveraging social value and the Creator Node) and **Economically Self-Sustaining** (using a sufficient deposit to attract market-compensated hosts).

### 5.2.1 Initial Deposit: Bootstrapping the Economic Engine

The initial deposit is the capital required to transition a piece of content from a **Creator-Pinned state** to a **Compensated-Redundancy state**, where the content can afford third-party hosts and achieve perpetual availability.

#### **A. The Zero-Cost Launch (Community Bootstrapping)**

Content can be made persistent with a **zero $\text{sats}$ initial deposit** if the creator pins it on their own device ($\text{Creator Node}$).

  * **Viral Feedback Loop:** If the content gains popularity, incoming user payments (Zaps) and community deposits directly fund the $\text{LYW}$ balance. Once the $\text{LYW}$ balance crosses the **Minimum Sustainable Deposit** threshold, $\text{Key 3}$ automatically activates the yield engine and begins paying third-party hosts.
  * **Principle:** The system prioritizes **permissionless access** over initial financial requirements.

#### **B. Determining the Self-Sustaining Deposit Amount**

This calculation determines the capital needed for the content to generate enough yield to cover market-rate hosting costs indefinitely. The minimum viable deposit depends on: **Content Size**, **Expected Yield Rate**, and **Desired Runway**.

-----

#### Calculation Formula (JavaScript Example)

This function models the required principal deposit based on conservative financial and storage cost assumptions.

```javascript
/**
 * Calculates the minimum and recommended deposit needed for perpetual persistence.
 * @param {number} contentSizeGB - Size of content in Gigabytes.
 * @param {number} hostCount - Desired number of redundant hosts.
 * @param {number} safetyMultiplier - Factor to hedge against market risk (e.g., 2x).
 * @returns {object} Financial projections for minimum deposit.
 */
function calculateMinimumDeposit(contentSizeGB, hostCount, safetyMultiplier = 2) {
  // Monthly hosting cost per GB per host (market rate estimate in sats)
  const costPerGBPerHost = 100; // sats
  
  // Total monthly hosting cost
  const monthlyHostCost = contentSizeGB * hostCount * costPerGBPerHost;
  
  // Conservative yield rate (low estimate for safety)
  const conservativeYieldAPY = 0.10; // 10% annual
  const monthlyYieldRate = conservativeYieldAPY / 12;
  
  // Minimum deposit to cover costs: Principal = Costs / Rate
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

*Assumptions: $10\% \text{ APY}$ conservative yield, $100 \text{ sats}$/$\text{GB}$/host/month, $2\times$ safety margin.*

| Content Type | Size | Hosts | Min Deposit | Recommended | Notes |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Text Document** | $1 \text{ MB}$ | 3 | $3,600 \text{ sats}$ | $10,000 \text{ sats}$ | Minimal hosting cost |
| **Image/Photo** | $5 \text{ MB}$ | 3 | $18,000 \text{ sats}$ | $50,000 \text{ sats}$ | Standard redundancy |
| **Audio Track** | $10 \text{ MB}$ | 5 | $60,000 \text{ sats}$ | $150,000 \text{ sats}$ | Higher availability |
| **Research Dataset** | $1 \text{ GB}$ | 5 | $600,000 \text{ sats}$ | $1,500,000 \text{ sats}$ | Long-term archive |
| **Video (HD)** | $5 \text{ GB}$ | 5 | $3,000,000 \text{ sats}$ | $7,500,000 \text{ sats}$ | High bandwidth needs |
| **Software Release** | $500 \text{ MB}$ | 7 | $2,100,000 \text{ sats}$ | $5,000,000 \text{ sats}$ | Critical availability |

