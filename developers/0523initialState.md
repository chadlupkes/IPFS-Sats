### 5.2.3 Initial State Example

A look at the JSON state of a newly launched $\text{Content DAO}$ with a $1,000,000 \text{ sats}$ deposit.

```json
{
  "lyw": {
    "wallet_address": "lnbc1...",
    "balance": 1000000,  // 1M sats deposited
    "compound_pool": 0,  // Nothing compounded yet
    "distribution_history": [],
    "yield_sources": [
      {
        "type": "liquidity_lease",
        "platform": "Lightning Pool",
        "amount": 1000000,
        "expected_apy": 0.12,  // 12%
        "expected_monthly": 10000,
        "lease_started": 1735094400,
        "lease_expires": 1737686400
      }
    ]
  },
  "smart_contract": {
    "yield_split": {
      "creator": 50, // 50% to the creator (Key 2)
      "compound": 50 // 50% reinvested into the principal
    },
    "host_payments": {
      "monthly_budget": 5000,
      "hosts_count": 5,
      "payment_per_host": 1000
    }
  },
  "financial_projection": {
    "monthly_yield": 10000,
    "monthly_costs": 5000,
    "net_monthly": 5000,
    "runway": "indefinite (yield > costs)"
  }
}
```
