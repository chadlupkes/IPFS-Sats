## 4.1.3 Key 3: Smart Contract Execution Key (Automated Authority) 🤖

$\text{Key 3}$ is the engine of the IPFS-Sats DAO, enabling **automated operations** like yield distribution and host payments without requiring human intervention for every transaction. It executes the collective will of the DAO as encoded in the smart contract rules.

### Generation and Control

$\text{Key 3}$'s private key is generated and managed by the secure execution environment that hosts the smart contract logic. Its public key is part of the 3-of-3 multi-sig address.

#### Key Generation Pseudocode

$\text{Key 3}$ is deterministically derived from the initial wallet seed and the hash of the immutable smart contract rules. This binding ensures that if the core rules change, the key must be replaced, requiring $\text{Key 2}$'s authorization.

```javascript
function generateKey3(walletSeed, contractRules) {
  // Derive Key 3 from wallet seed + contract hash
  const contractHash = SHA256(JSON.stringify(contractRules));
  const seed = HKDF(walletSeed, contractHash, "smart-contract-key");
  
  const privateKey = derivePrivateKey(seed);
  const publicKey = derivePublicKey(privateKey);
  
  return { public: publicKey, role: "automated_operations" };
}
```

#### Who Controls the Private Key?

The crucial aspect of $\text{Key 3}$'s security is how its private key is managed to ensure trustless automation:

  * **Decentralized Oracle Network (Recommended):** Multiple independent nodes run the smart contract logic and use a **Threshold Signature Scheme** (e.g., 5-of-9 nodes) to sign transactions. No single party holds the full key.
  * **Trusted Execution Environment (TEE):** The key is stored inside a secure hardware enclave (HSM, Intel SGX), where the smart contract runs. The code is attested, ensuring the key cannot be extracted, even by the server operator.
  * **Multi-Party Computation (MPC):** The private key is split into shares and is never whole. Multiple parties must cooperate to generate a signature, achieving maximum trustlessness.

-----

### Key 3 Authorization Matrix

$\text{Key 3}$ operates within strict, DAO-approved boundaries and typically requires $\text{Key 2}$'s signature for non-routine or policy-altering actions.

| Key 3 Action | Authorization Required | Examples of Operations |
| :--- | :--- | :--- |
| **Key 3 Alone** | **Self-Authorized** (within contract limits) | $\text{Distribute yield}$ per split, $\text{Pay hosts}$ for verified storage, $\text{Execute approved proposals}$ (after timelock), $\text{Generate routine reports}$. |
| **Key 3 + Key 2** | **Human Policy Approval** | $\text{Change smart contract rules}$ (e.g., quorum size), $\text{Withdraw funds}$ exceeding the auto-approved threshold, $\text{Grant new licenses}$. |
| **Key 3 + Key 1** | **Forbidden** | Key 3 cannot interact with Key 1 alone for any operation. |

#### Automated Execution Limits

To mitigate the risk of bugs or exploitation, $\text{Key 3}$'s permissions are limited by pre-defined caps established by $\text{Key 2}$ and the DAO.

```json
"key3_permissions": {
  "max_payment_per_tx": 10000, // Max sats per single automated payment
  "max_daily_payments": 100000, // Total sats Key 3 can spend per day
  "allowed_operations": [
    "yield_distribution",
    "host_payment",
    "content_retrieval_payment"
  ],
  "forbidden_operations": [
    "membership_change",
    "ownership_transfer"
  ]
}
```

#### Smart Contract Verification Logic

Before $\text{Key 3}$ authorizes any transaction, the execution environment runs a series of checks to ensure compliance with DAO rules and safety limits.

```javascript
async function key3Sign(operation) {
  // 1. Verify operation type and amount limits
  if (!isAllowedOperation(operation.type) || operation.amount > getLimits().max_payment_per_tx) {
    throw new Error("Operation or amount exceeds Key 3 limits");
  }
  
  // 2. Check for daily budget and emergency pause state
  const dailySpent = await getDailySpending();
  const dao = await getDAO(operation.dao_cid);
  if (dailySpent + operation.amount > getLimits().max_daily_payments || dao.smart_contract.paused) {
    throw new Error("Safety check failed (budget/pause)");
  }
  
  // 3. Verify specific prerequisites (e.g., Proof-of-Storage)
  if (operation.type === "host_payment" && !await verifyStorageProof(operation.host)) {
    throw new Error("Storage proof invalid");
  }
  
  // 4. All checks passed, sign and return transaction
  const signature = await signWithKey3(operation);
  return signature;
}
```

-----

## Summary: Three-Key Synergy

The IPFS-Sats three-key architecture creates a governance system that balances **security, autonomy, and sovereignty**. The three keys are mutually dependent for critical operations, ensuring a single point of failure cannot compromise the content, the funds, or the governance structure.

| Key | Core Function | Security Gain |
| :--- | :--- | :--- |
| **Key 1 (Content)** | **Identity & Binding** | Proves content authenticity and enables anti-plagiarism. |
| **Key 2 (Human)** | **Sovereignty & Policy** | Guarantees ultimate human control and the ability to override/pause automation. |
| **Key 3 (Automation)** | **Efficiency & Execution** | Enables trustless, instantaneous payments and operations without human bottlenecks. |

This robust combination delivers:

  * **Trustless Automation:** $\text{Key 3}$ efficiently manages day-to-day operations.
  * **Human Sovereignty:** $\text{Key 2}$ holds the ultimate veto and policy-setting power.
  * **Content Integrity:** $\text{Key 1}$ cryptographically anchors the wallet to the asset.

In the subsequent section, we will detail the specific operations and the key combinations required to authorize each action, from routine host payments to emergency DAO dissolution.
