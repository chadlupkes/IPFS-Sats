# 4.2 Operations

The three-key architecture enables a spectrum of operations ranging from fully permissionless (anyone can send payments) to highly restricted (only DAO supermajority can authorize). This section maps each type of operation to its required key combinations, creating a clear authorization matrix that balances accessibility, automation, and security.

Understanding this authorization model is critical for both users and developers: users need to know what they can do unilaterally versus what requires consensus, and developers need to implement the correct verification logic for each operation type.

---

## 4.2.1 Receiving Payments (No Signature Required)

**Principle:** Anyone can send value to the Lightning Yield Wallet (LYW) without requiring any signatures from the DAO or its members. This is fundamental to the value-for-value economy — users must be able to send micropayments to content creators instantly and spontaneously.

The wallet's unique multi-signature address is designed to be a standard Bitcoin/Lightning destination, ensuring maximum accessibility.

### Operations: Inflows to the LYW

Incoming funds are categorized by their origin and purpose, but all share the property of being permissionless to receive.

**1. Lightning Zaps (Micropayments)**

Users send instant, low-fee Lightning payments directly to the wallet's Lightning Address, which is stored in the content's Metadata Bundle. This is the primary source of revenue.

> Example: A fan sends 1,000 sats to a musician's content DAO wallet via a standard Lightning invoice. The LYW balance increases automatically.

**2. Bitcoin On-Chain Deposits**

Used for larger amounts, initial channel funding, or capital contributions. These funds are sent to the 3-of-3 multi-sig Bitcoin address (derived from Keys 1+2+3).

> Example: An investor deposits 0.01 BTC to the DAO wallet's on-chain address.

**3. Content Retrieval Micropayments**

These payments are made by users to hosts in exchange for content retrieval. They occur atomically via HTLC (Hashed Timelock Contract) to ensure the exchange is trustless.

- The host generates a payment request (invoice)
- The user pays the invoice
- The HTLC ensures the user gets the content only if payment succeeds, and the host gets payment only if content is delivered — no signatures are required from the content DAO itself

### Why Receiving is Permissionless

Receiving payments is permissionless by design to eliminate friction and maximize the value-for-value mechanism:

- **Enables Spontaneous Support:** Participants can support content instantly without identity registration or authorization delays
- **Increases Accessibility:** Anyone with a standard Bitcoin or Lightning wallet can contribute, aligning with the open, permissionless nature of the underlying protocols
- **Security Principle:** While receiving is permissionless, spending funds always requires one or more signatures (Key 3 for automation, Key 2 for governance), ensuring the wallet's assets cannot be compromised by incoming payments

### Policy and Accounting

The DAO metadata includes policies to mitigate abuse and ensures full transparency.

**Dust Attack Prevention:**

The DAO can set a minimum payment threshold and rate limits to prevent denial-of-service (DoS) attacks via numerous tiny payments.

```json
"receiving_policy": {
  "minimum_payment": 1,
  "rate_limit": {
    "max_per_minute": 100,
    "max_per_hour": 1000
  },
  "reject_from": []
}
```

**Accounting and Auditability:**

All received payments are automatically logged and published to the network for public transparency and DAO auditing.

```json
{
  "received_payments": [
    {
      "timestamp": 1735094400,
      "amount": 1000,
      "source": "anonymous_zap",
      "type": "lightning_zap",
      "memo": "Love this song!"
    }
  ]
}
```

---

## 4.2.2 Routine Operations (Automated via Key 3)

**Principle:** Pre-approved, recurring operations execute automatically without human intervention, enabling the self-sustaining economic model of IPFS-Sats. The goal is to move the system from requiring constant human oversight to operating as a **digital perpetual machine**.

**Authorization:** Key 3 only (within pre-defined limits and DAO-approved rules).

### Operations: Automated Financial and Governance Tasks

**1. Yield Distribution**

The core financial mechanism. Key 3 runs on a set schedule (e.g., daily or weekly) to automatically calculate and distribute funds earned by the LYW.

- **Mechanism:** Key 3 retrieves the DAO's current `yield_split` percentages and applies them to the earned yield. Individual shares are sent instantly via Lightning to member addresses; the Compound Share is reinvested into the LYW pool for persistence.
- **Authorization Check:** Key 3 verifies that the distribution percentages match the current DAO rules and that the total amount is within its daily spending limits. If checks pass, Key 3 signs the multi-sig transaction automatically.

**2. Host Payments (Proof-of-Storage)**

