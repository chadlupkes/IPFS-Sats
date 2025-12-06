## 6.2 Proposal Types and Validation Thresholds 🗳️

Governance actions within the Per-Content $\text{DAO}$ are categorized by their potential impact on the content’s economic structure and technical integrity. To ensure stability and security, different proposal types require corresponding validation thresholds. 

---

### 1. Yield Distribution Reallocation (Constitutional)

A proposal to alter the yield distribution is effectively a proposal to restructure the $\text{DAO}$'s ownership and governance, as voting weight is derived directly from the income distribution ratio. These are the most critical proposals in the system.

* **Scope:** Adjusting the percentage of incoming $\text{\$SATS}$ allocated among the **Content Creator, Stakers, and Storage Providers**.
* **Implication:** A change here **automatically updates the voting weights** for all subsequent proposals, potentially shifting the balance of power.
* **Guardrails:** To prevent **hostile takeovers** (e.g., a majority voting to strip the minority of their revenue share), these proposals require a **Supermajority ($\mathbf{66.7\%}$)**. Some high-value contracts may opt for **"Immutable Distribution,"** disabling Yield Reallocation entirely to guarantee fixed returns for initial investors.

### 2. Membership Changes

Membership changes focus specifically on the entry and exit of participants, linked intrinsically to the Yield Distribution structure.

* **Onboarding:** Granting a new entity (e.g., a new long-term Storage Provider or a Co-Creator) a share of the revenue stream. This typically **dilutes existing shares proportionally** unless specific shares are voluntarily reduced.
* **Offboarding:** Removing a member due to malicious behavior, lack of performance (e.g., a Storage Provider failing proof-of-storage checks), or voluntary exit.
* **Mechanism:** Upon successful passing, the smart contract automatically **mints a new distribution schedule** and burns the old one.
* **Threshold:** **Supermajority ($\mathbf{66.7\%}$)** due to the high governance risk associated with ownership restructuring.

### 3. Smart Contract Updates (Technical)

These proposals address the underlying code governing the content's financial logic and security, separate from the economic parameters.

* **Scope:** Includes **Logic Upgrades** (patching bugs, optimizing gas efficiency), **Security Patches** (addressing protocol vulnerabilities), and **Migration** to a new version of the $\text{IPFS-Sats}$ protocol.
* **Risk Profile:** **High.** A malicious code update could lock funds or break content access.
* **Threshold & Delay:** Always default to the **Supermajority ($\mathbf{66.7\%}$)** threshold and include a mandatory **Extended Execution Delay ($\mathbf{48h}$)** to allow stakeholders time to react (e.g., withdraw their stakes) if they disagree with the proposed upgrade.

### 4. Licensing and Commercial Decisions

These are operational proposals that affect how the content is consumed and monetized, but do not necessarily alter the internal revenue distribution percentages.

* **Access Pricing:** Adjusting the cost (in $\text{\$SATS}$) required for a user to view, decrypt, or download the content.
* **Rights Management:** Toggling content between "View Only" and "Remixable," updating copyright status (e.g., moving to Creative Commons/$\text{CC0}$), or authorizing specific commercial use cases for third parties.
* **Threshold:** As these are business decisions intended to maximize revenue, they typically require a **Simple Majority ($\mathbf{51\%}$)**.

---

### Summary of Proposal Constraints

This table outlines the essential guardrails—Quorum, Threshold, and Delay—required for each type of governance action, reflecting the system's focus on stability and economic alignment.

| Proposal Category | Impact Level | Threshold Required | Standard Quorum | Execution Delay |
| :--- | :--- | :--- | :--- | :--- |
| **Licensing / Pricing** | Low (Operational) | $\mathbf{51\%}$ (Simple Majority) | $35\%$ | $\mathbf{24h}$ (Standard) |
| **Smart Contract Update** | High (Technical Risk) | $\mathbf{66.7\%}$ (Supermajority) | $35\%$ | $\mathbf{48h}$ (Extended) |
| **Membership Change** | High (Governance Risk) | $\mathbf{66.7\%}$ (Supermajority) | $35\%$ | $\mathbf{24h}$ (Standard) |
| **Yield Reallocation** | Critical (Constitutional) | $\mathbf{66.7\%}$ (Supermajority)\* | $35\%$ | $\mathbf{72h}$ (Extended) |

$^*$ *Note: Immutable Distribution contracts automatically reject Yield Reallocation proposals.*
