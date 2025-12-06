## 3.2.3 IPFS-Sats Protocol Metadata

The **Metadata Bundle** for every piece of content includes the essential, protocol-specific configuration data required for the IPFS-Sats economic and governance layers. This data is housed within the `ipfs_sats_metadata` object.

This information directs clients on how to interact with the economic layer (payment, royalties) and the governance layer (DAO structure) associated with the content.

### Protocol Data Structure

```json
{
  "version": "2.0",                       // Protocol version for client compatibility
  "wallet_address": "lnbc1...",           // Lightning payment destination (LYW)
  "channel_id": "xyz789...",              // Associated Lightning Channel Anchor
  "dao_cid": "QmDAOconfig...",            // IPFS CID of the DAO configuration
  "smart_contract_hash": "sha256:abc..."  // Hash of the core smart contract logic
}
```

-----

### Field Definitions

  * **Version**
    :   Specifies the **Protocol Version** (e.g., "2.0"). This field ensures **forward compatibility**, allowing IPFS-Sats clients to appropriately handle changes in the protocol's structure, rules, or required transaction formats as the system evolves.

  * **Wallet Address**
    :   The **Lightning Network payment destination** tied to the creator's **Lightning Yield Wallet (LYW)**. This is the content's **economic interface**—the point where value flows to creators. It receives payments from various sources:
    \* **Zaps:** Value-for-value tips from appreciative users.
    \* **Retrieval Payments:** Micropayments for data delivery (when applicable).
    \* **Royalties:** Automated revenue from derivative works.

  * **Channel ID**
    :   The identifier of the specific Lightning Network channel used to anchor the content's timestamp and fund the LYW. This field links the content to its **on-chain temporal proof**.

  * **DAO CID**
    :   A link to a separate **IPFS object** that defines the content's **Decentralized Autonomous Organization (DAO) governance structure** (detailed further in Section 6). This configuration typically includes:
    \* Member list and voting weights.
    \* Quorum and threshold requirements for proposals.
    \* Revenue distribution formulas.

    Storing governance as a separate CID allows the DAO configuration to be **updated** (creating a new DAO CID) and **shared** across multiple related content pieces (e.g., all tracks on an album).

  * **Smart Contract Hash**
    :   The $\text{SHA-256}$ hash fingerprint of the **core smart contract code** responsible for managing the content's economics. This contract manages crucial logic, including:
    \* Yield and royalty distribution.
    \* Host node payment verification.
    \* Licensing enforcement.

    This hash serves as an **immutable fingerprint**, allowing users and auditors to verify that the executed contract logic has not been tampered with. The full contract code is typically retrievable via the DAO configuration.
