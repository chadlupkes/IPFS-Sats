# Developer Implementation Guide: LYW Operational Mechanics

This guide provides pseudocode for the primary functions executed by the Key 3 Smart Contract Environment to manage host payments, monitor LYW health, and execute economic failsafes.

---

## 1. Host Payment Model

Hosts are not paid from a DAO-managed budget on a monthly schedule. They earn per block delivered through SatSwap exchange completions. The HTLC mechanism provides atomicity — the payment settles simultaneously with block delivery when the preimage is revealed. No separate payment batch is required.

Key 3's role in host payments is:
- Monitoring `drawdown_mode` to determine whether the LYW can fund SatSwap exchanges
- Updating the LYW State Ledger after each exchange completion
- Transitioning `drawdown_mode` when the balance threshold is crossed

```javascript
/**
 * Called by Key 3 after each SatSwap exchange completion.
 * Updates the LYW State Ledger to record the host payment.
 * The HTLC has already settled atomically — this is bookkeeping only.
 *
 * @param {string} lyw_address
 * @param {Object} exchangeRecord - Completed SatSwap exchange details
 */
async function recordHostPayment(lyw_address, exchangeRecord) {
  const lyw = await getLYW(lyw_address);
  const ledger = lyw.state_ledger;

  // Record the payment in the current cycle's expenses
  ledger.expenses.host_payments_sats += exchangeRecord.amount_sats;
  ledger.expenses.cycle_expenses_sats += exchangeRecord.amount_sats;

  // Update available balance
  ledger.balance.available_sats -= exchangeRecord.amount_sats;
  ledger.balance.total_sats     -= exchangeRecord.amount_sats;

  // Check whether drawdown threshold has been crossed
  await evaluateDrawdownMode(lyw_address, ledger);

  ledger.last_updated_block = await getCurrentBlockHeight();
  await updateLYW(lyw);
}

/**
 * Evaluates whether drawdown_mode should activate or deactivate.
 * Called after any balance-changing event.
 *
 * drawdown_mode activates when available_sats can no longer cover
 * the estimated cost of the next host payment cycle.
 * drawdown_mode deactivates when available_sats recovers above that threshold.
 *
 * @param {string} lyw_address
 * @param {Object} ledger - Current LYW State Ledger
 */
async function evaluateDrawdownMode(lyw_address, ledger) {
  const dao = await getDAOByLYW(lyw_address);

  // Estimate next cycle host cost from recent expense history
  const estimatedCycleCost = ledger.expenses.host_payments_sats;

  const sufficientFunds = ledger.balance.available_sats >= estimatedCycleCost;
  const currentlyInDrawdown = ledger.expenses.drawdown_mode;

  if (!sufficientFunds && !currentlyInDrawdown) {
    // Activate drawdown mode — suspend host SatSwap payments
    ledger.expenses.drawdown_mode = true;
    await notifyCreator(dao, {
      type: "DRAWDOWN_MODE_ACTIVATED",
      available_sats: ledger.balance.available_sats,
      message: "LYW balance below hosting cost threshold. Host payments suspended. Creator yield distribution continues."
    });
  }

  if (sufficientFunds && currentlyInDrawdown) {
    // Deactivate drawdown mode — resume host SatSwap payments
    ledger.expenses.drawdown_mode = false;
    ledger.balance.cycles_at_threshold = 0; // Reset sunset counter
    await notifyCreator(dao, {
      type: "DRAWDOWN_MODE_DEACTIVATED",
      available_sats: ledger.balance.available_sats,
      message: "LYW balance recovered. Host payments resumed."
    });
  }
}
```

---

## 2. Health Monitoring

LYW health is assessed at each distribution cycle using three indicators: yield coverage, drawdown state, and sunset proximity. All three are derived from the LYW State Ledger — no external inputs required.

