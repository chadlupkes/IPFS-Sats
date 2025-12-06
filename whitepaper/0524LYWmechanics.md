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
