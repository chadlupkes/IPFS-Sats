## 4.2.3 Major Operations (Require DAO Approval via Key 2 + Key 3) 🤝🤖

This section details significant state-changing operations that require collective human authorization (via $\text{Key 2}$ signatures) combined with the automated execution mechanism (via $\text{Key 3}$). These are the core governance functions of the $\text{IPFS}$-$\text{Sats}$ $\text{DAO}$.

### Principle and Authorization

* **Principle:** Significant changes affecting governance, economics, or membership require human authorization through a formal consensus process.
* **Authorization:** $\text{Key 2}$ + $\text{Key 3}$ (Human decision-making combined with automated execution).

### Governance Process Flow: Proposal to Execution

All major operations follow a strict, multi-stage process to ensure deliberate and auditable decisions:

1.  **Proposal Created:** A member submits a formal request to change the $\text{DAO}$'s state.
2.  **DAO Members Vote ($\text{Key 2}$ Signatures):** Members secure their vote using their individual $\text{Key 2}$ authority.
3.  **Consensus Check:** The system verifies that the required **Quorum** and **Threshold** (e.g., a $66\%$ majority) are met.
4.  **Timelock Period:** A mandatory delay (e.g., 24–72 hours) begins, allowing for final review or veto before funds/rules are altered.
5.  **$\text{Key 3}$ Executes:** Upon successful consensus and expiration of the timelock, $\text{Key 3}$ automatically enacts the change in the smart contract's state.



### Operations Requiring Consensus

#### 1. Yield Distribution Changes

Modifying how revenue is split among members and the compounding pool.

* **Mechanism:** A proposal defines the new $\text{yield\_split}$ percentages. Members vote using $\text{Key 2}$. If passed, $\text{Key 3}$ updates the contract variable.
* **Authorization:** $\text{DAO}$ majority via $\text{Key 2}$ signatures, finalized by $\text{Key 3}$'s state-change signature.

#### 2. Membership Changes

Adding new collaborators or removing existing members.

* **Mechanism:** The proposal outlines the new member list and the rebalancing of voting weights. If approved, $\text{Key 3}$ updates the official $\text{Key 2}$ multi-sig structure and the membership record.
* **Authorization:** $\text{DAO}$ consensus via $\text{Key 2}$ signatures.

#### 3. Smart Contract Updates

Modifying the core operational logic or parameters of the automation system.

* **Mechanism:** $\text{DAO}$ approval is needed to prevent unilateral rule changes. If approved, $\text{Key 3}$ implements the new parameters. For major upgrades, $\text{Key 2}$'s signature is required alongside $\text{Key 3}$ to authorize the deployment of a new contract version.
* **Authorization:** $\text{Key 2}$ consensus is mandatory for all policy-altering actions.

#### 4. License Grants

Formal authorization for granting exclusive rights, derivative work approvals, or commercial licensing terms.

* **Mechanism:** Upon approval, $\text{Key 3}$ generates a verifiable **License Certificate CID** and records the terms into the $\text{DAO}$'s immutable metadata. If payment is involved, $\text{Key 3}$ may generate a time-sensitive $\text{Lightning}$ invoice for atomic execution.

#### 5. Large Withdrawals

Any withdrawal exceeding $\text{Key 3}$'s pre-approved automated daily limit (Tier 1) must be escalated.

* **Mechanism:** Members vote on the amount, recipient, and reason. If approved by $\text{Key 2}$ consensus, $\text{Key 3}$ is authorized to bypass its normal spending limit and process the transaction.

#### 6. Emergency Actions

Time-sensitive operations to protect the $\text{DAO}$'s assets or function.

* **Emergency Pause:** A proposal to temporarily freeze all automated $\text{Key 3}$ operations. Voting periods are expedited, and thresholds are typically increased (e.g., $80\%$). Execution is handled by $\text{Key 3}$ after the expedited timelock.
* **Key Replacement:** If $\text{Key 3}$ is compromised, the replacement bypasses the compromised key and requires the cooperation of **$\text{Key 2}$ (human authority) and $\text{Key 1}$ (content binding)**.

#### 7. Ownership Transfer

Transferring complete control of the content $\text{DAO}$ (e.g., selling the content asset to a new entity).

* **Mechanism:** Requires the highest level of consensus (often $100\%$ of $\text{Key 2}$ weight). If approved, $\text{Key 3}$ executes the transfer of the $\text{Key 2}$ control key to the new owner(s) and records the final sale terms (including any retained perpetual royalties) in the immutable $\text{DAO}$ history.
* **Key Status:** $\text{Key 1}$ and $\text{Key 3}$ remain unchanged (preserving identity and automation), but are now under the control of the new $\text{Key 2}$ holders.
