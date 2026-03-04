# 4 The Multi-Sig Wallet Structure: Trustless Foundation 🔑

The **multi-signature wallet** is the cryptographic foundation that enables IPFS-Sats to achieve **trustless governance**, **automated execution**, and **verifiable ownership** without central authorities. This architecture binds together the content (via its **Content ID** or CID), the creators (via their **identity keys**), and the automated systems (via **smart contract keys**) into a single, coherent economic and governance unit.

Traditional multi-sig wallets require $M$-of-$N$ signatures (e.g., 2-of-3 keys) to authorize transactions. IPFS-Sats extends this by assigning each key a **specific role and purpose**, creating a three-dimensional security model where content identity, human control, and automated execution each contribute distinct authorization capabilities.

This section details the technical architecture of the three-key system, explaining how each key functions, what it authorizes, and how they interact to create a governance structure that is simultaneously secure, flexible, and autonomous.

-----

## 4.1 Three-Key Architecture

Every piece of content uploaded to IPFS-Sats generates a **3-of-3 multi-signature wallet** with three distinct keys. The wallet is technically a 3-of-3 structure, meaning all three keys must cooperate for specific, high-security actions (like ownership transfer or total withdrawal), but the *internal smart contract logic* grants distinct operational permissions to $\text{Key 2}$ and $\text{Key 3}$ for routine tasks.

| Key | Role | Function | Authority |
| :--- | :--- | :--- | :--- |
| **Key 1** | **CID-Derived Identifier** | Links the wallet to specific content; proves authenticity. | **Verification Only**. Cannot spend alone. |
| **Key 2** | **Creator/DAO Control Key** | Represents human authority (creator or DAO member group). | **Governance and Emergency** control. |
| **Key 3** | **Smart Contract Execution Key** | Performs routine, automated operations as dictated by DAO rules. | **Automated Payments** and rule enforcement. |

### Core Principle: Role-Based Key Separation

IPFS-Sats uses role-based key separation where:

  * $\text{Key 1}$ proves **what** (the content).
  * $\text{Key 2}$ proves **who** (the creator/DAO).
  * $\text{Key 3}$ proves **how** (the automation rules).

This separation is crucial; it allows automated payments ($\text{Key 3}$ action) without requiring human consent, while simultaneously preventing $\text{Key 3}$ from unilaterally changing the governance rules (which require $\text{Key 2}$ and possibly $\text{Key 1}$).

-----

### 4.1.1 Key 1: CID-Derived Identifier (Content Link)

$\text{Key 1}$ is the content's cryptographic fingerprint. It serves to **cryptographically bind the wallet to specific content**, proving the funds and governance rules are dedicated to managing that exact asset.

#### Generation

$\text{Key 1}$ is **deterministically derived** from the content's CID using a robust key derivation function. This means that if the content is identical, the CID is identical, and thus $\text{Key 1}$ is identical.

```javascript
// Pseudocode for Key 1 generation
function deriveKey1(contentCID) {
  // 1. Use content CID and a fixed salt as seed material
  const seed = SHA256(contentCID + "IPFS_SATS_KEY1_DERIVATION");
  
  // 2. Derive a robust private key
  const privateKey = HKDF(seed, "content-binding-key");
  const publicKey = derivePublicKey(privateKey);
  
  return { public: publicKey, fingerprint: RIPEMD160(SHA256(publicKey)) };
}
```

#### Security and Authority

Due to the deterministic nature of its derivation, $\text{Key 1}$'s **private key is theoretically knowable** to anyone who possesses the content and the derivation protocol. For this reason:

  * ❌ $\text{Key 1}$ is **NEVER** used alone for spending or making governance decisions.
  * ✅ $\text{Key 1}$ is used in combination with $\text{Key 2}$ (Creator/DAO) for **Emergency Recovery** or **Content Transfer** to ensure the new owner is taking control of the *correct* content.

#### Anti-Plagiarism Application

The deterministic nature of $\text{Key 1}$ creates an **automatic anti-plagiarism guard**.

1.  **Alice** uploads content $\rightarrow$ generates $\text{CID}_A \rightarrow$ derives $\text{Key1}_A$.
2.  **Bob** steals the same content and uploads it $\rightarrow$ generates the **same** $\text{CID}_A \rightarrow$ derives the **same** $\text{Key1}_A$.

The IPFS-Sats protocol detects two different wallets claiming the same $\text{Key1}_A$ and uses the **Bitcoin block timestamp** of the wallet creation transaction to instantly verify **Alice's wallet** as the original, authentic, and earlier claim.

