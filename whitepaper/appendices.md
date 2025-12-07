# Appendices 📚

## Appendix A: Glossary

This glossary defines the technical terms and key concepts foundational to the $\text{IPFS-Sats}$ Core Protocol.

### Technical Terms Defined

| Term | Definition |
| :--- | :--- |
| **Atomic Exchange** | A transaction mechanism, enabled by $\text{HTLCs}$ on the Lightning Network, that guarantees a simultaneous **"payment or no data"** outcome for block retrieval, ensuring the host is compensated only upon successful data delivery. |
| **Content Addressing** | The core principle of $\text{IPFS}$ where data is identified by a cryptographic hash of its content ($\text{CID}$) rather than its network location, ensuring data integrity and verifiability. |
| **Free Riding** | The behavior of network participants who consume resources by retrieving content without contributing back through hosting, sharing, or providing bandwidth, undermining the system's economic model. |
| **Hashed Timelock Contract ($\text{HTLC}$)** | A cryptographic tool utilized by the $\text{Lightning Network}$ to enable **Atomic Exchanges**. $\text{HTLCs}$ lock a payment until the recipient reveals a cryptographic secret ($\text{pre-image}$), which the sender verifies to unlock the data block. |
| **Lightning Yield Wallet ($\text{LYW}$)** | A specialized Bitcoin wallet that generates passive income ($\text{yield}$) through activities like $\text{Lightning}$ liquidity leasing. This yield automatically funds perpetual storage for the associated content. |
| **Merkle Directed Acyclic Graph ($\text{Merkle DAG}$)** | The fundamental data structure used by $\text{IPFS}$ and $\text{IPLD}$. It is a graph where links between objects are cryptographic hashes ($\text{CIDs}$), making the entire structure tamper-proof. |
| **Persistence Bounty ($\text{PB}$)** | The long-term storage mechanism of $\text{IPFS-Sats}$, where the $\text{LYW}$ yield provides a recurring, self-sustaining payment to hosts committed to pinning content for long periods. |
| **Per-Content DAO** | A Decentralized Autonomous Organization structure automatically generated for every piece of content. It manages governance, licensing, revenue distribution, and derivative work approval for that **single content object**. |
| **Right to Fork** | The foundational digital right institutionalized by the protocol, ensuring any creator can build upon existing work while guaranteeing the original author receives automatic, fair compensation via $\text{Per-Content DAO}$ smart contracts. |
| **Right to Verify** | The foundational digital right that allows every individual to access and authenticate accurate information through transparent, cryptographic proof (the Bitcoin blockchain timestamp). |

### Acronyms Explained

| Acronym | Stands for | Context within $\text{IPFS-Sats}$ |
| :--- | :--- | :--- |
| **$\text{ARP}$** | Atomic Retrieval Payments | The specific $\text{LN}$ mechanism that provides instant, pay-per-block compensation for data retrieval, eliminating free-riding. |
| **$\text{CID}$** | Content Identifier | The unique, immutable, cryptographic hash that serves as the address for any content in $\text{IPFS}$. |
| **$\text{DAO}$** | Decentralized Autonomous Organization | The governance structure used to manage licensing and automated royalty distribution for a single content $\text{CID}$. |
| **$\text{DID}$** | Decentralized Identifier | A self-sovereign identity used to verify the creator's signature in the Metadata Bundle, providing definitive proof of original authorship. |
| **$\text{IPFS}$** | InterPlanetary File System | The underlying content-addressed peer-to-peer file system that the $\text{IPFS-Sats}$ Protocol provides an economic layer for. |
| **$\text{IPLD}$** | InterPlanetary Linked Data | The data model that defines the linked data structures ($\text{Merkle DAG}$) used by $\text{IPFS}$ and the Metadata Bundle. |
| **$\text{LN}$** | Lightning Network | The Bitcoin Layer 2 protocol used for instant, trustless micropayments ($\text{Sats}$ and $\text{Millisats}$) to fund retrieval and persistence. |
| **$\text{SATS}$** | Satoshis | The smallest unit of Bitcoin (1 Sat = $0.00000001 \text{ BTC}$). The native currency used for all micropayments and persistence bounties in the protocol. |