```javascript
/**
 * Assesses the LYW's economic health at a distribution cycle boundary.
 * Returns a structured health report for Key 3 action and creator notification.
 *
 * @param {string} lyw_address
 * @returns {Object} Health state and recommended action
 */
async function assessLYWHealth(lyw_address) {
  const lyw = await getLYW(lyw_address);
  const ledger = lyw.state_ledger;

  // Yield coverage: does monthly liquidity yield cover monthly host costs?
  const monthlyYield = ledger.liquidity_yield.deployed_balance_sats
    * (ledger.liquidity_yield.yield_rate_ppm / 1_000_000) / 12;
  const monthlyHostCost = ledger.expenses.host_payments_sats;
  const yieldCoversHostCosts = monthlyYield >= monthlyHostCost;

  // Sunset proximity: how close is the balance to the sunset threshold?
  const totalSats = ledger.balance.total_sats;
  const sunsetThreshold = ledger.balance.sunset_threshold_sats;
  const cyclesAtThreshold = ledger.balance.cycles_at_threshold;

  // Determine health state
  let state, message;

  if (!ledger.expenses.drawdown_mode && yieldCoversHostCosts) {
    state = "healthy";
    message = "LYW is self-sustaining. Yield covers hosting costs.";

  } else if (ledger.expenses.drawdown_mode && yieldCoversHostCosts) {
    state = "recovering";
    message = "Drawdown mode active but yield still covers costs. Balance should recover.";

  } else if (ledger.expenses.drawdown_mode && !yieldCoversHostCosts && cyclesAtThreshold < 3) {
    state = "warning";
    message = "Drawdown mode active. Yield below hosting cost threshold. Consider increasing LYW funding.";

  } else if (cyclesAtThreshold >= 3 && totalSats > sunsetThreshold) {
    state = "critical";
    message = "Multiple cycles below hosting threshold. Host availability degrading.";

  } else if (totalSats <= sunsetThreshold) {
    state = "sunset_evaluation";
    message = `Balance below sunset threshold (${sunsetThreshold} sats). Sunset evaluation active. cycles_at_threshold: ${cyclesAtThreshold}.`;

  } else {
    state = "unknown";
    message = "Unable to determine health state — check LYW State Ledger directly.";
  }

  return {
    state,
    message,
    drawdown_mode:           ledger.expenses.drawdown_mode,
    available_sats:          ledger.balance.available_sats,
    total_sats:              totalSats,
    yield_covers_host_costs: yieldCoversHostCosts,
    cycles_at_threshold:     cyclesAtThreshold,
    sunset_threshold_sats:   sunsetThreshold
  };
}

/**
 * Executes monitoring at each distribution cycle boundary.
 * Sends creator notifications scaled to health state severity.
 *
 * @param {string} lyw_address
 * @param {string} dao_cid
 */
async function monitorAndNotify(lyw_address, dao_cid) {
  const health = await assessLYWHealth(lyw_address);
  const dao = await getDAO(dao_cid);

  switch (health.state) {
    case "healthy":
      // No action required
      break;

    case "recovering":
      // Informational — no urgency
      await notifyCreator(dao, { type: "RECOVERING", ...health });
      break;

    case "warning":
      // Notify at distribution cycle cadence (~4 weeks)
      await notifyCreator(dao, { type: "WARNING", ...health });
      break;

    case "critical":
      // Notify at each distribution cycle — prompt for LYW top-up
      await notifyCreator(dao, { type: "CRITICAL", ...health });
      break;

    case "sunset_evaluation":
      // Notify at each distribution cycle
      // cycles_at_threshold is incrementing toward the duration_blocks threshold
      await notifyCreator(dao, { type: "SUNSET_EVALUATION", ...health });
      await evaluateSunsetCondition(lyw_address, dao_cid);
      break;
  }
}
```

---

## 3. Sunset Evaluation

When the LYW's total balance remains below `sunset_threshold_sats` for the number of blocks configured in `lifecycle.sunset_condition.duration_blocks`, the sunset condition is confirmed and the pre-approved archival action executes automatically.

This is not a failure mode — it is a graceful lifecycle completion. Content that has reached economic exhaustion is transitioned to public availability rather than simply disappearing.

