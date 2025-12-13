## 4.2 Operations

The three-key architecture enables a spectrum of operations ranging from fully permissionless (anyone can send payments) to highly restricted (only $\text{DAO}$ supermajority can authorize). This section maps each type of operation to its required key combinations, creating a clear authorization matrix that balances accessibility, automation, and security.

Understanding this authorization model is critical for both users and developers: users need to know what they can do unilaterally versus what requires consensus, and developers need to implement the correct verification logic for each operation type.

-----

### 4.2.1 Receiving Payments (No Signature Required)

**Principle:** Anyone can send value to the $\text{Lightning Yield Wallet}$ ($\text{LYW}$) without requiring any signatures from the $\text{DAO}$ or its members. This is fundamental to the value-for-value economy—users must be able to "zap" content creators instantly and spontaneously.

The wallet's unique multi-signature address is designed to be a standard Bitcoin/Lightning destination, ensuring maximum accessibility.

#### Operations: Inflows to the LYW

Incoming funds are categorized by their origin and purpose, but all share the property of being permissionless to receive.

1.  **Lightning Zaps (Micropayments)**
    Users send instant, low-fee Lightning payments directly to the wallet's Lightning Address, which is stored in the content's metadata. This is the primary source of revenue.

    > *Example:* A fan sends 1,000 sats to a musician's content $\text{DAO}$ wallet via a standard Lightning invoice. The $\text{LYW}$ balance increases automatically.

2.  **Bitcoin On-Chain Deposits**
    Used for larger amounts, initial channel funding, or capital contributions. These funds are sent to the $3$-of-$3$ multi-sig Bitcoin address (derived from $\text{Keys 1+2+3}$).

    > *Example:* An investor deposits $0.01$ $\text{BTC}$ to the $\text{DAO}$ wallet's on-chain address.

3.  **Content Retrieval Micropayments**
    These payments are made by users to hosts in exchange for content retrieval. They occur atomically via $\text{HTLC}$ (Hashed Timelock Contract) to ensure the exchange is trustless.

      * The host generates a payment request (invoice).
      * The user pays the invoice.
      * The $\text{HTLC}$ ensures the user gets the content only if the payment succeeds, and the host gets the payment only if the content is delivered. **No signatures are required from the content $\text{DAO}$ itself.**

#### Why Receiving is Permissionless

Receiving payments is permissionless by design to eliminate friction and maximize the value-for-value mechanism:

  * **Enables Spontaneous Support:** Fans can support content instantly without identity registration or authorization delays.
  * **Increases Accessibility:** Anyone with a standard Bitcoin or Lightning wallet can contribute, aligning with the open, permissionless nature of the underlying protocols.
  * **Security Principle:** While receiving is permissionless, spending funds always requires one or more signatures (e.g., $\text{Key 3}$ for automation, or $\text{Key 2}$ for governance), ensuring the wallet's assets cannot be compromised by incoming payments.

#### Policy and Accounting

The $\text{DAO}$ metadata includes policies to mitigate abuse and ensures full transparency.

  * **Dust Attack Prevention:**
    The $\text{DAO}$ can set a minimum payment threshold and rate limits to prevent denial-of-service ($\text{DoS}$) attacks via numerous tiny payments.

    ```json
    "receiving_policy": {
      "minimum_payment": 1,  // sats (reject anything smaller)
      "rate_limit": {
        "max_per_minute": 100,  // Prevent DoS via many tiny payments
        "max_per_hour": 1000
      },
      "reject_from": []  // Blacklist for abusive senders (optional)
    }
    ```

  * **Accounting and Auditability:**
    All received payments are automatically logged and published to $\text{IPFS}$ for public transparency and $\text{DAO}$ auditing.

    ```json
    {
      "received_payments": [
        {
          "timestamp": 1735094400,
          "amount": 1000,
          "source": "anonymous_zap",
          "type": "lightning_zap",
          "memo": "Love this song!"
        }
        // ... more transactions
      ]
    }
    ```

-----
