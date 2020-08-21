package main

import (
	"fmt"
	"math/big"
)

type gfP2 struct {
	p    *big.Int
	x, y *big.Int
}

func newGFp2(p *big.Int) *gfP2 {
	return &gfP2{
		p: new(big.Int).Set(p),
		x: new(big.Int),
		y: new(big.Int),
	}
}

//cloudflare bn256: i²=-1
func (c *gfP2) Mul(a, b *gfP2) *gfP2 {
	t1, t2 := new(big.Int), new(big.Int)
	t1.Mul(a.y, b.y)
	t2.Mul(a.x, b.x)
	t1.Sub(t1, t2).Mod(t1, c.p)

	t3 := new(big.Int)
	t2.Mul(a.x, b.y)
	t3.Mul(a.y, b.x)

	c.x.Add(t2, t3).Mod(c.x, c.p)
	c.y.Set(t1)
	return c
}

func (c *gfP2) Exp(a *gfP2, scalar *big.Int) *gfP2 {
	sum, t := newGFp2(c.p), newGFp2(c.p)
	sum.y.SetInt64(1)

	for i := scalar.BitLen(); i >= 0; i-- {
		t.Mul(sum, sum)
		if scalar.Bit(i) != 0 {
			sum.Mul(t, a)
		} else {
			sum.Set(t)
		}
	}

	c.Set(sum)
	return c
}

func (c *gfP2) MontEncode(bitSize uint) *gfP2 {
	c.x.Lsh(c.x, bitSize).Mod(c.x, c.p)
	c.y.Lsh(c.y, bitSize).Mod(c.y, c.p)

	return c
}

//sm9 bn256: i²=-2
func (c *gfP2) Sm9Mul(a, b *gfP2) *gfP2 {
	t1, t2 := new(big.Int), new(big.Int)
	t1.Mul(a.y, b.y)
	t2.Mul(a.x, b.x)
	t1.Sub(t1, t2).Sub(t1,t2).Mod(t1, c.p)

	t3 := new(big.Int)
	t2.Mul(a.x, b.y)
	t3.Mul(a.y, b.x)

	c.x.Add(t2, t3).Mod(c.x, c.p)
	c.y.Set(t1)
	return c
}

func (c *gfP2) Sm9Exp(a *gfP2, scalar *big.Int) *gfP2 {
	sum, t := newGFp2(c.p), newGFp2(c.p)
	sum.y.SetInt64(1)

	for i := scalar.BitLen(); i >= 0; i-- {
		t.Sm9Mul(sum, sum)
		if scalar.Bit(i) != 0 {
			sum.Sm9Mul(t, a)
		} else {
			sum.Set(t)
		}
	}

	c.Set(sum)
	return c
}

func (c *gfP2) Set(a *gfP2) *gfP2 {
	c.x.Set(a.x)
	c.y.Set(a.y)
	return c
}

var zeroWordSlice = []big.Word{0,0,0,0,0,0,0,0}

func padding(w []big.Word) []big.Word {
	if len(w) <= 8 {
		w = append(zeroWordSlice[8-len(w):],w...)
	}

	return w
}

func (c *gfP2) Println() {
	fmt.Print("&gfP2{gfP{")
	words := c.x.Bits()
	for _, word := range words[:len(words)-1] {
		fmt.Printf("%#x, ", word)
	}
	fmt.Printf("%#x}, gfP{", words[len(words)-1])
	words = c.y.Bits()
	for _, word := range words[:len(words)-1] {
		fmt.Printf("%#x, ", word)
	}
	fmt.Printf("%#x}}\n\n", words[len(words)-1])
}

func (c *gfP2) PrintY() {
	fmt.Print("&gfP{")
	words := c.y.Bits()
	for _, word := range words[:len(words)-1] {
		fmt.Printf("%#x, ", word)
	}
	fmt.Printf("%#x}\n\n", words[len(words)-1])
}

func (c *gfP2) PrintX() {
	fmt.Print("&gfP{")
	words := c.x.Bits()
	for _, word := range words[:len(words)-1] {
		fmt.Printf("%#x, ", word)
	}
	fmt.Printf("%#x}\n\n", words[len(words)-1])
}
