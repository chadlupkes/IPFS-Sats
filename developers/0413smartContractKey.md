# Developer Implementation Guide: Key 3 — Smart Contract Execution Key

The **Smart Contract Execution Key (Key 3)** is the operational engine of the Per-Content DAO. It enables trustless automation by executing routine, pre-approved financial and governance operations without human intervention for every transaction.

**Key 3 executes; it does not decide.** Every operation Key 3 performs is either triggered by a completed Key 2 governance vote, by an automated threshold condition defined in the DAO Configuration Object, or by an external event (such as an AtomicSats exchange completion) that satisfies a pre-approved condition. Key 3 has no discretionary authority.

---

## Key Generation

Key 3 is deterministically derived from the wallet seed and the contract rules hash. Any change to the smart contract logic requires re-derivation of Key 3, which requires Key 2 approval.

```javascript
function generateKey3(walletSeed, contractRules) {
  // Derive Key 3 from wallet seed + contract hash
  const contractHash = SHA256(JSON.stringify(contractRules));
  const seed = HKDF(walletSeed, contractHash, "smart-contract-key");

  const privateKey = derivePrivateKey(seed);
  const publicKey = derivePublicKey(privateKey);

  return {
    private:    privateKey,
    public:     publicKey,
    type:       "ed25519",
    managed_by: "smart_contract_executor",
    role:       "automated_operations"
  };
}
```

---

## Private Key Management

The trustlessness of the DAO depends on Key 3's private key being held by an execution environment that is verifiably constrained by the smart contract code. Three options, in order of maturity:

**Option 1: Decentralized Oracle Network (Recommended Starting Point)**
Multiple independent nodes run the smart contract logic. A threshold signature scheme (e.g., 5-of-9 nodes) signs transactions, requiring consensus and eliminating a single point of failure.

**Option 2: Trusted Execution Environment**
Key 3 stored in a hardware security module (HSM) or secure enclave (Intel SGX). Guarantees the key cannot be extracted, even by the physical machine operator.

**Option 3: Multi-Party Computation (Goal State)**
Key 3's private key is never whole — it is split into shares (Shamir's Secret Sharing). A threshold of parties must cooperate to generate a signature, achieving maximum trustlessness.

Recommended path: start with Option 1, migrate to Option 3 as MPC tooling matures.

---

## Key 3 Authorization Matrix

Key 3 operates under a tightly scoped set of permissions defined in the DAO Configuration Object.

| Key Combination | Authorized Operations |
|---|---|
| **Key 3 alone** | Distribute yield per income split; Fund host AtomicSats exchange payments; Process content access payments; Renew Lightning liquidity leases; Execute approved proposals after timelock expiry |
| **Key 3 + Key 2** | Change smart contract rules (requires DAO vote); Withdraw above auto-approved threshold; Grant new licenses |
| **Key 3 cannot do** | Change DAO membership; Transfer ownership; Override DAO votes; Initiate operations not in allowed_operations list |

### Automated Spending Caps

Hard-coded spending limits prevent errors or exploits from becoming catastrophic.

```json
{
  "key3_permissions": {
    "max_payment_per_tx_sats": 10000,
    "max_daily_payments_sats": 100000,
    "requires_dao_approval_above_sats": 50000,
    "allowed_operations": [
      "yield_distribution",
      "host_atomicsats_payment",
      "content_access_payment",
      "fork_royalty_routing",
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

---

## Smart Contract Verification Logic

Before Key 3 signs any transaction, the execution environment runs non-bypassable compliance checks.

```javascript
/**
 * Key 3 signing function — runs compliance checks before every operation.
 * @param {Object} operation - The operation to be signed.
 * @returns {string} signature
 */
