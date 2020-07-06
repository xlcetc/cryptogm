// Copyright 2020 cetc-30. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

package sm2

import (
	"encoding/asn1"
	"io"
	"math/big"
)

type sm2Signature struct {
	R, S *big.Int
}

func (priv *PrivateKey) Sign(rand io.Reader, msg []byte) ([]byte, error) {
	r, s, err := Sign(rand, priv, msg)
	if err != nil {
		return nil, err
	}
	return asn1.Marshal(sm2Signature{r, s})
}

func (pub *PublicKey) Verify(msg []byte, sign []byte) bool {
	var sm2Sign sm2Signature
	_, err := asn1.Unmarshal(sign, &sm2Sign)
	if err != nil {
		return false
	}
	return Verify(pub, msg, sm2Sign.R, sm2Sign.S)
}