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
