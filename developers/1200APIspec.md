# 🌐 IPFS-Sats Protocol Developer API (v2)

Welcome to the **$\text{IPFS-Sats v2 API}$** documentation. This $\text{RESTful}$ interface is the primary tool for building applications that leverage **immutable content addressing ($\text{CID}$)**, **Bitcoin-anchored finality**, and **Lightning Network micro-monetization ($\text{Zaps}$/$\text{Royalties}$)**.

---

## 🔑 Authentication and Security

All $\text{POST}$ requests and sensitive $\text{GET}$ requests **must** be authenticated.

* **API Key:** Passed in the `X-API-KEY` header for service identification and rate limiting.
* **Cryptographic Signature:** All $\text{POST}$ requests that create or transfer value must include a verifiable $\text{ECDSA}$ signature over the request payload in the `X-SIG-AUTH` header. This proves the request originated from the claimed user identity (the creator/funder).
* **Data Format:** All requests and responses use the $\text{application/json}$ content type.

---

## 12.1 Core Endpoints (Content & Monetization)

These endpoints manage the lifecycle of content, from publishing to retrieval and direct payment.

### A. Publish Content (On-Chain Finality)

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/api/v2/content/upload` | $\text{POST}$ | Publishes content. Triggers the $\text{CID}$ hash calculation, initial $\text{IPFS}$ pinning, and sets up the **Lightning Yield Wallet (LYW)**. The commitment to Bitcoin is batched by the service operator. |

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `raw_data` | string (base64) | Yes | The actual content to be hashed and stored. |
| `metadata_bundle` | object | Yes | JSON containing license, royalty split, and creator $\text{DID}$. |
| `lyw_funding_txid` | string | Yes | The Bitcoin $\text{TXID}$ funding the initial **LYW endowment**. |

| Status Code | Response Body | Description |
| :--- | :--- | :--- |
| $\text{202}$ Accepted | `{"cid": "Qm...", "lyw_id": "...", "status": "PENDING_COMMIT"}` | Content accepted. $\text{CID}$ is live on $\text{IPFS}$ and $\text{LYW}$ is active, but main-chain lock is pending batching. |

### B. Retrieve Content & Verify

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/api/v2/content/{cid}` | $\text{GET}$ | Retrieves raw content and essential metadata. |

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `cid` | string | Yes | The Content Identifier ($\text{CID}$) of the resource. |

| Status Code | Response Body | Description |
| :--- | :--- | :--- |
| $\text{200}$ OK | `{"raw_data": "...", "metadata": { ... }, "on_chain_txid": "..."}` | Success. Content is returned. Includes the $\text{Bitcoin TXID}$ confirming finality. |

### C. Facilitate Instant Payment (Zap)

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/api/v2/payment/zap` | $\text{POST}$ | Initiates a direct $\text{Lightning Network}$ payment to the content creator's registered wallet. |

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `target_cid` | string | Yes | The $\text{CID}$ of the content being Zapped. |
| `amount_sats` | integer | Yes | Amount in satoshis to send. |
| `memo` | string | No | Optional message to the creator. |

---

## 12.4 Lightning/Off-Chain Status (LYW & Liquidity) ⚡

These endpoints enable **near-real-time verification** of content funding from the service's internal ledger.

### A. Query Lightning Yield Wallet Status

This is a **read-only endpoint** that provides the status of the content's persistent funding mechanism.

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/api/v2/lyw/status/{cid}` | $\text{GET}$ | Returns the current balance and service health for the $\text{CID}$'s $\text{LYW}$. |

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `cid` | string | Yes | The $\text{CID}$ whose $\text{LYW}$ balance is being checked. |

| Status Code | Response Body | Description |
| :--- | :--- | :--- |
| $\text{200}$ OK | `{"balance_sats": 15000, "verified_at": "...", "signature": "..."}` | Returns current balance and a cryptographic signature confirming the data's authenticity from the service's $\text{DID}$. |
| $\text{404}$ Not Found | $\text{N/A}$ | The $\text{CID}$ is not hosted or funded by this service operator. |

### B. Query Service Operator DID

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/api/v2/lyw/did/{service\_id}` | $\text{GET}$ | Retrieves the public $\text{DID}$ information for the $\text{LYW}$ operator, used to verify signatures on $\text{LYW}$ status queries. |

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `service_id` | string | Yes | A unique identifier for the Pinning Service/LYW Operator. |

| Status Code | Response Body | Description |
| :--- | :--- | :--- |
| $\text{200}$ OK | `{"did": "did:web:...", "public_key": "...", "lyw_status_endpoint": "https://api.example.com/api/v2/lyw/status/"}` | Returns the operator's public keys and the $\text{URL}$ for querying the $\text{LYW}$ status. |

---

## 12.3 Fork Management (Attribution & Royalties)

These endpoints are crucial for tracking content lineage and distributing revenue to all contributors.

### A. Register Derivative Work

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/api/v2/fork/create` | $\text{POST}$ | Links a new $\text{CID}$ ($\text{Child}$) to an existing one ($\text{Parent}$), activating the royalty split. |

| Parameter | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `parent_cid` | string | Yes | The $\text{CID}$ of the original content being forked. |
| `new_cid` | string | Yes | The $\text{CID}$ of the derivative work. |

### B. Query Royalty Ledger

| Endpoint | Method | Description |
| :--- | :--- | :--- |
| `/api/v2/fork/royalties/{cid}` | $\text{GET}$ | Provides an auditable ledger of all revenues and automatic payments related to this content and its lineage. |

| Status Code | Response Body | Description |
| :--- | :--- | :--- |
| $\text{200}$ OK | `{"total_revenue": "...", "distribution_log": [...]}` | Success. Ledger details are returned. |

---

## ⚠️ Error Codes

The $\text{IPFS-Sats API}$ uses standard $\text{HTTP}$ response codes.

| Code | Reason | Resolution |
| :--- | :--- | :--- |
| $\text{400}$ Bad Request | Missing required parameters or invalid JSON format. | Check the request payload against the schema. |
| $\text{401}$ Unauthorized | Missing or invalid `X-API-KEY` or `X-SIG-AUTH` header. | Verify credentials and re-sign the request payload. |
| $\text{402}$ Payment Required | $\text{LYW}$ funding is insufficient for the requested service level. | Add more $\text{sats}$ to the content's $\text{LYW}$. |
| $\text{404}$ Not Found | The requested $\text{CID}$ or $\text{DAO}$ does not exist on this service. | Check the $\text{CID}$ or the $\text{service\_id}$. |
| $\text{429}$ Too Many Requests | Rate limit exceeded for the provided $\text{API}$ key. | Slow down requests and honor the `Retry-After` header. |
