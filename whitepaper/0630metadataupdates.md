## 6.3 Metadata Bundle Updates & Propagation 📡

While the underlying media content stored on $\text{IPFS}$ is fundamentally **immutable** (any change generates a new Content $\text{CID}$), the rules governing that content are dynamic. The **Metadata Bundle** serves as the lightweight, mutable container for these economic and commercial rules. This section details how a successful $\text{DAO}$ vote translates into a technical update that is propagated and strictly enforced across all storage providers and gateways.

### The Structure of the Metadata Bundle

The Metadata Bundle is a lightweight $\text{JSON}$ object associated with the content's master Smart Contract. It acts as the "operating system" for the content, dictating how the network interacts with the static files.

| Component | Description | Example Data |
| :--- | :--- | :--- |
| **Economic Logic** | The current Yield Distribution Table and Access Pricing (cost in $\text{\$SATS}$), and Zap allocation split. | `{"price_sats": 1500, "creator_share": 0.50, ...}` |
| **Rights Management** | Licensing status, remix permissions, and regional restrictions for access/forking. | `{"license": "CC-BY-NC-SA", "remix_perm": true, ...}` |
| **Pointer (Payload)** | The $\text{IPFS CID}$ of the immutable media files (the "Payload"). | `"ipfs_cid": "QmSong..."` |
| **Version History** | A cryptographic hash chain linking to previous versions of the metadata for full auditability. | `"prev_cid": "QmzAP..."` |

### The Atomic Bundle Update Mechanism

When a governance proposal passes the required Threshold and completes the mandatory Execution Delay (as defined in 6.1 and 6.2), the system initiates an **Atomic Bundle Update**:

1.  **State Transition:** The $\text{DAO}$ Smart Contract commits the new parameters to the blockchain state.
2.  **Regeneration & Re-Hashing:** A new Metadata Bundle ($\text{JSON}$) is generated using the new rules, and this bundle is cryptographically hashed to create a new **Governance $\text{CID}$ ($\text{CID}_{gov}$)**.
3.  **Source of Truth:** The Smart Contract executes a transaction to update its `CurrentMetadataPointer` variable, pointing it to the new $\text{CID}_{gov}$. This single, immutable transaction serves as the verifiable **Source of Truth** for the entire network.

### Propagation and Enforcement to Content Hosts

Content Hosts (Storage Providers) must enforce the new rules immediately to remain compliant and eligible for continuous yield payments. This is achieved through an event-driven **"Push-Pull" architecture**:

#### The Push (Event Emission)

Upon updating the `CurrentMetadataPointer`, the Smart Contract emits a standard **`MetadataUpdate` event** containing:

* The new **$\text{CID}_{gov}$**.
* The **Effective Block Number** at which the new rules must be enforced.

#### The Pull (Node Synchronization)

All active Content Hosts run a lightweight service ("The Watcher") that subscribes to and monitors these events from the contracts of the content they host.

1.  **Detection & Fetch:** The Watcher detects the `MetadataUpdate` event and immediately retrieves the new Metadata Bundle ($\text{JSON}$) via $\text{IPFS}$ using the new $\text{CID}_{gov}$.
2.  **Validation:** The node verifies that the update was initiated by the correct, approved $\text{DAO}$ Smart Contract.
3.  **Application:** The node updates its local gateway configuration (e.g., adjusts the payment requirement, or $\text{SATS}$ routing logic for incoming retrieval requests).

#### Synchronization and Hard Enforcement

To prevent **race conditions** where users and hosts are operating under conflicting rules, updates are strictly enforced based on **Block Height**:

* **Effective Block:** The `MetadataUpdate` event specifies a future block number (e.g., $\text{CurrentBlock} + 100$) as the point of enforcement. This buffer zone allows time for global node synchronization.
* **Hard Enforcement:** Once the **Effective Block** is mined, all nodes must strictly enforce the new Metadata Bundle. Any node continuing to serve content under the old, deprecated rules (e.g., serving content at a lower price than mandated) will fail **Proof-of-Commerce** checks and may be penalized by the protocol, ensuring consistent rules across the decentralized network.