async function key3Sign(operation) {
  // 1. Verify operation type is in the allowed list
  if (!isAllowedOperation(operation.type)) {
    throw new Error(`Operation type "${operation.type}" not permitted by Key 3`);
  }

  // 2. Check per-transaction amount limit
  if (operation.amount_sats > getLimits().max_payment_per_tx_sats) {
    throw new Error("Amount exceeds Key 3 per-transaction limit — requires DAO approval");
  }

  // 3. Check daily spending budget
  const dailySpent = await getDailySpending();
  if (dailySpent + operation.amount_sats > getLimits().max_daily_payments_sats) {
    throw new Error("Daily spending limit reached — resume after next distribution cycle");
  }

  // 4. Verify DAO is not in emergency pause state
  const dao = await getDAO(operation.dao_cid);
  if (dao.smart_contract.paused) {
    throw new Error("DAO operations paused — Key 3 requires Key 2 authorization to resume");
  }

  // 5. Operation-specific prerequisites

  if (operation.type === "host_atomicsats_payment") {
    // Prerequisite: an AtomicSats exchange has completed for this block delivery.
    // The HTLC preimage reveal is the proof of delivery — no separate
    // storage verification is required or implemented.
    const exchangeCompleted = await verifyAtomicSatsExchange(
      operation.atomicsats_exchange_id
    );
    if (!exchangeCompleted) {
      throw new Error("No completed AtomicSats exchange found for this payment");
    }
  }

  if (operation.type === "fork_royalty_routing") {
    // Prerequisite: child DAO payment received and upstream percentage computed
    const royaltyValid = await verifyForkRoyaltyTrigger(
      operation.child_dao_cid,
      operation.upstream_percentage
    );
    if (!royaltyValid) {
      throw new Error("Fork royalty trigger verification failed");
    }
  }

  // 6. All checks passed — sign and return
  const signature = await signWithKey3(operation);
  return signature;
}
```

---

## Operation Log

Every Key 3 action is logged as a content-addressed record, providing full auditability to DAO members and any external observer.

```json
{
  "key3_operation_log": [
    {
      "block_height": 875440,
      "operation": "yield_distribution",
      "amount_sats": 30000,
      "recipients": ["did:key:alice...", "did:key:bob...", "compound"],
      "transaction_id": "abc123...",
      "distribution_report_cid": "QmReport..."
    },
    {
      "block_height": 875441,
      "operation": "host_atomicsats_payment",
      "amount_sats": 10000,
      "recipient": "did:key:host_xyz...",
      "atomicsats_exchange_id": "exchange_abc...",
      "transaction_id": "def456..."
    },
    {
      "block_height": 875442,
      "operation": "fork_royalty_routing",
      "amount_sats": 5000,
      "child_dao_cid": "QmChildDAO...",
      "parent_lyw_address": "lnbc...",
      "upstream_percentage": 0.15,
      "transaction_id": "ghi789..."
    }
  ]
}
```

---

## Emergency Override

If Key 3 malfunctions or is compromised, Key 2 (Human Authority) and Key 1 (Content Binding) together can replace it.

```javascript
/**
 * Replaces Key 3 under emergency conditions.
 * Requires both Key 2 (human authority) and Key 1 (content binding) signatures.
 * Key 1 authorization is required because Key 3 replacement changes the
 * governance constraints Key 1 has established.
 * @param {string} key2Signature
 * @param {string} key1Signature
 * @param {Object} newKey3
 */
async function emergencyReplaceKey3(key2Signature, key1Signature, newKey3) {
  if (!verifySignature(key2Signature) || !verifySignature(key1Signature)) {
    throw new Error("Emergency override requires valid Key 2 and Key 1 signatures");
  }

  const oldKey3 = await getCurrentKey3();
  await revokeKey(oldKey3);
  await activateKey(newKey3);

  // Log emergency action — immutable audit record
  await logOperation({
    block_height: await getCurrentBlockHeight(),
    operation: "KEY3_EMERGENCY_REPLACEMENT",
    old_key_fingerprint: oldKey3.fingerprint,
    new_key_fingerprint: newKey3.fingerprint,
    authorized_by: [key2Signature.signer, key1Signature.signer]
  });
}
```

---

## Summary: Three-Key Architecture

| Key | Role | Authority |
|---|---|---|
| **Key 1 — Content Binding Key** | Establishes creator authority and defines the governance constraints within which Key 2 and Key 3 operate | Constitutional — sets the rules Key 2 and Key 3 must operate within |
| **Key 2 — Human Authority Key** | The DAO's human decision-making capacity — proposals, votes, authorizations | Governance — decides what Key 3 may do |
| **Key 3 — Execution Key** | Executes what Key 2 has authorized, within constraints Key 1 has established | Operational — executes without deciding |

The three-key architecture achieves trustless automation with human sovereignty and content integrity through role separation. No single key can compromise the system. Key 3 cannot override Key 2 votes. Key 2 cannot override Key 1 constraints without Key 1's participation. Key 1 establishes the constitutional layer that makes both possible.