The maintenance mechanism that financially secures data persistence.

- **Mechanism:** Key 3 initiates a cryptographic challenge to hosts storing the content, requesting a Proof-of-Storage (e.g., a Merkle proof). Only hosts that provide a valid proof within the response time limit are approved for payment. Payment is calculated from the Compound Pool and sent instantly via Lightning. Hosts who fail verification are flagged for replacement.
- **Authorization Check:** Key 3 verifies that the storage proof is valid and that the payment is within the pre-defined host budget.

**3. Content Retrieval Payments**

When content is sold or leased on demand (retrieval-as-a-service), Key 3 ensures the host is compensated.

- **Mechanism:** The content buyer pays the host for retrieval. Key 3 is responsible for routing the payment, ensuring the transaction is atomic and fast.
- **Authorization Check:** Key 3 verifies the proof of content delivery and that the payment amount is within the expected per-retrieval limits.

**4. Report Generation**

Ensuring transparency and auditability for all stakeholders.

- **Mechanism:** Key 3 gathers all financial, governance, and host performance data over a set period, compiles it into a comprehensive report, publishes the immutable report to the network, and signs a metadata update to link the new report's CID to the DAO record.
- **Authorization Check:** This is a read-only data aggregation operation followed by a routine, pre-approved metadata update, which Key 3 executes automatically.

**5. Liquidity Lease Renewals**

Maintaining the functionality and profitability of the LYW.

- **Mechanism:** Key 3 monitors the expiration of Lightning Network liquidity leases. If a lease is profitable and nearing expiration, Key 3 automatically calculates the optimal renewal terms and executes the renewal transaction using funds from the Compound Pool.
- **Authorization Check:** Key 3 verifies that the lease renewal is net positive and that the amount is within the designated liquidity management budget.

### Limits on Automated Operations

To prevent unauthorized or faulty automation, Key 3 operates within three tiers of authorization:

| Category | Authority | Required Key Combination |
|---|---|---|
| **Tier 1: Routine Automation** | Execute automatically within budget | Key 3 Alone |
| **Tier 2: Policy/Major Finance** | Requires DAO vote and Key 2 approval | Key 2 + Key 3 |
| **Tier 3: Forbidden Actions** | Cannot be executed by Key 3 under any circumstance | N/A |

```json
"key3_automation_limits": {
  "max_payment_per_transaction": 10000,
  "max_daily_total": 100000,

  "allowed_without_approval": [
    "yield_distribution",
    "host_payment",
    "content_retrieval",
    "report_generation",
    "lease_renewal"
  ],

  "absolutely_forbidden": [
    "ownership_transfer",
    "key_replacement",
    "dao_dissolution"
  ]
}
```

### Exceeding Limits: Escalation to Governance

If Key 3 attempts an operation that exceeds its pre-approved limits, the transaction is rejected and the action is automatically escalated into a formal DAO proposal requiring human review and Key 2 authorization.

> Example: An exceptional host payment is needed that exceeds the 10,000 sats limit. Key 3 rejects the automatic payment and creates a DAO Proposal for a Large Payment, requiring member vote and Key 2's signature for final execution.

---

## 4.2.3 Major Operations (Require DAO Approval via Key 2 + Key 3) 🤝

**Principle:** Significant changes affecting governance, economics, or membership require human authorization through a formal consensus process.

**Authorization:** Key 2 + Key 3 (human decision-making combined with automated execution).

### Governance Process Flow: Proposal to Execution

All major operations follow a strict, multi-stage process to ensure deliberate and auditable decisions:

1. **Proposal Created:** A member submits a formal request to change the DAO's state
2. **DAO Members Vote (Key 2 Signatures):** Members secure their vote using their individual Key 2 authority
3. **Consensus Check:** The system verifies that the required Quorum and Threshold (e.g., a 66% majority) are met
4. **Timelock Period:** A mandatory delay (e.g., 24–72 hours) begins, allowing for final review or veto before funds or rules are altered
5. **Key 3 Executes:** Upon successful consensus and expiration of the timelock, Key 3 automatically enacts the change in the smart contract's state

### Operations Requiring Consensus

**1. Yield Distribution Changes**

Modifying how revenue is split among members and the compounding pool.

- **Mechanism:** A proposal defines the new `yield_split` percentages. Members vote using Key 2. If passed, Key 3 updates the contract variable.
- **Authorization:** DAO majority via Key 2 signatures, finalized by Key 3's state-change signature.

