## 4.2.5 Authorization Matrix: The Key to Trustless Governance 🗝️

The Authorization Matrix defines the security model of $\text{IPFS}$-$\text{Sats}$, demonstrating how the separation of roles between the **Content $\text{Key}$ ($\text{Key 1}$)**, the **Human Control $\text{Key}$ ($\text{Key 2}$)**, and the **Execution $\text{Key}$ ($\text{Key 3}$)** enforces security and sovereignty.

A checkmark ($\checkmark$) indicates the cryptographic signature from that key is required for the transaction to be valid. An em dash (—) indicates the key is not required.

| Operation Category | Operation | Key 1 (Content) | Key 2 (Human Control) | Key 3 (Automation) | Notes / Purpose |
| :--- | :--- | :--- | :--- | :--- | :--- |
| **Permissionless Inflow** | Receive Lightning Zap | — | — | — | Standard Bitcoin behavior; permissionless by design. |
| | Receive On-Chain Deposit | — | — | — | Wallet always accepts funds; no key required to receive. |
| **Routine Automation** | Yield Distribution | — | — | $\checkmark$ | Executed automatically within $\text{DAO}$ limits and schedule. |
| | Host Payments | — | — | $\checkmark$ | Executes after verified Proof-of-Storage. |
| | Report Generation | — | — | $\checkmark$ | Routine metadata update; read-only data publishing. |
| | Liquidity Lease Renewal | — | — | $\checkmark$ | Automated financial optimization (if profitable). |
| **Governance & Policy** | Change Yield Split | — | $\checkmark$ | $\checkmark$ | Requires $\text{DAO}$ vote ($\text{Key 2}$ consensus) for execution ($\text{Key 3}$). |
| | Add/Remove Member | — | $\checkmark$ | $\checkmark$ | Modifies the $\text{Key 2}$ multi-sig structure. |
| | Update Contract Rules | — | $\checkmark$ | $\checkmark$ | Change to automation logic, requires $\text{Key 2}$ consensus. |
| | Large Withdrawal | — | $\checkmark$ | $\checkmark$ | Exceeds $\text{Key 3}$'s auto-approve limit; requires $\text{DAO}$ vote. |
| | Emergency Pause | — | $\checkmark$ | $\checkmark$ | Halts $\text{Key 3}$ execution after a rapid $\text{Key 2}$ vote. |
| **Ultimate Sovereignty** | **Replace $\text{Key 3}$** | $\checkmark$ | $\checkmark$ | — | **Override:** Bypasses a compromised $\text{Key 3}$ (Fail-Safe 1). |
| | **Transfer Ownership** | $\checkmark$ | $\checkmark$ | $\checkmark$ | Sale of content asset; requires all three for final transfer of $\text{Key 2}$. |
| | **DAO Dissolution** | $\checkmark$ | $\checkmark$ | — | Final withdrawal/migration; highest security clearance required. |

---

## Summary: Operational Security

The $\text{IPFS}$-$\text{Sats}$ three-key architecture creates **defense in depth** by separating authority into distinct, role-based keys. This separation ensures that no single point of failure can compromise the asset or its governance structure.

| Principle | Key/Combination | Security Gain |
| :--- | :--- | :--- |
| **No Single Point of Failure** | $\text{Key 1, Key 2, Key 3}$ | No one key can act alone for critical operations (e.g., spending, rule changes). |
| **Automation without Risk** | $\text{Key 3}$ | Executes routine tasks efficiently but operates within strict, pre-defined spending limits. |
| **Human Oversight** | $\text{Key 2}$ + $\text{Key 3}$ (or $\text{Key 1}$ in emergency) | $\text{Key 2}$ can always pause automated processes or initiate a vote to override $\text{Key 3}$. |
| **Content Integrity** | $\text{Key 1}$ | Cryptographically ensures the wallet and funds are dedicated to the specific, verifiable content ($\text{CID}$). |
| **Recovery Possible** | $\text{Key 1}$ + $\text{Key 2}$ or $\text{Key 1}$ + $\text{Key 3}$ Logs | Multiple paths to regain control or replace compromised keys, preventing permanent loss. |

This robust combination enables $\text{IPFS}$-$\text{Sats}$ to be simultaneously:

* **Accessible:** Anyone can "zap" funds without permission ($\text{Key 1, 2, 3}$ not required for inflow).
* **Automated:** Routine operations happen efficiently and instantly without human intervention ($\text{Key 3}$ alone).
* **Secure:** Major changes require consensus and a timelock ($\text{Key 2}$ + $\text{Key 3}$).
* **Recoverable:** Multiple fail-safes prevent permanent loss of control ($\text{Key 1}$ + $\text{Key 2}$ for override).
