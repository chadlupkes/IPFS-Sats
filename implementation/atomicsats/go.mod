module github.com/chadlupkes/ipfs-sats/implementation/atomicsats

go 1.23

// Core dependencies for AtomicSats reference implementation
require (
	// Lightning Network integration (LND client - most common for Go)
	github.com/lightningnetwork/lnd v0.18.0-beta.rc3 // or latest stable
	
	// CID handling (IPFS-compatible content addressing)
	github.com/ipfs/go-cid v0.4.1
	
	// Optional but useful: protobuf for clean wire messages (recommended)
	google.golang.org/protobuf v1.34.2
	
	// Standard structured logging
	go.uber.org/zap v1.27.0
	
	// Basic utilities
	github.com/google/uuid v1.6.0
)

require (
	// These will be pulled in automatically by the above
	github.com/btcsuite/btcd v0.24.2
	github.com/btcsuite/btcd/btcec/v2 v2.3.4
	github.com/btcsuite/btcd/btcutil v1.1.5
	github.com/btcsuite/btcwallet v0.16.10-0.20240404105736-8c0c2c1c3b3f
)