**2. Membership Changes**

Adding new collaborators or removing existing members.

- **Mechanism:** The proposal outlines the new member list and the rebalancing of voting weights. If approved, Key 3 updates the official Key 2 multi-sig structure and the membership record.
- **Authorization:** DAO consensus via Key 2 signatures.

**3. Smart Contract Updates**

Modifying the core operational logic or parameters of the automation system.

- **Mechanism:** DAO approval is required to prevent unilateral rule changes. If approved, Key 3 implements the new parameters. For major upgrades, Key 2's signature is required alongside Key 3 to authorize deployment of a new contract version.
- **Authorization:** Key 2 consensus is mandatory for all policy-altering actions.

**4. License Grants**

Formal authorization for granting exclusive rights, derivative work approvals, or commercial licensing terms.

- **Mechanism:** Upon approval, Key 3 generates a verifiable License Certificate CID and records the terms into the DAO's immutable metadata. If payment is involved, Key 3 generates a time-sensitive Lightning invoice for atomic execution.

**5. Large Withdrawals**

Any withdrawal exceeding Key 3's pre-approved automated daily limit must be escalated.

- **Mechanism:** Members vote on the amount, recipient, and reason. If approved by Key 2 consensus, Key 3 is authorized to bypass its normal spending limit and process the transaction.

**6. Emergency Actions**

Time-sensitive operations to protect the DAO's assets or function.

- **Emergency Pause:** A proposal to temporarily freeze all automated Key 3 operations. Voting periods are expedited and thresholds are typically increased (e.g., 80%). Execution is handled by Key 3 after the expedited timelock.
- **Key Replacement:** If Key 3 is compromised, the replacement bypasses the compromised key and requires the cooperation of Key 2 (human authority) and Key 1 (content binding).

**7. Ownership Transfer**

Transferring complete control of the content DAO (e.g., selling the content asset to a new entity).

- **Mechanism:** Requires the highest level of consensus (often 100% of Key 2 weight). If approved, Key 3 executes the transfer of the Key 2 control key to the new owner(s) and records the final sale terms — including any retained perpetual royalties — in the immutable DAO history.
- **Key Status:** Key 1 and Key 3 remain unchanged (preserving identity and automation), but are now under the control of the new Key 2 holders.

---

## 4.2.4 Fail-Safe and Recovery Mechanisms 🛡️

This section details the redundancy and recovery protocols built into the three-key architecture, ensuring that the loss or failure of any single key does not result in the permanent loss of the content, funds, or governance. These mechanisms represent the ultimate expression of human sovereignty over automated execution.

### Key Resilience Scenarios

The system's design ensures mutual dependence, allowing remaining keys to be used as proof of authority for recovery.

| Scenario | Required Recovery Keys | Functionality Retained |
|---|---|---|
| **Key 3 (Automation) Compromised** | Key 2 + Key 1 | Human authority (Key 2) and content binding (Key 1) cooperate to override and replace the execution key |
| **Key 2 (Human Control) Lost** | Key 1 + Key 3 Logs | Content binding (Key 1) and historical automated behavior (Key 3 logs) prove ownership for social recovery |
| **Key 2 and Key 3 Both Lost** | Key 1 + Bitcoin Timestamp | The deterministic content identifier (Key 1) combined with the immutable transaction timestamp proves the claim of original authorship |

### 1. Key 3 Malfunction: Emergency Override (Key 2 + Key 1)

If the Smart Contract Execution Key (Key 3) malfunctions, exceeds its programmed limits, or is suspected of being compromised, human authority must be able to intervene immediately.

- **Mechanism:** The Key 2 holder(s) and the Key 1 derivation must cooperate to sign an emergency override transaction. This transaction explicitly revokes the compromised Key 3's authority in the multi-sig and activates a new, freshly generated Key 3.
- **Result:** Automation is temporarily disabled. The DAO is forced to manually approve all financial transactions using Key 2 signatures until the new Key 3 is fully operational and verified.

### 2. Key 2 Loss: Social/Behavioral Recovery (Key 1 + Key 3 Logs)

The loss of the human-controlled private key (e.g., destroyed hardware wallet) is mitigated via a recovery process utilizing cryptographic proofs and social consensus.

- **Proof of Claim:** The user leverages Key 1 (re-derived from their content) and the public, immutable Key 3 execution logs, which contain a pattern of authorized actions consistent with their identity.
- **Mechanism:** The user initiates a recovery process with pre-designated trusted recovery contacts. The contacts verify the user's identity off-chain and then co-sign a transaction with the content DAO — using Key 1 and Key 3's verified logs as proof — to issue a new Key 2 for the owner.

