## 4.1.3 Key 3: Smart Contract Execution Key (Automated Authority) 🤖

The **Smart Contract Execution Key ($\text{Key 3}$)** is the operational engine of the per-content $\text{DAO}$. It enables **trustless automation** by autonomously executing routine, pre-approved financial and governance operations, eliminating human bottlenecks for day-to-day transactions.

### Key Generation and Control

$\text{Key 3}$ is deterministically bound to the $\text{DAO}$'s core rules and wallet seed. Any change to the smart contract logic requires re-derivation and replacement of $\text{Key 3}$, necessitating $\text{Key 2}$'s approval.

#### Generation Pseudocode

```javascript
function generateKey3(walletSeed, contractRules) {
  // Derive Key 3 from wallet seed + contract hash
  const contractHash = SHA256(JSON.stringify(contractRules));
  const seed = HKDF(walletSeed, contractHash, "smart-contract-key");
  
  const privateKey = derivePrivateKey(seed);
  const publicKey = derivePublicKey(privateKey);
  
  return {
    private: privateKey,
    public: publicKey,
    type: "ed25519",
    managed_by: "smart_contract_executor",
    role: "automated_operations"
  };
}
```

#### Private Key Management: The Trustless Imperative

The security and trustlessness of the entire $\text{DAO}$ hinges on the management of $\text{Key 3}$'s private key. The private key must be held by an execution environment that is verifiably constrained by the smart contract code.

  * **Option 1: Decentralized Oracle Network (Recommended Start)**
      * Multiple independent nodes run the smart contract logic.
      * A **Threshold Signature Scheme** (e.g., $5$-of-$9$ nodes) signs transactions, requiring consensus and eliminating a single point of failure.
  * **Option 2: Trusted Execution Environment (Secure Hardware)**
      * $\text{Key 3}$ stored in a hardware security module ($\text{HSM}$) or secure enclave (Intel $\text{SGX}$).
      * Guarantees the key cannot be extracted, even by the physical machine operator.
  * **Option 3: Multi-Party Computation (MPC - Goal State)**
      * $\text{Key 3}$'s private key is **never whole**; it is split into shares ($\text{Shamir's Secret Sharing}$).
      * A threshold of parties must cooperate to generate a signature, achieving maximum trustlessness.

$\text{IPFS}$-$\text{Sats}$ Recommendation: Start with Option 1 (decentralized oracles), migrate to Option 3 ($\text{MPC}$) as technology matures.

### Key 3 Authorization Matrix

$\text{Key 3}$ operates under a tightly scoped set of permissions.

| Key Combination | Authorized Operations |
| :--- | :--- |
| **Key 3 Alone** | Distribute yield per split, Pay hosts for verified storage, Process micropayments for content retrieval, Renew liquidity leases, Execute approved proposals (after timelock). |
| **Key 3 + Key 2** | Change smart contract rules (requires $\text{DAO}$ vote), Withdraw beyond auto-approved threshold, Grant new licenses. |
| **Key 3 CANNOT do** | Change $\text{DAO}$ membership, Transfer ownership, Override $\text{DAO}$ votes. |

#### Automated Execution Limits (Safety Caps)

To prevent errors or exploitation from becoming catastrophic, $\text{Key 3}$'s automated spending is limited by hard-coded caps.

```json
{
  "key3_permissions": {
    "max_payment_per_tx": 10000,  // sats
    "max_daily_payments": 100000,  // sats
    "requires_dao_approval_above": 50000,  // sats
    "allowed_operations": [
      "yield_distribution",
      "host_payment",
      "content_retrieval_payment",
      "report_generation"
    ],
    "forbidden_operations": [
      "membership_change",
      "ownership_transfer",
      "contract_rule_change"
    ]
  }
}
```

### Smart Contract Verification Logic

Before $\text{Key 3}$ signs any transaction, the execution environment runs a series of non-bypassable compliance checks.

```javascript
async function key3Sign(operation) {
  // 1. Verify operation type allowed
  if (!isAllowedOperation(operation.type)) {
    throw new Error("Operation not permitted by Key 3");
  }
  
  // 2. Check amount limits
  if (operation.amount > getLimits().max_payment_per_tx) {
    throw new Error("Amount exceeds Key 3 limit, requires DAO approval");
  }
  
  // 3. Verify daily budget
  const dailySpent = await getDailySpending();
  if (dailySpent + operation.amount > getLimits().max_daily_payments) {
    throw new Error("Daily spending limit reached");
  }
  
  // 4. Check DAO not paused
  const dao = await getDAO(operation.dao_cid);
  if (dao.smart_contract.paused) {
    throw new Error("DAO operations paused");
  }
  
  // 5. Verify prerequisites (e.g., storage proof for host payment)
  if (operation.type === "host_payment") {
    const proofValid = await verifyStorageProof(operation.host, operation.content_cid);
    if (!proofValid) {
      throw new Error("Storage proof invalid");
    }
  }
  
  // 6. All checks passed, sign transaction
  const signature = await signWithKey3(operation);
  return signature;
}
```

### Transparency, Auditability, and Emergency Override

Every action taken by $\text{Key 3}$ is logged and published to $\text{IPFS}$, ensuring full auditability by $\text{DAO}$ members.

#### Operation Log Example

```json
{
  "key3_operation_log": [
    {
      "timestamp": 1735094400,
      "operation": "yield_distribution",
      "amount": 30000,
      "recipients": ["alice", "bob", "compound"],
      "transaction_id": "abc123...",
      "verification_proof": "QmProof..."
    },
    {
      "timestamp": 1735180800,
      "operation": "host_payment",
      "amount": 10000,
      "recipient": "did:host:xyz...",
      "storage_proof": "QmStorageProof...",
      "transaction_id": "def456..."
    }
  ]
}
```

#### Emergency Override Procedure

In the event of $\text{Key 3}$ malfunction or compromise, the ultimate human authority ($\text{Key 2}$) can replace it, requiring the content binding ($\text{Key 1}$) for final confirmation:

```javascript
// Key 2 + Key 1 can override Key 3
async function emergencyOverride(key2Signature, key1Signature, newKey3) {
  // Requires both human authority (Key 2) and content binding (Key 1)
  if (verifySignature(key2Signature) && verifySignature(key1Signature)) {
    // Logic to replace Key 3 within the 3-of-3 multi-sig structure
    const oldKey3 = getCurrentKey3();
    revokeKey(oldKey3);
    activateKey(newKey3);
    
    // Log emergency action
    logEmergency({
      action: "KEY3_REPLACEMENT",
      old_key: oldKey3.fingerprint,
      new_key: newKey3.fingerprint,
      authorized_by: [key2Signature.signer, key1Signature.signer],
      timestamp: Date.now()
    });
  }
}
```

### Summary: Three-Key Synergy

The $\text{IPFS}$-$\text{Sats}$ three-key architecture uses role-based separation to create a robust and autonomous governance system:

  * **Key 1 (Content):** Ensures the wallet is cryptographically bound to specific content.
  * **Key 2 (Human):** Maintains ultimate control for policy decisions and emergency overrides.
  * **Key 3 (Automation):** Enables day-to-day operations and financial efficiency within $\text{DAO}$-approved boundaries.

Together, they enable: **Trustless automation**, **human sovereignty**, and **content integrity**, with security achieved through key separation—no single key can compromise the system.

-----
