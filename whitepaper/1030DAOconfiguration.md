# 10.3 DAO Configuration Object ⚙️

The **DAO Configuration Object** is the governance specification for a piece of content. It is pointed to by the `dao_cid` field in the Metadata Wrapper (Section 10.1) and defines the initial membership structure, voting parameters, smart contract logic, and lifecycle terms for the Per-Content DAO.

The DAO Configuration Object defines the *initial* governance rules. Whether those rules can be changed at runtime depends on how Key 1 is configured at publication time (Section 6.1). In the default unlocked configuration, the DAO's operational parameters — voting thresholds, membership weights, allowed actions — are governable through supermajority vote. When Key 1 is explicitly locked, no changes are permitted and this object represents permanent terms. The object itself is content-addressed: any change to its contents produces a new CID, creating an auditable history of governance evolution.

---

## JSON Schema: DAO Configuration Object

```json
{
  "protocol_version": "0.4",
  "content_cid": "<content-cid>",     // Content CID of the Metadata Wrapper this DAO governs

  // 1. MEMBER STRUCTURE (Defining Voting Power)
  "membership": {
    "model": "income_share",           // Voting weight derived from income distribution percentage
    "key1_config": {
      "type": "multisig_supermajority",// Options: "solo", "multisig_majority",
                                       // "multisig_supermajority", "universal_consensus", "locked"
      "signers": [
        { "did": "did:key:z6Mk...", "label": "creator" }
      ],
      "threshold": 0.67                // Fraction of Key 1 signers required for Key 1 actions
                                       // (ignored when type is "solo" or "locked")
    },
    "initial_members": [
      {
        "did": "did:key:z6Mk...",
        "income_share": 0.50,          // Fraction of income stream (0.0 to 1.0); sum must equal 1.0
        "role": "creator"              // Descriptive only — governance weight derives from income_share
      },
      {
        "did": "did:key:z7Nl...",
        "income_share": 0.30,
        "role": "initial_depositor"
      },
      {
        "did": "did:key:z8Om...",
        "income_share": 0.20,
        "role": "host_pool"
      }
    ]
  },

  // 2. VOTING PARAMETERS (Operational Security)
  "voting_rules": {
    "proposal_threshold": 0.001,       // Minimum income share required to submit a proposal (e.g., 0.1%)
    "standard_quorum": 0.35,           // Minimum income share participation for a binding vote (35%)
    "emergency_quorum": 0.20,          // Reduced quorum for emergency proposals (20%)
    "simple_majority_threshold": 0.51, // Threshold for operational proposals (51%)
    "supermajority_threshold": 0.67,   // Threshold for constitutional proposals (66.7%)
    "voting_period_blocks": 1008,      // Duration of voting period in Bitcoin blocks (~7 days at 10 min/block)
    "execution_delay_blocks": 144      // Delay between vote passage and execution (~24 hours)
  },

  // 3. SMART CONTRACT RULES (The Governance Logic)
  "governance_logic": {
    "implementation_type": "wasm",     // WebAssembly or equivalent content-agnostic execution environment
    "contract_cid": "<contract-cid>",  // Content-addressed hash of the smart contract bytecode
    "mutable_state_cid": "<state-cid>",// CID of the current mutable operational state
                                       // (e.g., active royalty splits, current license terms)
                                       // Updated by Key 3 after each successful governance execution
    "allowed_actions": [
      "update_income_distribution",    // Adjust member income shares (supermajority required)
      "update_membership",             // Add or remove DAO members (supermajority required)
      "update_smart_contract",         // Upgrade governance logic (supermajority + extended delay)
      "update_license_terms",          // Change licensing or access pricing (simple majority)
      "approve_fork",                  // Authorize a derivative work's parent-child CID link (simple majority)
      "emergency_pause",               // Temporarily suspend Key 3 automation (emergency quorum)
      "replace_key"                    // Replace a compromised Key 2 or Key 3 (supermajority + Key 1)
    ]
  },

  // 4. YIELD CONFIGURATION (Income Distribution and Persistence)
  "yield_config": {
    "lyw_address": "lnbc...",          // Lightning Yield Wallet address for this content
    "yield_split": {
      "creator": 0.50,                 // Fraction of yield distributed to creator and members
      "compound": 0.50                 // Fraction reinvested into LYW balance for persistence
    },
    "distribution_period_blocks": 4032 // Frequency of yield distribution cycles (~4 weeks)
  },

  // 5. LIFECYCLE AND SUNSET PARAMETERS (Persistence and End-of-Life)
  "lifecycle": {
    "sunset_condition": {
      "trigger_type": "balance_duration",
      "threshold_sats": 1000,          // LYW balance below this level triggers sunset evaluation
      "duration_blocks": 52596         // Balance must remain below threshold for this many blocks
                                       // (~1 year) before sunset is confirmed
    },
    "archival_action": {
      "action_type": "public_domain_release",
      "new_license_cid": "<cc0-license-cid>"  // License applied automatically on sunset
                                               // Common choice: CC0 (public domain dedication)
    }
  }
}
```