### 3. Worst-Case Loss: Ultimate Sovereignty (Key 1 + Bitcoin Timestamp)

In the extreme scenario where the creator loses both the control key (Key 2) and the automated system key (Key 3):

- **Proof:** The owner can prove that the CID of the original content (which regenerates Key 1) is their original creation. The unchangeable Bitcoin transaction timestamp proves they were the first to register that Key 1 to the DAO wallet.
- **Final Recourse:** This evidence constitutes an absolute claim of ownership that can be used in arbitration or a legal challenge to force the creation of a new Key 2 by the underlying protocol maintainers. This is the **ultimate fail-safe** — proving that physical possession of the content and the cryptographic proof of creation outweigh all other factors.

---

## 4.2.5 Authorization Matrix 🗝️

The Authorization Matrix defines the complete security model of IPFS-Sats, demonstrating how the separation of roles between Key 1 (Content), Key 2 (Human Control), and Key 3 (Execution) enforces security and sovereignty.

A checkmark (✓) indicates the cryptographic signature from that key is required for the transaction to be valid. A dash (—) indicates the key is not required.

| Operation Category | Operation | Key 1 (Content) | Key 2 (Human) | Key 3 (Automation) | Notes |
|---|---|:---:|:---:|:---:|---|
| **Permissionless Inflow** | Receive Lightning Zap | — | — | — | Standard Bitcoin behavior; permissionless by design |
| | Receive On-Chain Deposit | — | — | — | Wallet always accepts funds; no key required to receive |
| **Routine Automation** | Yield Distribution | — | — | ✓ | Executed automatically within DAO limits and schedule |
| | Host Payments | — | — | ✓ | Executes after verified Proof-of-Storage |
| | Report Generation | — | — | ✓ | Routine metadata update; read-only data publishing |
| | Liquidity Lease Renewal | — | — | ✓ | Automated financial optimization (if profitable) |
| **Governance & Policy** | Change Yield Split | — | ✓ | ✓ | Requires DAO vote (Key 2 consensus) for execution (Key 3) |
| | Add/Remove Member | — | ✓ | ✓ | Modifies the Key 2 multi-sig structure |
| | Update Contract Rules | — | ✓ | ✓ | Change to automation logic requires Key 2 consensus |
| | Large Withdrawal | — | ✓ | ✓ | Exceeds Key 3's auto-approve limit; requires DAO vote |
| | Emergency Pause | — | ✓ | ✓ | Halts Key 3 execution after a rapid Key 2 vote |
| **Ultimate Sovereignty** | Replace Key 3 | ✓ | ✓ | — | Override: bypasses a compromised Key 3 (Fail-Safe 1) |
| | Transfer Ownership | ✓ | ✓ | ✓ | Sale of content asset; requires all three keys |
| | DAO Dissolution | ✓ | ✓ | — | Final withdrawal/migration; highest security clearance required |

---

## Summary: Operational Security

The IPFS-Sats three-key architecture creates **defense in depth** by separating authority into distinct, role-based keys. This separation ensures that no single point of failure can compromise the asset or its governance structure.

| Principle | Key/Combination | Security Gain |
|---|---|---|
| **No Single Point of Failure** | Key 1, Key 2, Key 3 | No one key can act alone for critical operations (spending, rule changes) |
| **Automation without Risk** | Key 3 | Executes routine tasks efficiently within strict, pre-defined spending limits |
| **Human Oversight** | Key 2 + Key 3 (or Key 1 in emergency) | Key 2 can always pause automated processes or initiate a vote to override Key 3 |
| **Content Integrity** | Key 1 | Cryptographically ensures the wallet and funds are dedicated to the specific, verifiable content (CID) |
| **Recovery Possible** | Key 1 + Key 2 or Key 1 + Key 3 Logs | Multiple paths to regain control or replace compromised keys, preventing permanent loss |

This combination enables IPFS-Sats to be simultaneously:

- **Accessible:** Anyone can send funds without permission (Keys 1, 2, 3 not required for inflow)
- **Automated:** Routine operations happen efficiently and instantly without human intervention (Key 3 alone)
- **Secure:** Major changes require consensus and a timelock (Key 2 + Key 3)
- **Recoverable:** Multiple fail-safes prevent permanent loss of control (Key 1 + Key 2 for override)
