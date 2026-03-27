# Initial State Example: Newly Published Content with 1,000,000 Sats LYW Funding

This example shows the JSON state of a newly published piece of content with a 1,000,000 sat initial LYW funding. All values reflect the moment after Step 5 (Bitcoin confirmation) and Step 6 (Anchor Record publication) of the initialization sequence.

---

## LYW State Ledger (Section 10.5)

```json
{
  "last_updated_block": 875440,

  "liquidity_yield": {
    "deployed_balance_sats": 1000000,  // Full funding amount deployed into Lightning channels
    "leasing_income_sats": 0,          // No yield earned yet — first cycle not complete
    "routing_fee_income_sats": 0,
    "yield_rate_ppm": 1200,            // Expected ~10% APY at current network rates (1200 ppm annualized)
    "cycle_start_block": 875440,
    "cycle_income_sats": 0
  },

  "access_income": {
    "zap_income_sats": 0,              // No access payments received yet
    "access_fee_income_sats": 0,
    "fork_royalty_income_sats": 0,
    "cycle_income_sats": 0
  },

  "expenses": {
    "host_payments_sats": 0,           // No host AtomicSats exchanges completed yet
    "fork_royalty_outflow_sats": 0,
    "cycle_expenses_sats": 0,
    "drawdown_mode": true              // True on initialization — host payments suspended
                                       // until available_sats covers hosting cost threshold
  },

  "distribution": {
    "last_distribution_block": null,   // No distribution cycles completed yet
    "distributed_sats": 0,
    "compound_sats": 0,
    "distribution_history_cid": null
  },

  "balance": {
    "available_sats": 1000000,         // Full funding amount available for expenses and redeployment
    "total_sats": 1000000,             // available + deployed (same on day one)
    "sunset_threshold_sats": 1000,     // Below this for sustained cycles → sunset evaluation
    "cycles_at_threshold": 0           // Resets to 0 when balance recovers
  }
}
```

---

## DAO Configuration Object — Smart Contract Section (Section 10.3)

```json
{
  "smart_contract": {
    "yield_config": {
      "distribution_split": {
        "creator": 0.50,   // 50% of distributable income → creator's Lightning address
        "compound": 0.50   // 50% reinvested into LYW deployed balance
      },
      "distribution_period_blocks": 4032   // Distribution cycle ~every 4 weeks
    }
  }
}
```

**Note on host payments:** Hosts are not paid from a DAO-managed budget. They earn per block delivered through AtomicSats exchange completions. The LYW's `available_sats` funds those payments when they occur. There is no `monthly_budget` field and no per-host allocation — the Host Discovery Layer's pricing market determines what hosts will accept per exchange.

---

## Financial Projections

These are planning estimates, not protocol state. Actual yield varies with Lightning network conditions and channel deployment efficiency.

```
Deployed balance:           1,000,000 sats
Conservative yield APY:     10%
Expected monthly yield:     ~8,333 sats  (1,000,000 × 0.10 / 12)

Estimated monthly host cost (5 hosts, 10MB content):
  10MB × 5 hosts × 100 sats/GB/month = ~5 sats/month
  (negligible at this content size — yield far exceeds hosting cost)

Net monthly (yield − host cost): ~8,328 sats
Distribution to creator (50%):  ~4,164 sats
Compound reinvestment (50%):    ~4,164 sats

Runway: Indefinite — yield exceeds costs at current assumptions
```

---

## State Narrative

At initialization, the LYW's `drawdown_mode` is `true`. This is the correct and expected initial state — no third-party hosts have received payment yet, and the content's hosting is provided by the creator's own node. As the LYW's deployed capital generates its first yield cycle (~4 weeks), `available_sats` grows. Once yield income demonstrates it covers the hosting cost threshold, `drawdown_mode` automatically deactivates and host AtomicSats payments begin.

The 1,000,000 sat funding is well above the minimum required for a small content file — the LYW will reach self-sustaining operations well before the first distribution cycle completes.

For the minimum funding calculation by content size, see the bootstrapping guide (Section 5.2.1).
