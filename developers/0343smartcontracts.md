# Developer Implementation Guide: Smart Contract Execution

This guide provides JavaScript pseudocode for the Per-Content DAO's governance mechanics: proposal creation, voting, automated execution, yield distribution, and host payment. All functions are executed by Key 3 (the Execution Key) under authority granted by Key 2 (the Human Authority Key) and within constraints set by Key 1 (the Content Binding Key).

**Key 3 executes; it does not decide.** Every automated action in this guide is either triggered by a successful Key 2 governance vote or by a threshold condition defined in the DAO Configuration Object. Key 3 has no discretionary authority.

---

## 1. Proposal Creation

A proposal specifies a desired change to the DAO's state. It is published as a content-addressed object — any change to the proposal produces a different CID, making the proposal record tamper-evident.

### Proposal Object Schema

```json
{
  "proposal_id": "prop_20260101_001",
  "type": "UPDATE_INCOME_DISTRIBUTION",
  "created_by": "did:key:alice...",
  "created_at": 1735094400,
  "expires_at": 1735699200,

  "title": "Adjust income distribution to fund marketing campaign",
  "description": "Reduce compound from 50% to 30% for next 6 months...",

  "current_state": {
    "distribution_split": {
      "creator": 0.50,
      "compound": 0.50
    }
  },

  "proposed_state": {
    "distribution_split": {
      "creator": 0.50,
      "marketing_fund": 0.20,
      "compound": 0.30
    },
    "revert_at_block": 880000
  },

  "voting": {
    "quorum": 2,
    "threshold": 0.80,
    "votes": { "for": [], "against": [], "abstain": [] },
    "current_weight_for": 0.0,
    "current_weight_against": 0.0
  },

  "execution": {
    "auto_execute": true,
    "timelock_seconds": 86400,
    "status": "active"
  }
}
```

**Note on voting weights:** Voting weight in a Per-Content DAO derives from `income_share` — the fraction of the income stream allocated to each member in the DAO Configuration Object. Income shares sum to 1.0. Threshold is expressed as a fraction of total income share (e.g., 0.80 = 80% of total weight).

### Proposal Creation Function

```javascript
/**
 * Creates a governance proposal and publishes it to the network.
 * Only DAO members may create proposals.
 * @param {Object} dao - Current DAO Configuration Object.
 * @param {Object} proposal - Proposal parameters.
 * @returns {string} proposalCID
 */
async function createProposal(dao, proposal) {
  // 1. Validate proposer is a DAO member
  const member = dao.membership.initial_members.find(
    m => m.did === proposal.created_by
  );
  if (!member) throw new Error("Only DAO members can create proposals");

  // 2. Generate proposal ID and set expiration
  proposal.proposal_id = generateProposalId(dao.content_cid, proposal.created_at);
  proposal.expires_at = proposal.created_at + dao.voting.voting_period_seconds;

  // 3. Initialize voting state from DAO Configuration Object parameters
  proposal.voting = {
    quorum:                  dao.voting.quorum,
    threshold:               dao.voting.threshold,
    votes:                   { for: [], against: [], abstain: [] },
    current_weight_for:      0.0,
    current_weight_against:  0.0
  };

  // 4. Publish proposal as content-addressed object
  // IPFS is the reference implementation
  const proposalCID = await ipfs.dag.put(proposal);

  // 5. Notify DAO members
  await notifyMembers(dao, {
    type: "NEW_PROPOSAL",
    proposal_cid: proposalCID,
    title: proposal.title
  });

  return proposalCID;
}
```

---

## 2. Voting

Votes are authenticated by cryptographic signature over the proposal ID and vote value. Voting weight derives from the voter's `income_share` in the DAO Configuration Object.

### Cast Vote Function

