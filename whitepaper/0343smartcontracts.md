## 3.4.3 Smart Contract Execution 🤖

The per-content DAO structure relies on **smart contracts** to transform governance rules into cryptographically-guaranteed execution. These contracts automate every operational detail—from proposal creation and voting to yield distribution and host payments—all without requiring trust in any central authority or platform.

The goal is to provide governance that is powerful enough for complex, multi-stakeholder scenarios, yet simple enough for solo creators to use without coding knowledge.

---

### 1. Proposal Creation

Any aspect of content management affecting multiple stakeholders can be proposed for a DAO vote.

#### Common Proposal Types

* **Yield Distribution Changes:** Modify revenue split percentages, add/remove recipients, or change compound vs. payout ratios.
* **Membership Changes:** Add a new collaborator, remove a member (e.g., due to departure or dispute), or adjust voting weights.
* **Licensing Decisions:** Grant exclusive licenses, approve derivative works (fork approval), or change license terms.
* **Smart Contract Updates:** Modify auto-approval thresholds, update host payment rates, or change voting parameters (quorum, threshold).
* **Emergency Actions:** Pause the smart contract (in case of a security issue) or replace a compromised member key.

#### Proposal Structure (Example)

A proposal is structured as a clear request to change the smart contract's state:

| Parameter | Example Value | Description |
| :--- | :--- | :--- |
| `proposal_id` | `prop_20251126_001` | Unique identifier. |
| `type` | `YIELD_SPLIT_UPDATE` | Defines the area of change. |
| `expires_at` | [Timestamp] | Defines the end of the voting period. |
| `current_state` | Alice: 40, Bob: 40, Compound: 20 | The current rule set. |
| `proposed_state` | Alice: 40, Bob: 40, Compound: 10, Marketing Fund: 10 | The desired new rule set. |
| `execution` | `timelock`: 24 hours | A delay between approval and execution for final audit. |

#### Proposal Permissions
The content owner configures who can create proposals:
* **Open:** Any member can propose (the default).
* **Weighted Threshold:** Only members with a collective weight greater than X%.
* **Role-Based:** Only specific roles (e.g., "core\_team").

---

### 2. Voting Mechanics

All votes are cryptographically signed using the member's Decentralized Identifier (**DID**), ensuring non-repudiation and auditable proof of participation.

#### Vote Counting Methods
The smart contract can implement several mechanisms to ensure fair and contextualized governance:

1.  **Simple Weighted Voting (Default):**
    * Each member's vote is multiplied by their assigned weight (e.g., Alice's 40% weight counts for 40 vote units).
2.  **Quadratic Voting (Anti-Plutocracy):**
    * Vote power is the square root of the member's weight, preventing large stakeholders from dominating small ones.
3.  **Conviction Voting (Time-Weighted):**
    * The vote's strength increases the longer a member holds their vote, rewarding long-term commitment over impulsive decisions.
4.  **Delegated Voting (Proxy):**
    * Members can delegate their voting power to another trusted member for a set period or scope.

#### Quorum and Threshold

* **Quorum:** Ensures that decisions are not made by an inactive minority. The proposal only proceeds if a minimum number of members or minimum collective weight participates.
* **Threshold:** The percentage of *supporting* weight required for a proposal to pass (e.g., a $66\%$ threshold requires a supermajority).

---

### 3. Automated Execution

Approved proposals are automatically executed by the smart contract after a configurable **timelock** period (e.g., 24 hours). This process eliminates the need for a trusted party to enact the changes.

#### Execution by Type

| Action | Execution Logic |
| :--- | :--- |
| **Yield Split Update** | The smart contract updates its internal state with the new distribution percentages. If the change is temporary, it automatically schedules a **revert job** for the future. |
| **Membership Change** | The contract updates the DAO's official member list and rebalances voting weights. If a member is removed, it can trigger an automatic **buyout** from the content's funds. |
| **License Grant** | Upon approval, the contract generates a verifiable **License Certificate CID** and records the terms. If payment is required, it generates a **Lightning invoice** and activates the license only after payment is received via an atomic transaction. |
| **Emergency Pause** | If triggered by a member with emergency authority, the contract immediately halts all automated operations (e.g., yield distributions) and automatically generates a new proposal to **Unpause**, requiring a high threshold vote to resume. |

---

### 4. Yield Distribution and Host Payments

The smart contract coordinates the flow of funds from the **Lightning Yield Wallet (LYW)**.

#### Automated Distribution Cycle

1.  **Calculate Yield:** The system calculates the yield earned by the $\text{LYW}$ over the specified period (e.g., daily or weekly).
2.  **Calculate Splits:** The contract applies the current `yield_split` percentages to the earned yield.
3.  **Execute Payments:** Individual Lightning payments are sent instantly to the corresponding member's Lightning Address (DID) for their share.
4.  **Compound:** The remainder (**compound amount**) is reinvested or kept in the $\text{LYW}$ to fund persistence.
5.  **Record:** A full, auditable distribution report is generated and published to $\text{IPFS}$.

#### Host Payments (Proof-of-Storage)

Host payment is conditional on cryptographic proof that the data is still stored.

1.  **Verification:** The system generates a random $\text{Merkle}$ **challenge** and requests the host provide a $\text{Proof-of-Storage}$ signature/path in response.
2.  **Validation:** If the proof is valid and within the response deadline, the host is verified. Hosts that fail verification are removed from the payment list.
3.  **Payment Calculation:** The total available budget (from the compound pool) is divided among verified hosts, potentially **weighted by performance** (e.g., faster response time = higher payment).
4.  **Execution:** Payments are sent to the hosts via $\text{Lightning}$.

---

### 5. Reporting & Transparency

Every action of the smart contract is permanently recorded, providing an unchangeable audit trail.

* **Automated Reporting:** Comprehensive weekly reports detailing financial summaries, governance activity, and content metrics (retrievals, Zaps, host performance) are automatically generated and published to IPFS.
* **Dashboard Visualization:** Members can view a real-time DAO dashboard summarizing wallet balance, runway, active proposals, and their individual earnings.
* **Public Transparency:** DAOs can configure the level of public transparency, choosing what information (e.g., financial reports, member identities, host performance) is made public or restricted to members only.

### Summary: Trustless Automation

Smart contract execution in IPFS-Sats achieves three critical goals:

1.  **Automation:** Yield distribution, host payments, and financial reporting happen without manual intervention.
2.  **Transparency:** Every decision and payment is recorded permanently on $\text{IPFS}$ and auditable by all members.
3.  **Trustlessness:** Cryptographic proofs and atomic $\text{Lightning}$ transactions eliminate the need for trusted intermediaries.

The result is governance that scales from solo creators (where automation is merely convenient) to complex multi-stakeholder productions (where automation is absolutely essential).
