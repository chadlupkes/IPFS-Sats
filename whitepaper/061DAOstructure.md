# 6. Per-Content DAO Governance 🏛️

The governance for specific content parameters is managed by a **Per-Content Decentralized Autonomous Organization (DAO)**. This governance mechanism is tied directly to the content's core economic structure — specifically the income distribution ratio defined in the Metadata Bundle. The structure is self-contained and uses existing contract parameters to determine voting rights, ensuring simplicity and economic alignment.

---

## 6.1 DAO Structure: Economic Alignment and Voting Power

The Per-Content DAO operates under a structure where influence is directly proportional to the economic stake held by the participants.

### Membership, Weights, and Roles

#### 1. Membership

Membership in a Per-Content DAO is automatically granted to any entity listed as a recipient in the content's income distribution ratio at the time the Metadata Bundle is published.

- **Stakeholder Types:** This includes the Content Creator, initial depositors who funded the LYW at launch, and hosts contracted to receive a share of the content's persistent revenue stream.

#### 2. Voting Weights

Voting weight within the Per-Content DAO is defined by the member's percentage share of the content's sats income stream, as specified in the Metadata Bundle.

- **Defined by Metadata Bundle at publication:** The income distribution ratio published in the Metadata Bundle establishes initial voting weights and serves as the baseline for all governance activity. By default, this ratio is a governable parameter — a supermajority DAO vote can adjust allocations as the project evolves, with any change simultaneously updating the voting weights of all subsequent proposals.
- **Optional lock via Key 1 configuration:** The creator can configure Key 1 to explicitly prohibit distribution changes, making the ratio a permanent constant for that CID. When locked, the distribution ratio cannot be altered by any DAO vote. If participants want different distributions under a locked DAO, the mechanism is to publish a new CID with a new Metadata Bundle and a new DAO initialized with the desired ratios. The parent CID's DAO remains exactly as originally configured and continues operating under its original terms indefinitely.
- **Hostile takeover protection:** Whether locked or unlocked, distribution reallocation requires a supermajority (66.7%) to pass — precisely because changing the distribution ratio simultaneously changes voting weights for all future proposals. This threshold is the structural defense against a majority voting to strip the minority of their economic stake.

| Stakeholder Type | Example Income Ratio | Voting Weight |
|---|---|---|
| **Content Creator** | 50% | 50% of total DAO vote |
| **Initial Depositor Group** | 30% | 30% of total DAO vote |
| **Host Pool** | 20% | 20% of total DAO vote |
| **Total** | **100%** | **100% Total Distributable Voting Power** |

#### 3. Key 1 Authority and Creator Governance Configuration

The Content Creator's authority within the DAO is expressed through Key 1 (the Content Binding Key, defined in Section 4.1). Key 1 is not necessarily a single key held by a single person — its governance structure is fully configurable at the time of Metadata Bundle creation and reflects the creator's chosen model for collective decision-making.

Key 1 authority can be configured as any of the following:

- **Solo:** A single creator controls Key 1 unilaterally. All Key 1 actions execute immediately without additional approval.
- **Multi-sig Majority:** Key 1 actions require approval from more than half of the designated Key 1 signers. Appropriate for small collaborative teams.
- **Multi-sig Supermajority:** Key 1 actions require approval from two-thirds or more of the designated Key 1 signers. Appropriate for projects where significant decisions warrant broader consensus.
- **Universal Consensus:** Key 1 actions require unanimous agreement from all designated signers. Appropriate for foundational codebases, public goods, or any project where no unilateral authority is acceptable.

The creator can also configure Key 1 to be effectively locked — setting conditions under which no Key 1 action can be taken at all, creating a fully autonomous DAO governed only by Key 2 (member governance) and Key 3 (automation). In this configuration, any change to the DAO's operational parameters requires either a fork or a DAO vote within the bounds of what Key 2 governs.

This design means the creator's governance flexibility operates at two levels: how Key 1 is constructed at publication time, and — in the default unlocked configuration — through supermajority DAO votes at runtime. The locked configuration trades runtime flexibility for a permanent guarantee to participants that the foundational terms under which they joined cannot change.

#### 4. Roles

- **Proposer:** Any member whose income share meets a minimum content-specific threshold (e.g., 0.1% of Total Distributable Voting Power) can submit a formal proposal. A small sats bond is required to filter low-effort or frivolous proposals; this bond is returned when the proposal reaches minimum participation quorum, or forfeited otherwise.
- **Voter:** All members defined in the distribution ratio can cast votes (For, Against, or Abstain). The weight of each vote equals the member's income share percentage.

---

### Quorum and Threshold Requirements

All quorum and threshold requirements are calculated against the **Total Distributable Voting Power** — the full 100% of the income distribution ratio.

#### Quorum (Participation)

A minimum percentage of Total Distributable Voting Power must participate in a vote for the result to be valid and executable.

- **Standard Quorum:** 35% of Total Distributable Voting Power for all standard proposals.
- **Emergency Quorum:** A reduced quorum (e.g., 20%) may be accepted for time-sensitive emergency proposals, such as security patches requiring immediate action.

#### Threshold (Passage)

The threshold is the minimum percentage of *participating* votes required for a proposal to pass.

| Proposal Type | Description | Required Threshold |
|---|---|---|
| **Standard Parameters** | Adjusting content access fees, host incentive multipliers, or minor operational rules | 51% of participating voting power (Simple Majority) |
| **Critical / Constitutional** | Smart contract upgrades, Key 1 configuration changes, or reallocation of Content Treasury funds | 66.7% of participating voting power (Supermajority) |

---

### Governance Process and Voting Periods

The governance process is structured into distinct, time-bound phases to ensure adequate review and participation.

| Phase | Duration | Description |
|---|---|---|
| **Proposal Submission** | 48 hours | Proposal parameters are finalized, the required sats bond is locked, and the proposal enters the queue |
| **Discussion Period** | 72 hours | Off-chain period for community review and feedback before on-chain voting begins |
| **Voting Phase** | 7 days | The on-chain period during which members cast votes weighted by their income share |
| **Execution Delay** | 24 hours | A grace period after a successful vote before the change is enacted by Key 3, allowing all stakeholders time to review and respond |