```javascript
/**
 * Records an authenticated vote on a proposal.
 * @param {string} proposalCID
 * @param {string} voterDID
 * @param {string} vote - "FOR" | "AGAINST" | "ABSTAIN"
 * @param {string} signature - Signed over { proposal_id, vote }
 * @returns {string} updatedProposalCID
 */
async function castVote(proposalCID, voterDID, vote, signature) {
  const proposal = await ipfs.dag.get(proposalCID);
  const dao = await getDAO(proposal.dao_cid);

  // Find voter in DAO membership
  const voter = dao.membership.initial_members.find(m => m.did === voterDID);

  // Validate: membership, timing, signature, no duplicate vote
  if (!voter) throw new Error("Voter is not a DAO member");
  if (Date.now() / 1000 > proposal.expires_at) throw new Error("Voting period expired");
  if (!verifySignature(voterDID, signature, {
    proposal_id: proposal.proposal_id,
    vote: vote
  })) throw new Error("Invalid signature");

  const allVotes = [
    ...proposal.voting.votes.for,
    ...proposal.voting.votes.against,
    ...proposal.voting.votes.abstain
  ];
  if (allVotes.includes(voterDID)) throw new Error("Already voted");

  // Record vote — weight derives from income_share (0.0 to 1.0)
  if (vote === "FOR") {
    proposal.voting.votes.for.push(voterDID);
    proposal.voting.current_weight_for += voter.income_share;
  } else if (vote === "AGAINST") {
    proposal.voting.votes.against.push(voterDID);
    proposal.voting.current_weight_against += voter.income_share;
  } else if (vote === "ABSTAIN") {
    proposal.voting.votes.abstain.push(voterDID);
  }

  // Publish updated proposal
  const updatedProposalCID = await ipfs.dag.put(proposal);

  // Check whether threshold has been reached
  await checkProposalStatus(updatedProposalCID, dao);

  return updatedProposalCID;
}
```

### Threshold Check Function

```javascript
/**
 * Checks whether a proposal has reached approval threshold or expired.
 * Income shares sum to 1.0, so threshold is a direct fraction comparison.
 * @param {string} proposalCID
 * @param {Object} dao
 */
async function checkProposalStatus(proposalCID, dao) {
  const proposal = await ipfs.dag.get(proposalCID);

  // Check quorum: minimum number of distinct votes cast
  const totalVotesCast = proposal.voting.votes.for.length
    + proposal.voting.votes.against.length
    + proposal.voting.votes.abstain.length;

  if (totalVotesCast < proposal.voting.quorum) return; // Quorum not yet met

  // Check threshold: FOR weight as fraction of total income share (1.0)
  // income_shares sum to 1.0, so current_weight_for IS the approval fraction
  if (proposal.voting.current_weight_for >= proposal.voting.threshold) {
    proposal.execution.status = "approved";
    await ipfs.dag.put(proposal);
    await scheduleExecution(proposal);
    return;
  }

  // Check expiry
  if (Date.now() / 1000 > proposal.expires_at) {
    proposal.execution.status = "rejected";
    await ipfs.dag.put(proposal);
  }
}
```

---

## 3. Automated Execution

Key 3 executes approved proposals after the timelock period. Execution is type-specific.

### Execute Income Distribution Update

```javascript
/**
 * Updates the DAO's income distribution split after governance approval.
 * Optionally schedules an auto-revert at a specified Bitcoin block height.
 * @param {Object} proposal - Approved proposal object.
 * @returns {string} updatedDAOcid
 */
async function executeIncomeSplitUpdate(proposal) {
  const dao = await getDAO(proposal.dao_cid);

  // Apply proposed distribution split
  dao.smart_contract.yield_config.distribution_split =
    proposal.proposed_state.distribution_split;

  // Schedule auto-revert if temporary change
  if (proposal.proposed_state.revert_at_block) {
    await scheduleBlockHeightJob({
      block_height: proposal.proposed_state.revert_at_block,
      action: "REVERT_DISTRIBUTION_SPLIT",
      previous_split: proposal.current_state.distribution_split
    });
  }

  // Record change in governance history
  dao.governance_history.push({
    block_height: await getCurrentBlockHeight(),
    proposal_id: proposal.proposal_id,
    action: "INCOME_SPLIT_UPDATED"
  });

  // Publish updated DAO Configuration Object
  const updatedDAOcid = await ipfs.dag.put(dao);

  // Update Metadata Wrapper to point to new DAO Configuration Object CID
  // (requires a new Metadata Bundle CID — see Section 6.3)
  await updateMetadataBundleDAORef(dao.content_cid, updatedDAOcid);

  return updatedDAOcid;
}
```

