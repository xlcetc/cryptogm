// Copyright 2020 cetc-30. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.

//go:build arm64
// +build arm64

package sm3

// no asm
func block(dig *digest, p []byte) {
	Block(dig, p)
}