#### Metadata Example

$\text{Key 1}$'s public key and derivation method are permanently stored in the DAO's metadata, making the content-to-wallet link publicly auditable.

```json
{
  "content_cid": "QmOriginalContent...",
  "wallet": {
    "address": "bc1q...",
    "keys": {
      "key1": {
        "type": "cid_derived",
        "derivation_method": "HKDF-SHA256",
        "public_key": "02a1b2c3d4...",
        "role": "content_binding"
      }
    }
  }
}
```

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

## 4.2.4 Fail-Safe and Recovery Mechanisms 🛡️

This section details the redundancy and recovery protocols built into the three-key architecture, ensuring that the loss or failure of any single key does not result in the permanent loss of the content, funds, or governance. These mechanisms represent the ultimate expression of human sovereignty over automated execution.

### Key Resilience Scenarios

The system's design ensures mutual dependence, allowing remaining keys to be used as proof of authority for recovery.

| Scenario | Required Recovery Keys | Functionality Retained |
| :--- | :--- | :--- |
| **$\text{Key 3}$ (Automation) Compromised/Stuck** | $\text{Key 2}$ + $\text{Key 1}$ | Human authority ($\text{Key 2}$) and content binding ($\text{Key 1}$) cooperate to override and replace the execution key. |
| **$\text{Key 2}$ (Human Control) Lost** | $\text{Key 1}$ + $\text{Key 3}$ Logs | The content binding ($\text{Key 1}$) and historical automated behavior ($\text{Key 3}$ logs) prove ownership for social recovery. |
| **$\text{Key 2}$ and $\text{Key 3}$ Both Lost** | $\text{Key 1}$ + $\text{Bitcoin}$ Timestamp | The deterministic content identifier ($\text{Key 1}$) combined with the immutable transaction timestamp proves the claim of original authorship. |

### 1. Key 3 Malfunction: Emergency Override ($\text{Key 2}$ + $\text{Key 1}$)

If the $\text{Smart Contract Execution Key}$ ($\text{Key 3}$) malfunctions, exceeds its programmed limits, or is suspected of being compromised, the human authority must be able to intervene immediately.

* **Mechanism:** The $\text{Key 2}$ holder(s) and the $\text{Key 1}$ derivation must cooperate to sign an **emergency override transaction**. This transaction explicitly revokes the compromised $\text{Key 3}$'s authority in the multi-sig and activates a new, freshly generated $\text{Key 3}$.
* **Result:** Automation is temporarily disabled. The $\text{DAO}$ is forced to manually approve all financial transactions using $\text{Key 2}$ signatures until the new $\text{Key 3}$ is fully operational and verified.

### 2. Key 2 Loss: Social/Behavioral Recovery ($\text{Key 1}$ + $\text{Key 3}$ Logs)

The loss of the human-controlled private key (e.g., destroyed hardware wallet) is mitigated via a recovery process utilizing cryptographic proofs and social consensus.

* **Proof of Claim:** The user leverages $\text{Key 1}$ (re-derived from their physical content) and the public, immutable $\text{Key 3}$ execution logs, which contain a pattern of authorized actions consistent with their identity.
* **Mechanism:** The user initiates a recovery process with pre-designated trusted recovery contacts. The contacts verify the user's identity off-chain and then co-sign a transaction with the content $\text{DAO}$ (using $\text{Key 1}$ and $\text{Key 3}$'s verified logs as proof) to issue a new $\text{Key 2}$ for the owner.

### 3. Worst-Case Loss: Ultimate Sovereignty ($\text{Key 1}$ + $\text{Bitcoin}$ Timestamp)

In the extreme scenario where the creator loses both their control key ($\text{Key 2}$) and the automated system key ($\text{Key 3}$).

* **Proof:** The owner can prove that the $\text{CID}$ of the original content (which regenerates $\text{Key 1}$) is their original creation. The unchangeable $\text{Bitcoin}$ transaction timestamp proves they were the first to register that $\text{Key 1}$ to the $\text{DAO}$ wallet.
* **Final Recourse:** This evidence constitutes an absolute claim of ownership that can be used in arbitration or a legal challenge to force the creation of a new $\text{Key 2}$ by the underlying protocol maintainers. This is the **ultimate fail-safe**, proving that **physical possession of the content and the cryptographic proof of creation outweigh all other factors.**

## 4.2.5 Authorization Matrix: The Key to Trustless Governance 🗝️

