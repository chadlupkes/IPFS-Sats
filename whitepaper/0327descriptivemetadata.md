## 3.2.7 Descriptive Metadata 🔍

The **Descriptive Metadata** section provides human-readable and machine-indexable context about the content itself. Unlike the protocol-specific fields (Sections 3.2.3–3.2.6), these fields are primarily designed for **discoverability, searchability, and display** across decentralized applications.

### Descriptive Data Structure

This object includes both standard, recognized fields and an arbitrary extension field for specialized details.

```json
{
  "title": "Symphony in D Minor",
  "description": "A haunting orchestral piece exploring themes of loss and redemption",
  "tags": ["classical", "orchestral", "symphony", "emotional"],
  "media_type": "audio/mpeg",
  "language": "en",
  "duration": 1847,           // In seconds
  "file_size": 45678901,      // In bytes
  "thumbnail_cid": "QmThumbnail...",
  "additional": {
    "composer": "Jane Doe",
    "performed_by": "City Orchestra",
    "recording_date": "2025-11-15",
    "instruments": ["violin", "cello", "piano", "flute"]
  }
}
```

-----

### Fields for Discoverability

Descriptive metadata allows decentralized search engines to index and categorize content **without relying on centralized services**.

  * **Standard Fields:** Include universally recognized data points like **`title`**, **`description`**, **`tags`** (keywords for categorization), **`media_type`** (MIME type for client rendering), and **`language`** (ISO 639-1 code).
  * **Extended Fields (`additional`):** This arbitrary object allows creators to include structured, domain-specific data (e.g., *composer* for music, *resolution* for video, *dependencies* for software). This ensures the protocol can handle rich metadata for any asset type.
  * **Thumbnail/Preview:** The **`thumbnail_cid`** links to a small, optimized preview file (e.g., a 200x200px image, a 30-second audio clip). This enables client applications to provide **rich preview displays** for content catalogs and search results without requiring the download of the full, large file.

-----

## Metadata Object Lifecycle

The complete metadata bundle is a complex object composed of all seven component sections (3.2.1 through 3.2.7). Its creation follows a precise sequence:

### Metadata Object Creation Flow

1.  **Raw Content Upload:** The file is uploaded to IPFS, generating the `content_cid`.
2.  **External Data Fetch:** Current Bitcoin block height is queried, and the creator generates a digital signature using their cryptographic key.
3.  **Bundle Construction:** The complete metadata object (including protocol data, identity, and descriptive fields) is assembled.
4.  **Serialization:** The object is serialized using **dag-cbor** for efficient, binary encoding and deterministic hashing.
5.  **Metadata Upload:** The serialized bundle is uploaded to IPFS, generating the **`metadata_cid`** (the primary, immutable identifier).
6.  **Usage:** The `metadata_cid` is used for all interactions: sharing, indexing, legal referencing, and triggering Lightning payments.

### Metadata Immutability vs. Updates (IPNS)

The core challenge of content-addressing is that changing a single field in the metadata creates an entirely new `metadata_cid`, potentially breaking existing links.

#### Solution: InterPlanetary Name System (IPNS)

IPFS-Sats uses **IPNS** to provide a **mutable pointer** to the latest version of the immutable metadata object.

1.  The creator generates an **IPNS name** (often derived from their **Decentralized Identifier**).
2.  This IPNS name is initially signed to point to the first metadata version (e.g., `/ipns/k51qzi...` $\to$ `QmMetadata_v1`).
3.  When a protocol-level update occurs (e.g., a DAO vote changes a royalty split), a new metadata CID is generated (e.g., `QmMetadata_v2`).
4.  The creator signs an update that points the **same IPNS name** to the new `QmMetadata_v2`.

**Best Practice:**

  * **Immutable References** (e.g., legal documents, long-term archives) should use the raw **`metadata_cid`**.
  * **Dynamic References** (e.g., client applications, websites) should use the **IPNS name** to ensure they always resolve to the latest, most up-to-date version of the content's configuration and rights.
