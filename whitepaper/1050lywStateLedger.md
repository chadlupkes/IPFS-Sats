# 10.5 LYW State Ledger 💰

The **LYW State Ledger** is the live accounting record embedded within the Lightning Yield Wallet (LYW) for a piece of content. It tracks the economic health of the content's persistence engine in real time — income generated, expenses paid, and current balance — and provides the publicly auditable financial record that DAO members, hosts, and any other participant can query at any time.

Its CID is referenced by the `mutable_state_cid` in the DAO Configuration Object (Section 10.3) and is updated by Key 3 after every financial event.

---

## The LYW as an Income-Generating Instrument

The LYW is not a passive wallet that drains toward zero as hosting costs are paid out. It is an active income-generating instrument. Sats deposited into the LYW are deployed on the Lightning Network through liquidity leasing, channel provisioning, and routing fee generation. This yield is the primary and foundational income stream — the mechanism that makes content persistence economically self-sustaining rather than dependent on continuous manual funding.

Content access payments — zaps from supporters, access fees from readers and listeners, and fork royalty inflows from derivative works — are additive income on top of the base liquidity yield. A well-configured LYW should be self-sustaining or growing. The sunset condition (Section 10.3) triggers only when liquidity yield has fallen below hosting cost for a sustained period, meaning the content's economic viability has genuinely ended — not because the account ran out of borrowed funds.

There is no debt in this system. The drawdown-to-creator-only mechanism (Section 5.2) ensures that when the LYW balance drops below the hosting cost threshold, host SatSwap payments are suspended and the balance drawdown shifts to creator-only mode. Expenses are never incurred beyond what the LYW can currently pay.

---

## JSON Schema: LYW State Ledger

```json
{
  "last_updated_block": 875440,        // Bitcoin block height of the last state change

  // 1. PRIMARY INCOME: Lightning Liquidity Yield
  "liquidity_yield": {
    "deployed_balance_sats": 500000,   // Sats currently deployed in Lightning channels
                                       // and liquidity leasing positions
    "leasing_income_sats": 12400,      // Yield earned from channel leasing in current cycle
    "routing_fee_income_sats": 340,    // Routing fees earned in current cycle
    "yield_rate_ppm": 1200,            // Current yield rate in parts-per-million (annualized)
    "cycle_start_block": 874432,       // Block height at the start of the current yield cycle
    "cycle_income_sats": 12740         // Total liquidity yield earned in current cycle
                                       // (leasing + routing fees)
  },

  // 2. SECONDARY INCOME: Content Access Payments
  "access_income": {
    "zap_income_sats": 8200,           // Sats received from supporter zaps in current cycle
    "access_fee_income_sats": 3100,    // Sats received from content access fees in current cycle
    "fork_royalty_income_sats": 950,   // Sats received from Child DAO upstream royalty payments
    "cycle_income_sats": 12250         // Total access income in current cycle
                                       // (zaps + access fees + fork royalties)
  },

  // 3. EXPENSES: Outbound Payments
  "expenses": {
    "host_payments_sats": 9800,        // Sats paid to hosts via SatSwap completions in current cycle
    "fork_royalty_outflow_sats": 1200, // Sats routed to Parent LYW addresses as upstream royalties
    "cycle_expenses_sats": 11000,      // Total expenses in current cycle
    "drawdown_mode": false             // True when LYW balance is below hosting cost threshold
                                       // and host payments are suspended (Section 5.2)
  },

  // 4. DISTRIBUTION: Member Yield Payouts
  "distribution": {
    "last_distribution_block": 871408, // Block height of the most recent distribution cycle
    "distributed_sats": 7200,          // Total sats distributed to DAO members in last cycle
    "compound_sats": 7200,             // Total sats reinvested into deployed balance in last cycle
    "distribution_history_cid": "<history-cid>" // CID of content-addressed ordered list
                                                // of all prior distribution events
  },

  // 5. CURRENT BALANCE
  "balance": {
    "available_sats": 48600,           // Current undeployed LYW balance available for
                                       // immediate expenses or redeployment
    "total_sats": 548600,              // Total LYW value: available + deployed balance
    "sunset_threshold_sats": 1000,     // Balance threshold below which sunset evaluation begins
                                       // (set in DAO Configuration Object Section 10.3)
    "cycles_at_threshold": 0           // Number of consecutive distribution cycles the total
                                       // balance has remained below sunset_threshold_sats
                                       // (sunset triggers when this reaches the configured duration)
  }
}
```

---

## Key Components and Operational Logic

### 1. Primary Income: Lightning Liquidity Yield

The LYW's sats are actively deployed in Lightning Network channels and liquidity leasing positions. The `deployed_balance_sats` field tracks how much capital is currently at work. `leasing_income_sats` and `routing_fee_income_sats` track the two streams of yield that deployment generates — fees paid by other Lightning participants to lease channel capacity, and routing fees earned when payments flow through the LYW's channels.

This yield is not dependent on the content being accessed or purchased. It is generated by the LYW's participation in Lightning Network liquidity provision and would continue even if the content received no direct payments in a given cycle. This is the foundational persistence mechanism.

### 2. Secondary Income: Content Access Payments

Zaps, access fees, and inbound fork royalties are tracked separately from liquidity yield because they are variable and directly tied to content activity. These flows are additive — they increase the LYW balance and therefore the deployed capital available for yield generation in future cycles, creating a compounding effect where popular content becomes more economically durable over time.

### 3. Expenses: Outbound Payments

Host SatSwap payments are the primary expense. They are paid per retrieval event as SatSwap exchanges complete — hosts earn sats for blocks served, not for storage committed in advance. `fork_royalty_outflow_sats` tracks upstream royalty payments routed to Parent LYW addresses, consistent with the fork provenance terms encoded in the Metadata Wrapper (Section 10.4).

The `drawdown_mode` flag is the key state indicator. When true, the LYW balance has dropped below the hosting cost threshold, host payments are suspended, and the remaining balance drawdown is reserved for creator distribution only. This is not a debt condition — it is a graceful degradation mode that ensures the creator continues to receive yield while the content's economic viability is evaluated.

### 4. Distribution: Member Yield Payouts

The distribution section tracks how the cycle's net income — total income minus expenses — is split between member payouts and reinvestment into the deployed balance. The split ratio is set in the DAO Configuration Object (`yield_config.yield_split`) and is governable by DAO vote. `distribution_history_cid` provides a permanent, queryable record of every prior distribution event, giving DAO members a complete auditable history of what was paid and when.

### 5. Current Balance

The balance section provides the at-a-glance economic health summary. `available_sats` is the undeployed balance immediately accessible for expenses. `total_sats` includes deployed capital — the true measure of the LYW's economic scale. `cycles_at_threshold` is the sunset evaluation counter — it increments each distribution cycle the total balance remains below `sunset_threshold_sats` and resets to zero if the balance recovers. When it reaches the duration configured in the DAO Configuration Object, the sunset process initiates.
