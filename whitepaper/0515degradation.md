## 5.1.5 Economic Degradation & Host Selection Logic 📉

To ensure content persists for the maximum possible duration even as funds dwindle, IPFS-Sats utilizes an **Economic Degradation Protocol**. This mechanism allows the `DAO` (via Key 3) to signal reducing demand to the network, triggering a graceful reduction in redundancy rather than a catastrophic, sudden loss of availability.

### The Dynamic Payout Gradient

The Lightning Yield Wallet ($\text{LYW}$) does not pay a static rate forever. Instead, Key 3 adjusts the **Storage Bid (sats/GB)** based on the wallet's **Runway Health** (Remaining Balance / Monthly Burn).

| Wallet Health | Runway | Bid Strategy | Network Effect |
| :--- | :--- | :--- | :--- |
| **Abundant** | $>24 \text{ mo}$ | **Premium Bid** ($\text{Market Rate} + 10\%$) | Attracts **all hosts**, including expensive, high-speed edge nodes (home computers, mobile). Max redundancy/speed. |
| **Standard** | $6\text{-}24 \text{ mo}$ | **Market Bid** ($\text{Average Market Rate}$) | Retains standard hosts and data centers. Expensive edge nodes likely drop the content. |
| **Critical** | $<6 \text{ mo}$ | **Survival Bid** ($\text{Market Floor}$) | Offers only the bare minimum. Retains only the most efficient, low-cost storage providers (hyperscale/archival). |
| **Depleted** | $0 \text{ mo}$ | **Zero Bid** | All compensated hosts drop content. **Fades to Creator Node only.** |

### Host Logic: Decentralized Cost/Benefit Analysis

Hosts in IPFS-Sats do not blindly store data. Each node runs a local **Economic Logic Daemon** that compares the DAO's offered bid against the node's internal cost floor.

1.  **High-Cost Nodes (e.g., Home Desktop/App):** These nodes have limited storage and high opportunity cost. When the LYW drops from "Premium" to "Standard" pricing, their daemon detects that `Offer < Cost`. They **automatically unpin** the content to free up space for higher-paying data.
2.  **Low-Cost Nodes (e.g., Data Center/Archival):** These nodes operate with massive economies of scale. They remain profitable even at "Survival" bid rates, continuing to store the content long after others have dropped it.



### The Result: Graceful Degradation

This interaction creates a natural lifecycle for content that matches its economic reality:

1.  **Peak Popularity:** High yield/zaps allow the wallet to pay **Premium Bids**. Content is replicated on hundreds of fast devices globally.
2.  **Normalization:** As hype fades, the wallet stabilizes at **Market Bids**. Content remains safe on reliable servers, but expensive edge caching drops off.
3.  **Long Tail:** If funding dries up, the wallet switches to **Survival Mode**. The content retreats to a few efficient, low-cost archival nodes.
4.  **Creator Fallback:** Finally, if all funds are exhausted, the content persists solely on the **Creator's personal node** (or any altruistic fans), ensuring it is never lost unless truly abandoned by its owner.

This mechanism maximizes the **temporal length** of persistence by sacrificing **redundancy** when funds are low, ensuring the system prioritizes *survival* over *speed* during lean times.