### Execute License Grant

```javascript
/**
 * Issues a license certificate, conditioned on Lightning payment if priced.
 * Payment atomicity is enforced by the Lightning HTLC mechanism.
 * @param {Object} proposal - Approved proposal object.
 * @returns {string} certificateCID
 */
async function executeLicenseGrant(proposal) {
  const license = proposal.proposed_state.license;

  const certificate = {
    content_cid:    proposal.dao_cid,
    licensee_did:   license.licensee_did,
    license_type:   license.type,
    territory:      license.territory,
    duration_blocks: license.duration_blocks,
    payment_amount: license.payment_amount,
    status:         "pending"
  };

  const certificateCID = await ipfs.dag.put(certificate);

  if (license.payment_amount > 0) {
    // Generate Lightning invoice — payment atomically activates the license
    const invoice = await lightning.createInvoice({
      amount_sats: license.payment_amount,
      metadata: { certificate_cid: certificateCID }
    });

    certificate.payment_invoice = invoice;

    // Monitor for HTLC settlement
    await monitorInvoice(invoice, async (settled) => {
      if (settled) {
        certificate.status = "active";
        certificate.payment_hash = settled.payment_hash;
        await ipfs.dag.put(certificate);
        await notifyLicensee(license.licensee_did, certificateCID);
      }
    });
  } else {
    // Free license: activate immediately
    certificate.status = "active";
    await ipfs.dag.put(certificate);
    await notifyLicensee(license.licensee_did, certificateCID);
  }

  // Record in DAO governance history
  const dao = await getDAO(proposal.dao_cid);
  dao.licenses_granted.push(certificateCID);
  await ipfs.dag.put(dao);

  return certificateCID;
}
```

---

## 4. Yield Distribution Cycle

Key 3 distributes income to DAO members on the schedule defined by `distribution_period_blocks` in the DAO Configuration Object. Distribution operates on the LYW's total cycle income — Lightning liquidity yield plus content access payments — minus expenses already paid.

```javascript
/**
 * Distributes yield to DAO members based on the distribution_split configuration.
 * Called by Key 3 at each distribution_period_blocks interval.
 * @param {string} dao_cid
 * @returns {string} distributionReportCID
 */
async function distributeYield(dao_cid) {
  const dao = await getDAO(dao_cid);

  // Retrieve current LYW State Ledger
  const lyw = await getLYW(dao.protocol_metadata.lyw_address);
  const ledger = lyw.state_ledger;

  // Total cycle income: liquidity yield + access income
  const totalCycleIncome =
    ledger.liquidity_yield.cycle_income_sats +
    ledger.access_income.cycle_income_sats;

  // Total cycle expenses (host SatSwap payments + outbound fork royalties)
  const totalCycleExpenses = ledger.expenses.cycle_expenses_sats;

  // Distributable income: what remains after expenses
  const distributableSats = Math.max(0, totalCycleIncome - totalCycleExpenses);

  const split = dao.smart_contract.yield_config.distribution_split;
  const distributions = {};
  let totalDistributed = 0;

  for (const [recipient, fraction] of Object.entries(split)) {
    if (recipient === "compound") continue; // Compound stays in LYW — handled below

    const amountSats = Math.floor(distributableSats * fraction);

    // Find member Lightning address
    const member = dao.membership.initial_members.find(
      m => m.did === recipient || m.role === recipient
    );

    if (member?.lightning_address) {
      try {
        const payment = await lightning.send({
          destination: member.lightning_address,
          amount_sats: amountSats,
          memo: `Yield distribution from ${dao.content_cid}`
        });
        distributions[recipient] = {
          amount_sats: amountSats,
          status: "paid",
          payment_hash: payment.payment_hash
        };
        totalDistributed += amountSats;
      } catch (error) {
        // Payment failed — schedule retry
        distributions[recipient] = {
          amount_sats: amountSats,
          status: "pending",
          error: error.message,
          retry_at: Date.now() + 3600000
        };
      }
    }
  }

  // Compound fraction stays in LYW available_sats for redeployment
  const compoundFraction = split.compound || 0;
  const compoundSats = Math.floor(distributableSats * compoundFraction);
  ledger.balance.available_sats += compoundSats;

  // Update LYW State Ledger distribution record
  ledger.distribution.last_distribution_block = await getCurrentBlockHeight();
  ledger.distribution.distributed_sats = totalDistributed;
  ledger.distribution.compound_sats = compoundSats;
  await updateLYW(lyw);

  // Publish distribution report
  const report = {
    dao_cid,
    block_height:       ledger.distribution.last_distribution_block,
    total_income_sats:  totalCycleIncome,
    total_expenses_sats: totalCycleExpenses,
    distributable_sats: distributableSats,
    distributions,
    compound_sats:      compoundSats
  };

  const reportCID = await ipfs.dag.put(report);
  ledger.distribution.distribution_history_cid = appendToHistory(
    ledger.distribution.distribution_history_cid,
    reportCID
  );
  await updateLYW(lyw);

  return reportCID;
}
```

