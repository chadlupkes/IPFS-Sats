## 3.2.4 Creator Identity & Signature 🔑

The **Creator Identity & Signature** object is essential for establishing **provable authorship** and ensuring the integrity of the content's metadata. IPFS-Sats is designed to be **Identity System Agnostic**, supporting any cryptographic standard capable of generating a verifiable signature. This maximizes accessibility while enforcing the core requirement of **cryptographic proof**.

### Creator Identity Structure

This structure holds the necessary elements for verification: the identifier, the method used, and the cryptographic proof that the creator authorized the metadata bundle.

```json
{
  "identity_type": "did:key",       // Standard or scheme (e.g., "nostr", "bitcoin")
  "identifier": "did:key:z6MkhaXgBZDvotDkL5...", // The creator's public identifier
  "signature": "ed25519:A8B3C9D2E1F4...",    // Cryptographic proof of authorization
  "public_key": "base58:5Hd7YFqz...",      // Public key for signature verification
  "signature_algorithm": "ed25519"         // Algorithm used (e.g., "secp256k1")
}
```

-----

### Universal Verification Requirements

Regardless of the identity scheme chosen, all entries must adhere to the following principles to enable universal verification by any IPFS-Sats client:

  * **Public Identifier:** A unique, publicly-shareable string (e.g., $\text{npub}$ or $\text{bc1}$ address).
  * **Signature:** Cryptographic proof that the holder of the private key signed the current state of the metadata bundle (minus the signature field itself).
  * **Verification Algorithm:** Explicitly specified method (e.g., $\text{secp256k1}$ or $\text{ed25519}$) required to perform the signature check.
  * **Public Key (or derivable):** The key material needed to verify the signature against the hash of the metadata.

### Flexibility and Supported Identity Types

IPFS-Sats supports a wide range of popular cryptographic standards, allowing creators to use an identity they already control, reducing friction and maximizing adoption.

| Identity Type | Scheme Example | Core Use Case & Rationale |
| :--- | :--- | :--- |
| **W3C DID** | `did:key:z6Mkha...` | **Institutions, Interoperability.** Self-sovereign, multi-method, and aligned with global decentralized identity standards. |
| **Nostr** | `npub1sg6plzptd...` | **Social Media, Lightning-Native.** Uses $\text{secp256k1}$ cryptography, integrating directly with the Nostr social protocol and Bitcoin community. |
| **Bitcoin** | `bc1qxy2kgdygjr...` | **Financial Applications, Simplicity.** Proves control of a Bitcoin private key, often the same key used for the Lightning wallet. |
| **Ethereum** | `0x71C7656EC7ab...` | **Web3, NFT Ecosystems.** Compatible with Ethereum's signing standards ($\text{EIP-191}/\text{EIP-712}$) and smart contract interaction. |
| **PGP/GPG** | Key Fingerprint | **Developers, Security-Conscious Users.** Long-established, reliable standard used for software provenance and email security. |
| **Custom/Future** | `quantum-resistant-id...` | **Future-Proofing.** Allows for the inclusion of new, even post-quantum, algorithms (e.g., **Dilithium**), with verification code referenced via IPFS. |

-----

### Why Agnosticism Matters

This identity-agnostic design provides substantial benefits for the protocol's ecosystem:

  * **Accessibility:** Users do not face **identity lock-in**. A developer can use their established SSH key, while a Web3 artist uses their Ethereum wallet, all within the same IPFS-Sats protocol.
  * **Future-Proofing:** The core protocol is decoupled from specific cryptographic implementations. As quantum-resistant or other advanced signature schemes emerge, IPFS-Sats can support them simply by adding a new `identity_type` handler.
  * **Unified Identity (Binding):** For optimal economic functionality, creators are encouraged to use the same cryptographic key to generate both their **Content Signature** and their **Lightning Wallet Address**, creating a single, auditable link: "The key that signed the content is the key that receives the revenue."

### Identity Verification Flow

Clients verify the creator's identity by dynamically selecting the correct verification library based on the `identity_type` specified in the metadata:

```javascript
function verifyCreatorSignature(metadata) {
  const { identity_type, identifier, signature, public_key, signature_algorithm } = metadata.creator;
  const dataToVerify = prepareVerificationData(metadata); // Hash of the metadata minus the signature field
  
  // Select verification method based on identity type
  switch(identity_type) {
    case "did:key":
      return verifyDID(identifier, signature, dataToVerify);
    case "nostr":
      return verifyNostr(identifier, signature, dataToVerify);
    case "bitcoin":
      return verifyBitcoinSignature(identifier, signature, dataToVerify);
    // ... handles all other supported types
    case "custom":
      // Load and execute custom verification logic from IPFS
      const verifier = await ipfs.get(metadata.creator.verification_method);
      return executeCustomVerifier(verifier, identifier, signature, dataToVerify);
    default:
      throw new Error(`Unsupported identity type: ${identity_type}`);
  }
}
```
