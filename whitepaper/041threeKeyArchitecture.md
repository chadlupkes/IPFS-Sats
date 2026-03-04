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

## 4.1.2 Key 2: Creator/DAO Control Key (Human Authority) 👤

$\text{Key 2}$ represents the **human authority** within the IPFS-Sats multi-sig structure. This key, or set of keys, is controlled by the creator(s), DAO members, or the managing organization, and is used to authorize all major policy and financial decisions.

### Purpose and Generation

$\text{Key 2}$ is generated **independently** of the content CID and is intended to be linked directly to the creator's persistent decentralized identity ($\text{DID}$).

| Aspect | Detail |
| :--- | :--- |
| **Purpose** | To enforce **human governance**, manage policy, and execute emergency overrides. |
| **Derivation** | Generated using standard cryptographic methods (e.g., $\text{secp256k1}$, $\text{Ed25519}$), often derived from an existing identity system ($\text{Nostr}$, $\text{Bitcoin}$ wallet, $\text{DID}$). |
| **Security Focus** | **Secure storage** is paramount, as compromise means loss of governance control. |

#### Key Generation Pseudocode

The process is flexible, allowing users to leverage existing identity keys or generate a fresh key pair.

```javascript
function generateKey2(identityType, identityData) {
  // Key 2 is based on the creator's identity, not content
  switch(identityType) {
    case "nostr": // Use existing secp256k1 key
    case "ethereum":
      return { public: identityData.publicKey, type: "secp256k1" };
      
    case "bitcoin": // Derive from Bitcoin wallet HD structure
      return deriveBitcoinKey(identityData.masterKey, "m/84'/0'/0'/0/0");
      
    case "did:key": // Generate fresh Ed25519 key pair
    default:
      return generateEd25519KeyPair();
  }
}
```

-----

### Control Structure: Single vs. Multi-Member

$\text{Key 2}$ can be structured to support both solo creators and complex decentralized organizations.

#### 1\. Single Creator Control (Solo Mode)

For a solo creator, $\text{Key 2}$ is simply one private key controlled by that individual.

```json
"key2": {
  "type": "single_owner",
  "public_key": "03b4c5d6e7...",
  "identity": "did:key:alice...",
  "role": "creator_control"
}
```

#### 2\. Multi-Member DAO Control (Collaborative Mode)

For collaborative projects, $\text{Key 2}$ becomes an **internal multi-sig or weighted voting structure** itself, enforcing the DAO's governance rules for major changes.

```json
"key2": {
  "type": "multi_member_dao",
  "threshold": 3, // Requires 3 signatures (or weighted majority)
  "total_members": 5,
  "members": [
    { "public_key": "02a1b2c3...", "identity": "did:key:alice...", "weight": 40 },
    { "public_key": "03d4e5f6...", "identity": "did:key:bob...", "weight": 30 }
    // ... more members
  ],
  "role": "dao_governance"
}
```

-----

### Key 2 Authorization Matrix

$\text{Key 2}$ is the primary key for state-changing operations, usually requiring cooperation with $\text{Key 3}$ (Automation Key) for routine governance, or $\text{Key 1}$ (Content Key) for emergency overrides.

| Key Combination | Authorized Operations | Purpose |
| :--- | :--- | :--- |
| **Key 2 + Key 3** | Change $\text{Yield}$ distribution percentages, $\text{Update}$ smart contract rules, $\text{Add/remove}$ DAO members, $\text{Grant}$ licenses, $\text{Withdraw}$ routine funds. | **Standard Governance:** Enforcing DAO policy by combining human intent with the current automated rules. |
| **Key 2 + Key 1** | $\text{Emergency recovery}$ (if $\text{Key 3}$ compromised), $\text{Override}$ malfunctioning smart contract, $\text{Dissolve}$ DAO and reclaim funds. | **Emergency Override:** Bypassing automation to perform high-risk, trust-critical actions. |
| **Key 2 Alone** | $\text{Delegate}$ voting authority, $\text{Sign}$ a vote on a proposal (read-only action). | **Non-Custodial Actions:** Actions that don't directly move funds or change core rules. |

### Security and Delegation

The security of $\text{Key 2}$ is managed through best practices common to high-value crypto assets:

  * **Security Model:** Utilizing **hardware wallets**, $\text{M-of-N}$ multi-sig for groups (e.g., 2-of-3 for core team), and optional social recovery methods.
  * **Time-locks:** For maximum security, all major operations (e.g., withdrawing large sums, transferring ownership) authorized by $\text{Key 2}$ are subject to an enforced **time-lock delay** (e.g., 24-48 hours) to allow for review or veto.

#### Delegation and Proxies

$\text{Key 2}$ holders can delegate limited authority to other members or trusted advisors without transferring ownership of the actual control key. This is managed via an on-chain/IPFS record:

```json
"delegations": [
  {
    "delegate_to": "did:key:trusted_advisor...",
    "permissions": ["vote_on_proposals"], // Limited scope
    "excluded": ["withdraw_funds", "change_membership"],
    "expires": 1750636800,
    "revocable": true
  }
]
```

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
