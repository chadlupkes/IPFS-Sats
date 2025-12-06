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