The Authorization Matrix defines the security model of $\text{IPFS}$-$\text{Sats}$, demonstrating how the separation of roles between the **Content $\text{Key}$ ($\text{Key 1}$)**, the **Human Control $\text{Key}$ ($\text{Key 2}$)**, and the **Execution $\text{Key}$ ($\text{Key 3}$)** enforces security and sovereignty.

A checkmark ($\checkmark$) indicates the cryptographic signature from that key is required for the transaction to be valid. An em dash (—) indicates the key is not required.

| Operation Category | Operation | Key 1 (Content) | Key 2 (Human Control) | Key 3 (Automation) | Notes / Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Permissionless Inflow** | Receive Lightning Zap | — | — | — | Standard Bitcoin behavior; permissionless by design. |
| | Receive On-Chain Deposit | — | — | — | Wallet always accepts funds; no key required to receive. |
| **Routine Automation** | Yield Distribution | — | — | $\checkmark$ | Executed automatically within $\text{DAO}$ limits and schedule. |
| | Host Payments | — | — | $\checkmark$ | Executes after verified Proof-of-Storage. |
| | Report Generation | — | — | $\checkmark$ | Routine metadata update; read-only data publishing. |
| | Liquidity Lease Renewal | — | — | $\checkmark$ | Automated financial optimization (if profitable). |
| **Governance & Policy** | Change Yield Split | — | $\checkmark$ | $\checkmark$ | Requires $\text{DAO}$ vote ($\text{Key 2}$ consensus) for execution ($\text{Key 3}$). |
| | Add/Remove Member | — | $\checkmark$ | $\checkmark$ | Modifies the $\text{Key 2}$ multi-sig structure. |
| | Update Contract Rules | — | $\checkmark$ | $\checkmark$ | Change to automation logic, requires $\text{Key 2}$ consensus. |
| | Large Withdrawal | — | $\checkmark$ | $\checkmark$ | Exceeds $\text{Key 3}$'s auto-approve limit; requires $\text{DAO}$ vote. |
| | Emergency Pause | — | $\checkmark$ | $\checkmark$ | Halts $\text{Key 3}$ execution after a rapid $\text{Key 2}$ vote. |
| **Ultimate Sovereignty** | **Replace $\text{Key 3}$** | $\checkmark$ | $\checkmark$ | — | **Override:** Bypasses a compromised $\text{Key 3}$ (Fail-Safe 1). |
| | **Transfer Ownership** | $\checkmark$ | $\checkmark$ | $\checkmark$ | Sale of content asset; requires all three for final transfer of $\text{Key 2}$. |
| | **DAO Dissolution** | $\checkmark$ | $\checkmark$ | — | Final withdrawal/migration; highest security clearance required. |

---

## Summary: Operational Security

The $\text{IPFS}$-$\text{Sats}$ three-key architecture creates **defense in depth** by separating authority into distinct, role-based keys. This separation ensures that no single point of failure can compromise the asset or its governance structure.

| Principle | Key/Combination | Security Gain |
| :--- | :--- | :--- |
| **No Single Point of Failure** | $\text{Key 1, Key 2, Key 3}$ | No one key can act alone for critical operations (e.g., spending, rule changes). |
| **Automation without Risk** | $\text{Key 3}$ | Executes routine tasks efficiently but operates within strict, pre-defined spending limits. |
| **Human Oversight** | $\text{Key 2}$ + $\text{Key 3}$ (or $\text{Key 1}$ in emergency) | $\text{Key 2}$ can always pause automated processes or initiate a vote to override $\text{Key 3}$. |
| **Content Integrity** | $\text{Key 1}$ | Cryptographically ensures the wallet and funds are dedicated to the specific, verifiable content ($\text{CID}$). |
| **Recovery Possible** | $\text{Key 1}$ + $\text{Key 2}$ or $\text{Key 1}$ + $\text{Key 3}$ Logs | Multiple paths to regain control or replace compromised keys, preventing permanent loss. |

This robust combination enables $\text{IPFS}$-$\text{Sats}$ to be simultaneously:

* **Accessible:** Anyone can "zap" funds without permission ($\text{Key 1, 2, 3}$ not required for inflow).
* **Automated:** Routine operations happen efficiently and instantly without human intervention ($\text{Key 3}$ alone).
* **Secure:** Major changes require consensus and a timelock ($\text{Key 2}$ + $\text{Key 3}$).
* **Recoverable:** Multiple fail-safes prevent permanent loss of control ($\text{Key 1}$ + $\text{Key 2}$ for override).
