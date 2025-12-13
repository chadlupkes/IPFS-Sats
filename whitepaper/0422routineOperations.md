## 4.2.2 Routine Operations (Automated via Key 3)

**Principle:** Pre-approved, recurring operations execute automatically without human intervention, enabling the self-sustaining economic model of $\text{IPFS}$-$\text{Sats}$. The goal is to move the system from requiring constant human oversight to operating as a **digital perpetual machine**.

**Authorization:** **$\text{Key 3}$ only** (within pre-defined limits and DAO-approved rules).

#### Operations: Automated Financial and Governance Tasks

All these tasks are fully auditable and rely on $\text{Key 3}$'s pre-approved logic.

1.  **Yield Distribution**
    The core financial mechanism. $\text{Key 3}$ runs on a set schedule (e.g., daily or weekly) to automatically calculate and distribute funds earned by the $\text{Lightning Yield Wallet}$ ($\text{LYW}$).

      * **Mechanism:** $\text{Key 3}$ retrieves the $\text{DAO}$'s current yield_split percentages and applies them to the earned yield. Individual shares are sent instantly via $\text{Lightning}$ to member addresses; the **Compound Share** is reinvested into the $\text{LYW}$ pool for persistence.
      * **Authorization Check:** $\text{Key 3}$ verifies that the distribution percentages match the current $\text{DAO}$ rules and that the total amount is within its daily spending limits. If checks pass, $\text{Key 3}$ signs the multi-sig transaction automatically.

2.  **Host Payments (Proof-of-Storage)**
    This is the maintenance mechanism that financially secures data persistence.

      * **Mechanism:** $\text{Key 3}$ initiates a cryptographic challenge to hosts storing the content, requesting a **Proof-of-Storage** (e.g., a $\text{Merkle}$ proof). Only hosts that provide a valid proof within the response time limit are approved for payment. Payment is calculated from the Compound Pool and sent instantly via $\text{Lightning}$. Hosts who fail verification are flagged for replacement.
      * **Authorization Check:** $\text{Key 3}$ verifies that the storage proof is valid and that the payment is within the pre-defined host budget.

3.  **Content Retrieval Payments**
    When content is sold or leased on demand (retrieval-as-a-service), $\text{Key 3}$ ensures the host is compensated.

      * **Mechanism:** The content buyer pays the host for retrieval. $\text{Key 3}$ may be responsible for routing the payment, ensuring the transaction is atomic and fast.
      * **Authorization Check:** $\text{Key 3}$ verifies the proof of content delivery and that the payment amount is within the expected per-retrieval limits.

4.  **Report Generation**
    Ensuring transparency and auditability for all stakeholders.

      * **Mechanism:** $\text{Key 3}$ gathers all financial, governance, and host performance data over a set period, compiles the information into a comprehensive report, publishes the immutable report to $\text{IPFS}$, and signs a metadata update to link the new report's $\text{CID}$ to the $\text{DAO}$ record.
      * **Authorization Check:** This is a read-only data aggregation operation followed by a routine, pre-approved metadata update, which $\text{Key 3}$ executes automatically.

5.  **Liquidity Lease Renewals**
    Maintaining the functionality and profitability of the $\text{LYW}$.

      * **Mechanism:** $\text{Key 3}$ monitors the expiration of Lightning Network liquidity leases. If a lease is profitable and nearing expiration, $\text{Key 3}$ automatically calculates the optimal renewal terms and executes the renewal transaction using funds from the Compound Pool.
      * **Authorization Check:** $\text{Key 3}$ verifies that the lease renewal is profitable (net positive yield) and that the amount is within the designated liquidity management budget.

### Limits on Automated Operations

To prevent unauthorized or faulty automation, $\text{Key 3}$ operates within three tiers of authorization:

| Category | Authority | Required Key Combination |
| :--- | :--- | :--- |
| **Tier 1: Routine Automation** | Execute automatically within budget. | **$\text{Key 3}$ Alone** |
| **Tier 2: Policy/Major Finance** | Requires $\text{DAO}$ vote and $\text{Key 2}$ approval. | **$\text{Key 2}$ + $\text{Key 3}$** |
| **Tier 3: Forbidden Actions** | Cannot be executed by $\text{Key 3}$ under any circumstance. | $\text{N/A}$ |

```json
"key3_automation_limits": {
  "max_payment_per_transaction": 10000,  // sats
  "max_daily_total": 100000,  // sats
  
  "allowed_without_approval": [ // Tier 1
    "yield_distribution",
    "host_payment",
    "content_retrieval",
    "report_generation",
    "lease_renewal"
  ],
  
  "absolutely_forbidden": [ // Tier 3
    "ownership_transfer",
    "key_replacement",
    "dao_dissolution"
  ]
}
```

#### Exceeding Limits: Escalation to Governance

If $\text{Key 3}$ attempts an operation that exceeds its pre-approved limits, the transaction is rejected, and the action is automatically escalated into a formal $\text{DAO}$ proposal requiring human review and $\text{Key 2}$ authorization.

> *Example:* An exceptional host payment is needed that exceeds the $10,000$ sats limit. $\text{Key 3}$ rejects the automatic payment and creates a **DAO Proposal** for a **Large Payment**, requiring member vote and $\text{Key 2}$'s signature for final execution.

-----
