## 10.3 DAO Configuration Object ⚙️

The **$\text{DAO}$ Configuration Object** (pointed to by the Core Content Object's dao_cid) defines the initial and persistent governance rules for the asset. This structure is **immutable once published**, ensuring that any change to the asset's operational parameters requires a formal vote according to the fixed rules defined within this object.

### $\text{JSON}$ Schema: $\text{DAO}$ Configuration Object

```json
{
  "protocol_version": "2.0",
  "asset_cid": "bafy... (CID of the Core Content Object this DAO governs)",  // Content link

  // 1. MEMBER STRUCTURE (Defining Voting Power)
  "membership_model": {
    "type": "fractional_sats",
    "stake_definition": "CID of the fractionalization smart contract/state tree"
  },
  "initial_members": [
    {
      "did": "did:key:z6Mk...",
      "initial_stake": 1000000, // Power is granted via stake, measured in atomic units
      "role": "creator"
    }
  ],

  // 2. VOTING PARAMETERS (Operational Security)
  "voting_rules": {
    "proposal_threshold": 0.01,         // Minimum stake required to submit a proposal (e.g., 1%)
    "approval_quorum": 0.50,            // Minimum stake participation required for a binding vote (e.g., 50%)
    "approval_threshold": 0.66,         // Minimum percentage of participating votes required to pass (e.g., 66% Supermajority)
    "voting_period_blocks": 4032        // Duration of voting, measured in Bitcoin blocks
  },

  // 3. SMART CONTRACT RULES (The Governance Logic)
  "governance_logic": {
    "implementation_type": "wasm",      // WebAssembly, EVM, etc.
    "contract_cid": "QmContractCode...",// Immutable CID of the smart contract code
    "mutable_state_cid": "QmInitialState...", // CID pointing to the mutable operational state (e.g., current royalty splits)
    "allowed_actions": [
      "update_royalty_split",
      "change_license_uri",
      "content_flagging"
    ]
  },

  // 4. LIFECYCLE AND SUNSET PARAMETERS (Persistence and End-of-Life)
  "lifecycle": {
    "persistence_funding_cid": "QmCurrentLYWState...", // Link to the current balance of the Locked Yield Wallet (LYW)
    "sunset_condition": {
      "trigger_type": "balance_duration",
      "threshold_sats": 1000,
      "duration_blocks": 52596
    },
    "archival_action": {
      "action_type": "public_domain_release",
      "new_license_cid": "QmCC0License..."
    }
  }
}
```

-----

### Member Structure

The $\text{DAO}$'s structure defines who holds governing power and how that power is measured, directly linking governance to economic stake.

  * **`membership_model`:** Defines the stake mechanism, typically **fractionalized $\text{\$SATS}$**, where ownership is represented by a fractional share of the asset's associated yield.
  * **`initial_members`:** A mandatory array defining the genesis state of the $\text{DAO}$. Power is granted via the **`initial_stake`** field, measured in atomic units of the fractionalized asset.

### Voting Parameters

These parameters enforce operational security and participation requirements. The **`voting_period_blocks`** is measured in Bitcoin blocks, ensuring time is objective and immutable.

  * **`proposal_threshold`:** Minimum stake required to submit a proposal.
  * **`approval_quorum`:** Minimum percentage of total stake that must **participate** in the vote for the result to be binding.
  * **`approval_threshold`:** Percentage of participating votes that must be **in favor** for the proposal to pass and trigger an action.

### Smart Contract Rules

These rules define the actual logic and constraints of the governance system, ensuring that voting only results in pre-defined, safe actions.

  * **`contract_cid`:** The **immutable $\text{CID}$** of the smart contract code (e.g., WebAssembly bytecode) that contains the logic for all allowed actions.
  * **`mutable_state_cid`:** The $\text{CID}$ pointing to a separate, mutable data structure that holds the current operational state (e.g., the active royalty split percentages). This is the only state that changes upon a successful vote.
  * **`allowed_actions`:** An explicit array listing the functions or endpoints within the contract_cid that the $\text{DAO}$ is permitted to trigger via a successful vote.

### Lifecycle and Sunset Parameters

This section establishes the terms for the asset's economic viability and its final disposition, ensuring a graceful content end-of-life.

  * **`persistence_funding_cid`:** A required link to the data structure that tracks the state of the **Locked Yield Wallet ($\text{LYW}$)**. This allows any node to verify the current economic health of the asset (i.e., its ability to continuously pay $\text{IPFS}$ hosts).
  * **`sunset_condition`:** Defines the precise metric and threshold to initiate the $\text{DAO}$'s final stage. For example, if the $\text{LYW}$ balance drops below **`threshold_sats`** and stays there for **`duration_blocks`**, the process is triggered.
  * **`archival_action`:** Specifies the pre-approved, immutable action that is executed once the sunset condition is confirmed, ensuring the asset is handled according to the original governance design. A common action is **`public_domain_release`**, which automatically updates the linked license to $\text{CC0}$.