```javascript
/**
 * Evaluates whether the sunset condition has been met.
 * Called at each distribution cycle when in sunset_evaluation state.
 * Executes the pre-approved archival action when duration_blocks is reached.
 *
 * @param {string} lyw_address
 * @param {string} dao_cid
 */
async function evaluateSunsetCondition(lyw_address, dao_cid) {
  const lyw = await getLYW(lyw_address);
  const ledger = lyw.state_ledger;
  const dao = await getDAO(dao_cid);

  const sunsetConfig = dao.lifecycle.sunset_condition;
  const archivalAction = dao.lifecycle.archival_action;

  // Increment cycles_at_threshold counter
  ledger.balance.cycles_at_threshold += 1;

  // Convert cycles to approximate block count
  // (distribution_period_blocks per cycle)
  const blocksAtThreshold =
    ledger.balance.cycles_at_threshold * dao.smart_contract.yield_config.distribution_period_blocks;

  if (blocksAtThreshold >= sunsetConfig.duration_blocks) {
    // Sunset condition confirmed — execute pre-approved archival action
    await executeSunsetAction(dao_cid, archivalAction);
  } else {
    // Sunset not yet triggered — record updated counter and continue
    await updateLYW(lyw);
  }
}

/**
 * Executes the pre-approved archival action on sunset confirmation.
 * The most common action is public_domain_release (CC0 license).
 *
 * @param {string} dao_cid
 * @param {Object} archivalAction - From dao.lifecycle.archival_action
 */
async function executeSunsetAction(dao_cid, archivalAction) {
  const dao = await getDAO(dao_cid);

  switch (archivalAction.action_type) {
    case "public_domain_release":
      // Update content license to CC0
      // Requires Key 3 execution (pre-approved — no Key 2 vote needed at this step)
      await updateContentLicense(dao.content_cid, archivalAction.new_license_cid);
      await notifyCreator(dao, {
        type: "SUNSET_CONFIRMED",
        message: "Content license updated to CC0. Content is now in the public domain."
      });
      break;

    case "archive_dao_transfer":
      // Transfer governance to a public archive DAO
      await transferDAOGovernance(dao_cid, archivalAction.archive_dao_cid);
      await notifyCreator(dao, {
        type: "SUNSET_CONFIRMED",
        message: "Governance transferred to archive DAO."
      });
      break;

    case "freeze":
      // Freeze current state — no license change, no governance transfer
      await freezeDAO(dao_cid);
      await notifyCreator(dao, {
        type: "SUNSET_CONFIRMED",
        message: "DAO frozen. Content state preserved at last known configuration."
      });
      break;
  }
}
```

---

## 4. LYW Top-Up (Funding Recovery)

When a creator funds a depleted or degraded LYW, the recovery sequence reactivates host payments and resets the sunset counter.

```javascript
/**
 * Processes a LYW top-up from the creator.
 * Updates the LYW State Ledger and re-evaluates drawdown_mode.
 *
 * @param {string} lyw_address
 * @param {number} amount_sats - Sats received via Lightning payment
 */
async function topUpLYW(lyw_address, amount_sats) {
  const lyw = await getLYW(lyw_address);
  const ledger = lyw.state_ledger;

  // Update balances
  ledger.balance.available_sats += amount_sats;
  ledger.balance.total_sats     += amount_sats;
  ledger.liquidity_yield.deployed_balance_sats += amount_sats;

  // Re-evaluate drawdown state — may deactivate if balance now sufficient
  await evaluateDrawdownMode(lyw_address, ledger);

  // Reset sunset counter if balance is above sunset threshold
  if (ledger.balance.total_sats > ledger.balance.sunset_threshold_sats) {
    ledger.balance.cycles_at_threshold = 0;
  }

  ledger.last_updated_block = await getCurrentBlockHeight();
  await updateLYW(lyw);

  const dao = await getDAOByLYW(lyw_address);
  await notifyCreator(dao, {
    type: "LYW_TOPPED_UP",
    amount_sats,
    new_balance: ledger.balance.available_sats,
    drawdown_mode: ledger.expenses.drawdown_mode
  });
}
```

---

## 5. The Closed-Loop Cycle: Summary

The LYW's self-sustaining model operates through six steps:

1. **Initial Funding:** The creator funds the LYW. Capital is deployed into Lightning channels to begin generating liquidity yield.

2. **Yield Generation:** The deployed balance earns yield through channel leasing, routing fees, and other Lightning liquidity activity. Yield accumulates in `liquidity_yield.cycle_income_sats`.

3. **Automatic Distribution:** At each `distribution_period_blocks` interval, Key 3 distributes cycle income to DAO members per the `distribution_split` configuration. Compound fraction stays in the LYW and is redeployed, growing the yield principal.

4. **Host SatSwap Payments:** When `drawdown_mode` is false, Key 3 funds host SatSwap exchange completions from `available_sats`. Hosts earn per block delivered — atomic with delivery, no verification step required.

5. **Monitoring and Alerts:** Key 3 evaluates health at each distribution cycle. Notifications scale to severity: drawdown activation, critical balance, sunset evaluation. The creator receives advance warning well before the sunset threshold is reached.

6. **Graceful Lifecycle Completion:** If the balance remains below `sunset_threshold_sats` for the configured `duration_blocks`, the pre-approved archival action executes — typically a CC0 public domain release. Content degrades to publicly accessible rather than simply disappearing.

**There is no debt, no grace period, and no external arbitrator.** Economic state is fully encoded in the LYW State Ledger and DAO Configuration Object. Key 3 reads state and executes pre-approved actions — nothing more.
