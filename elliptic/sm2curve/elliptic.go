package sm2curve

import (
	"crypto/elliptic"
	"sync"
)

var initOnce sync.Once

func initAll() {
	initP256()
}

// P256 returns a Curve which implements sm2 curve.
// The cryptographic operations are implemented using constant-time algorithms.
func P256() elliptic.Curve {
	initOnce.Do(initAll)
	return p256
}