---

## 5. Host Payment Model

**Host payments in IPFS-Sats 0.4 are not managed by the DAO's governance cycle.** Hosts earn per block delivered through SatSwap exchange completions. Payment is atomic with delivery — the HTLC settles when the preimage is revealed, simultaneously confirming delivery and releasing payment.

The DAO's role in host economics is indirect: the LYW's `available_sats` balance funds the Lightning payments that flow to hosts when SatSwap exchanges complete. Maintaining a healthy LYW balance ensures hosts continue to receive WANT messages and the content remains available. When `drawdown_mode` is true, host SatSwap payments are suspended — the LYW's income continues to flow to DAO members only, and content availability degrades as hosts that are no longer receiving payment reduce service.

**There is no Proof-of-Storage challenge-response mechanism.** The SatSwap exchange is the proof of availability. A host that delivers a valid block — one whose hash matches the requested CID — has proven it holds that block. No separate verification step is required or implemented.

```javascript
/**
 * Checks LYW balance and drawdown_mode status.
 * Key 3 monitors this to determine whether host payments can continue.
 * Called at each distribution cycle.
 * @param {string} lyw_address
 * @returns {Object} { can_pay_hosts: boolean, available_sats: number }
 */
async function checkHostPaymentCapacity(lyw_address) {
  const lyw = await getLYW(lyw_address);
  const ledger = lyw.state_ledger;

  const drawdownMode = ledger.expenses.drawdown_mode;
  const availableSats = ledger.balance.available_sats;
  const sunsetThreshold = ledger.balance.sunset_threshold_sats;

  if (drawdownMode) {
    // LYW is below threshold — host SatSwap payments suspended
    // Increment cycles_at_threshold counter
    ledger.balance.cycles_at_threshold += 1;
    await updateLYW(lyw);

    return {
      can_pay_hosts: false,
      available_sats: availableSats,
      cycles_at_threshold: ledger.balance.cycles_at_threshold,
      message: "Drawdown mode active — host payments suspended"
    };
  }

  if (availableSats > sunsetThreshold) {
    // Reset cycles_at_threshold if balance recovered
    if (ledger.balance.cycles_at_threshold > 0) {
      ledger.balance.cycles_at_threshold = 0;
      ledger.expenses.drawdown_mode = false;
      await updateLYW(lyw);
    }
  }

  return {
    can_pay_hosts: true,
    available_sats: availableSats,
    cycles_at_threshold: 0
  };
}
```

**Host payment flow summary:**

| Event | Who pays | Mechanism | Timing |
|---|---|---|---|
| Content block requested | Requester → Host | SatSwap HTLC | Atomic with delivery |
| LYW funds host payments | LYW → Host | SatSwap HTLC via Key 3 | Per exchange completion |
| LYW balance depleted | — | drawdown_mode activates | Automatic threshold check |
| LYW balance recovers | — | drawdown_mode deactivates | Automatic threshold check |

For the full SatSwap exchange implementation, see the SatSwap Protocol Specification.