---

## Member Structure

The membership section defines who holds governance weight and how Key 1 authority is configured.

- **`membership.model`:** Set to `income_share` — voting weight in the Per-Content DAO is derived directly from each member's fraction of the income distribution, as defined in Section 6.1. There is no separate staking mechanism.
- **`membership.key1_config`:** Defines how Key 1 (Content Binding Key) authority is structured. The `type` field determines whether Key 1 actions require a single signer, a majority of signers, a supermajority, universal consensus, or are locked entirely. See Section 4.1 for the full Key 1 architecture.
- **`membership.initial_members`:** The genesis membership array. Each member's `income_share` defines both their fraction of the revenue stream and their voting weight. The sum of all `income_share` values must equal exactly 1.0. The `role` field is descriptive — governance weight derives from `income_share`, not role assignment.

---

## Voting Parameters

Voting parameters enforce participation requirements and passage thresholds, measured in fractions of total income share rather than raw member counts.

- **`voting_period_blocks`:** Measured in Bitcoin blocks rather than wall-clock time, ensuring the voting window is objective and cannot be manipulated by clock discrepancies. At the Bitcoin target of one block per ten minutes, 1008 blocks represents approximately seven days.
- **`execution_delay_blocks`:** The delay between a successful vote and Key 3 execution, giving all participants time to review the outcome before it takes effect. 144 blocks represents approximately 24 hours.
- **`standard_quorum` and `emergency_quorum`:** Two quorum tiers allow time-sensitive emergency proposals to proceed with reduced participation while protecting standard governance from minority capture.

---

## Smart Contract Rules

The governance logic section defines what the DAO is permitted to do and how that logic is executed.

- **`contract_cid`:** The content-addressed hash of the smart contract bytecode. Because it is content-addressed, the contract logic is verifiable by anyone — retrieving the bytecode at this CID and inspecting it confirms exactly what rules govern the DAO.
- **`mutable_state_cid`:** The only field in this object that changes at runtime. After each successful governance execution, Key 3 updates this CID to point to the new operational state — updated royalty splits, revised license terms, current membership weights. The history of state changes is auditable through the chain of CIDs.
- **`allowed_actions`:** An explicit allowlist of the operations this DAO may execute. Key 3 automation will not execute any action not present in this list, regardless of vote outcome. This prevents governance proposals from invoking arbitrary contract functions.

---

## Yield Configuration

The yield configuration defines how the LYW generates and distributes income for this content.

- **`lyw_address`:** The Lightning Yield Wallet address. This is the same address published in the Metadata Wrapper's `wallet_address` field — the two must match. Zaps, access fees, and fork royalties all flow to this address.
- **`yield_split`:** The fraction of generated yield distributed to DAO members versus reinvested into the LYW balance for persistence funding. Configurable by DAO vote (supermajority). See Section 5.2.2 for the full yield distribution model.
- **`distribution_period_blocks`:** How frequently Key 3 executes yield distribution cycles. Measured in Bitcoin blocks for the same reason as voting periods.

---

## Lifecycle and Sunset Parameters

The lifecycle section defines the terms for graceful content end-of-life, ensuring that when a content's economic runway runs out, its final disposition is handled automatically according to the original governance design rather than simply disappearing.

- **`sunset_condition`:** Defines the trigger for end-of-life evaluation. The `balance_duration` trigger type fires when the LYW balance remains below `threshold_sats` for a sustained period measured in blocks — preventing a brief dip from triggering premature sunset.
- **`archival_action`:** The pre-approved action executed automatically when the sunset condition is confirmed. The most common configuration is `public_domain_release`, which updates the content's license to CC0, releasing it into the public domain and ensuring it remains freely accessible after the economic lifecycle ends. Other valid actions include transferring governance to a public archive DAO or simply freezing the current state without license change.
