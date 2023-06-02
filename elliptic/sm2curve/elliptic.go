package sm2curve

import (
	"crypto/ecdsa"
	"crypto/elliptic"
)

type SM2PublicKey ecdsa.PublicKey

func init() {
	initSM2P256()
}

// P256 returns a Curve which implements sm2 curve.
// The cryptographic operations are implemented using constant-time algorithms.
func P256() elliptic.Curve {
	return p256
}
