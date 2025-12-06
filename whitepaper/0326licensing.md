## 3.2.6 Licensing & Terms ⚖️

The **Licensing & Terms** object defines the permissions and restrictions governing the use and derivation of the content. Instead of relying solely on opaque legal text, IPFS-Sats encodes these terms into a **machine-readable structure**. This approach enables automated enforcement, clear user display, and programmatic querying by client applications.

### Licensing Data Structure

The primary licensing structure provides a concise summary of the content's rights.

```json
{
  "type": "custom",                     // Standard (e.g., "MIT", "CC-BY") or "custom"
  "terms_cid": "QmLicenseTerms...",     // IPFS CID of the full, legally-binding license text
  "commercial_use": true,               // Boolean: Does the license allow commercial derivatives?
  "attribution_required": true,         // Boolean: Must the creator be credited?
  "derivative_royalty": 10,             // Default royalty percentage for new derivatives (0-100)
  "geographic_restrictions": [],        // Optional array of jurisdictions (e.g., ["US", "EU"])
  "expiry_date": null                   // Optional UTC timestamp for license expiration
}
```

-----

### Machine-Readable Licensing

The core function of this section is to transform complex legal terms into actionable data points.

  * **Standard License Types:** For common, pre-defined licenses (e.g., **MIT**, **CC-BY-SA**, **Public-Domain**), the `"type"` field references the well-known standard. The full legal text is stored at the **`terms_cid`** for necessary legal reference, providing both clarity and depth.
  * **Automated Enforcement:** Fields like **`commercial_use`** and **`derivative_royalty`** are read directly by the smart contract to determine valid usage and to automate royalty splits upon payment.

### Custom and Conditional Terms

IPFS-Sats allows creators to define highly specific, complex licensing structures using the `"type": "custom"` field.

#### Tiered Commercial Licensing

Creators can define usage tiers based on factors like revenue limits or use case, each with different cost structures.

```javascript
// Example of a custom, tiered license structure:
"license": {
  "type": "custom",
  "terms_cid": "QmCustomLicense...",
  "tiers": [
    {
      "use_case": "personal",
      "cost": 0,
      "attribution": true
    },
    {
      "use_case": "small_business",
      "cost": 10000, // Cost in sats for a license
      "revenue_limit": 100000 // Annual revenue cap
    }
  ]
}
```

#### Geographic and Time Restrictions

These optional fields introduce temporal or jurisdictional limits on the license, which are enforceable at the application and smart contract layers:

  * **Geographic Restrictions:** The **`geographic_restrictions`** array specifies jurisdictions where the license applies (e.g., `restriction_type: "allow"`) or is prohibited (`restriction_type: "deny"`). While IPFS-Sats nodes in restricted regions can still retrieve the content (maintaining censorship resistance), the metadata explicitly indicates the legal constraints on its use.
  * **Time-Limited Licenses:** The **`expiry_date`** field allows for licenses to automatically transition (e.g., from paid commercial use to public domain) at a specific date. The smart contract validates the current time against this field before processing any related payment or royalty.
