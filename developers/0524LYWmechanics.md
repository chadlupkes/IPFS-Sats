## 5.2.4 Developer Specifications: Operational Functions 🛠️

This section provides the clean pseudocode for the primary functions executed by the **$\text{Key 3}$ Smart Contract Environment** to manage host compensation, monitor wallet health, and execute the economic failsafes.

### 1\. Host Compensation and Proof-of-Storage Payment

This function executes the core $\text{sats}$-for-data exchange, verifying storage and paying hosts from the compound pool.

```javascript
/**
 * Executes a payment batch for verified hosts storing the content.
 * Triggered periodically (e.g., monthly).
 * * @param {object} dao - The DAO metadata (contains content_cid, budget, split).
 * @param {object} lyw - The current Lightning Yield Wallet state.
 * @returns {object} Payment record (including verification results).
 */
async function payHostsForStorage(dao, lyw) {
    const { monthly_budget, performance_weighted } = dao.smart_contract.host_payments;

    // 1. FUND CHECK & ALERT
    if (lyw.compound_pool < monthly_budget) {
        await triggerLowBalanceAlert(dao.cid, monthly_budget - lyw.compound_pool);
        return { status: "insufficient_funds" };
    }

    // 2. VERIFICATION LOOP: Proof-of-Storage Challenge
    const hosts = await getHostsForContent(dao.content_cid);
    const verifiedHosts = [];
    let totalPaid = 0;

    for (const host of hosts) {
        const challenge = createChallenge(dao.content_cid);
        const proof = await requestStorageProof(host.did, challenge);

        if (await verifyMerkleProof(proof, dao.content_cid, challenge)) {
            verifiedHosts.push(prepareHostVerificationRecord(host, proof, challenge));
        } else {
            await removeHostFromRegistry(host.did, dao.content_cid);
        }
    }

    // 3. PAYMENT CALCULATION (Equal or Performance-Weighted)
    const paymentDistribution = calculatePaymentDistribution(
        verifiedHosts, 
        monthly_budget, 
        performance_weighted
    );

    // 4. EXECUTE ATOMIC LIGHTNING PAYMENTS
    const paymentResults = await executeLightningBatch(paymentDistribution);
    
    // 5. UPDATE STATE
    totalPaid = paymentResults.filter(r => r.status === "paid").reduce((sum, r) => sum + r.amount, 0);
    lyw.compound_pool -= totalPaid;
    await updateLYW(lyw);
    await recordPaymentBatch(dao, paymentResults, totalPaid);

    return paymentResults;
}
```

-----

### 2\. Viability and Health Monitoring

This set of functions determines the financial stability of the $\text{LYW}$ and triggers alerts based on the remaining Persistence Runway.

```javascript
/**
 * Assesses the LYW's financial health and determines the remaining runway.
 * * @param {object} lyw - The current Lightning Yield Wallet state.
 * @param {object} dao - The DAO metadata (costs, expected yield).
 * @returns {object} The current health state and runway.
 */
function assessLYWHealth(lyw, dao) {
    // Note: Assuming yieldAPY is stable for this calculation
    const yieldAPY = dao.yield_sources[0].expected_apy;
    const monthlyCosts = dao.smart_contract.host_payments.monthly_budget;

    // Calculate net flow
    const monthlyYield = (lyw.balance * yieldAPY) / 12;
    const monthlyNet = monthlyYield - monthlyCosts;

    // Determine runway (Infinity if sustainable)
    const runway = monthlyNet >= 0
        ? Infinity
        : lyw.compound_pool / Math.abs(monthlyNet);

    if (runway === Infinity) return { state: "healthy", runway: "indefinite" };
    if (runway > 12) return { state: "warning", runway_months: runway };
    if (runway > 3) return { state: "critical", runway_months: runway };
    if (runway > 0) return { state: "emergency", runway_months: runway };
    
    return { state: "depleted", runway_months: 0 };
}

/**
 * Executes monitoring and triggers necessary notifications/actions.
 * Triggered continuously (e.g., daily).
 */
async function monitorAndNotify() {
    const health = assessLYWHealth(await getLYW(), await getDAO());

    switch(health.state) {
        case "warning":
            // Notify creator every 30 days
            if (isTimeForAlert(lyw.last_warning, 30)) await notifyCreators(dao, "LOW BALANCE WARNING");
            break;
            
        case "critical":
            // Notify creator every 7 days; prompt for action
            if (isTimeForAlert(lyw.last_warning, 7)) await notifyCreators(dao, "CRITICAL BALANCE ALERT");
            break;
            
        case "emergency":
            // Notify creator daily
            await notifyCreators(dao, "EMERGENCY: FUNDS NEARLY GONE");
            await handleEmergencyPinning(dao); // Execute self-pinning failsafe
            break;
            
        case "depleted":
            await handleDepletion(lyw, dao); // Initiate 30-day grace period
            break;
    }
}
```