---

## Appendix B: References

### Technical Protocols and Specifications

* **Original $\text{IPFS}$ White Paper:** Benet, Juan. *IPFS - Content Addressed, Versioned, $\text{P2P}$ File System*. (2014).
* **Content Identifier ($\text{CID}$) Specification:** The Multiformats Project. *multiformats/cid: Self-describing content-addressed identifiers for distributed systems*.
* **InterPlanetary Linked Data ($\text{IPLD}$):** Protocol Labs. *IPLD - The data model of the content-addressable web.*
* **Bitcoin Core Protocol:** Satoshi Nakamoto. *Bitcoin: A Peer-to-Peer Electronic Cash System.* (2008).
* **Lightning Network Protocol:** Poon, Joseph, and Thaddeus Dryja. *The Bitcoin Lightning Network: Scalable Off-Chain Instant Payments.* (2016).
* **Bitcoin OP_RETURN Standard:** The Bitcoin opcode used to embed the content's Bundle Hash into a transaction, creating an immutable, timestamped record for the **Right to Verify**. This prunable output is limited to 83 bytes of data.

### Related Technologies and Solutions

* **Filecoin:** Addresses persistence using cryptographic proofs ($\text{Proof-of-Spacetime}$) but is industrial-scale and uses a proprietary token, lacking integration with $\text{IPFS}$ retrieval incentives.
* **Arweave:** Provides one-time permanent storage but lacks native retrieval incentives and flexibility for dynamic data.

---

## Appendix C: Frequently Asked Questions ($\text{FAQ}$)

### Common Questions

| Question | Answer |
| :--- | :--- |
| **How does $\text{IPFS-Sats}$ solve the "Persistence Crisis"?** | Persistence is solved through the **Lightning Yield Wallet ($\text{LYW}$)**. An initial deposit generates passive yield, which automatically funds recurring **Persistence Bounties ($\text{PB}$)** to multiple hosts for long-term storage, removing dependence on continuous manual payments or altruism. |
| **How does the protocol prevent plagiarism and content theft?** | The protocol uses the Bitcoin blockchain to provide an **unforgeable, immutable timestamp** for every piece of content. If a plagiarist uploads the same content later, their subsequent timestamp proves they are not the original creator, invalidating their claim for monetization or ownership. |
| **What is the "Right to Fork" and how is compensation enforced?** | The $\text{Right to Fork}$ allows any creator to build upon existing work. Compensation is enforced automatically by the **Per-Content DAO's smart contract**, which tracks the parent-child relationship and distributes automated $\text{Sats}$ royalties to all ancestor creators when the derivative work is accessed or monetized. |
| **Why use the Lightning Network instead of a new token or a different blockchain?** | The $\text{LN}$ provides **instant, trustless, and ultra-low-cost micropayments** down to the $\text{millisatoshi}$ level, which is necessary to price individual data blocks (**Pay-Per-Block**). It builds on Bitcoin's established security and liquidity, avoiding the complexity and volatility of a new proprietary token. |

### Misconceptions Addressed

| Misconception | Correction |
| :--- | :--- |
| **Misconception: "$\text{IPFS-Sats}$ is a new blockchain or cryptocurrency."** | **Correction:** $\text{IPFS-Sats}$ is a protocol built on top of the **existing $\text{IPFS}$ and $\text{Bitcoin/Lightning Network}$ infrastructure**. It uses Bitcoin ($\text{Sats}$) as its native economic unit and uses the Bitcoin blockchain only for high-security timestamp anchoring, not as a general data storage or consensus layer. |
| **Misconception: "The data is stored on the Bitcoin blockchain."** | **Correction:** Only a tiny cryptographic hash ($\text{Bundle Hash}$) that represents the content's existence and integrity is recorded on the Bitcoin blockchain via OP_RETURN. The actual content is stored **off-chain on the $\text{IPFS}$ network**. |
| **Misconception: "The protocol is centrally controlled by a single $\text{DAO}$."** | **Correction:** Governance is entirely **Per-Content**. Each file generates its own independent $\text{DAO}$, allowing solo creators to maintain full control or complex teams to manage their own revenue and licensing rules without coordination with the rest of the network. |