-----

### 3\. Failsafe and Recovery Mechanisms

These functions manage the automated actions taken when the balance is critical or depleted.

```javascript
/**
 * Automatically pins content to the creator's IPFS node if funds are low and the creator is online.
 * * @param {object} dao - The DAO metadata.
 */
async function handleEmergencyPinning(dao) {
    const creator = dao.members[0];
    
    // Check if creator node is running (Requires service integration)
    const creatorNode = await checkCreatorNodeOnline(creator.did);
    
    if (creatorNode.online) {
        // Use Key 2 signature to authorize pinning on the creator's behalf
        await creatorNode.pin(dao.content_cid);
        
        await notifyCreators(dao, "Emergency failsafe: Content pinned to your node.");
    }
}

/**
 * Initiates the 30-day grace period upon LYW depletion.
 */
async function handleDepletion(lyw, dao) {
    if (!lyw.grace_period_started) {
        // Set the 30-day expiration time
        lyw.grace_period_started = Date.now();
        lyw.grace_period_expires = Date.now() + (30 * 24 * 60 * 60 * 1000);
        
        // Notify all stakeholders (creators and hosts)
        await notifyCreators(dao, "LYW Depleted - 30 Day Grace Period Active.");
        await notifyHosts(dao.content_cid, "Grace period started. May unpin after 30 days.");
        
    } else if (Date.now() > lyw.grace_period_expires) {
        // If 30 days passed without replenishment, release hosts
        dao.smart_contract.hosts_released = true;
        await notifyCreators(dao, "Grace Period Expired - Hosts Released.");
    }

    await updateLYW(lyw);
    await updateDAO(dao);
}

/**
 * Handles the replenishment of the LYW by the creator.
 * @param {number} amount - Sats deposited.
 */
async function topUpLYW(lyw, dao, amount) {
    // 1. Process BTC/Lightning deposit and update balances
    lyw.balance += amount;
    lyw.compound_pool += amount;

    // 2. Clear Failsafe flags
    lyw.grace_period_started = null;
    dao.smart_contract.hosts_released = false;

    // 3. Notify network of restored persistence
    await notifyCreators(dao, "✅ LYW Replenished - Persistence Restored.");
    
    // The next execution of payHostsForStorage will resume payments.
    await updateLYW(lyw);
    await updateDAO(dao);
}
```

## The Lightning Yield Wallet's Self-Sustaining Model: Summary of the Closed-Loop Cycle ♻️

The **Lightning Yield Wallet ($\text{LYW}$)** transforms content persistence into a passive, self-funding investment by creating a closed-loop economic system. This model guarantees long-term content availability by linking financial yield directly to verifiable hosting incentives, replacing the traditional "pay monthly or lose data" model with a "deposit once, earn forever" mechanism.

The entire self-sustaining cycle flows through these seven steps:

1.  **Initial Deposit:** The creator funds the $\text{LYW}$ by depositing $\text{sats}$, which are used to open a **Lightning Network channel** for the content's lifespan.
2.  **Yield Generation:** The principal of the $\text{LYW}$ is deployed into liquidity markets (e.g., liquidity leasing and $\text{L3}$ DAOs) to **generate continuous Bitcoin yield**.
3.  **Automatic Distribution:** The earned yield is automatically split according to the DAO's configuration (**Creator/Compound Split**) to compensate the creator and fuel growth.
4.  **Host Payments:** The **compound pool** funds ongoing, atomic micropayments ($\text{Proof-of-Storage}$) to hosts, ensuring the content's persistent storage and high availability.
5.  **Surplus Compounding:** Any surplus remaining after host payments and creator payouts is **compounded back** into the $\text{LYW}$ balance, increasing the principal and generating greater future yield.
6.  **Monitoring and Alerting:** A transparent **Health Monitoring system (5.2.4)** continuously assesses the wallet's financial runway, providing advance warnings to the creator before funds become critical.
7.  **Failsafes:** Automated mechanisms, including the **30-day grace period** and **Creator Node Self-Pinning**, prevent data loss even if the funding eventually depletes, ensuring content degrades gracefully back to the original source.
