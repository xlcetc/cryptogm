package main

import (
	"fmt"
	"log"
	"math/big"
)

func bigFromBase10(s string) *big.Int {
	n, _ := new(big.Int).SetString(s, 10)
	return n
}

func mulPoly(coeffs []int64, x *big.Int) *big.Int {
	powers := make([]*big.Int, len(coeffs))

	acc := new(big.Int).SetInt64(1)
	for i, _ := range powers {
		powers[i] = new(big.Int).Set(acc)
		acc.Mul(acc, x)
	}

	acc.SetInt64(0)
	temp := new(big.Int)
	for i, _ := range powers {
		temp.SetInt64(coeffs[i]).Mul(temp, powers[i])
		acc.Add(acc, temp)
	}

	return acc
}

func printWords(in *big.Int) {
	words := in.Bits()

	for _, word := range words[:len(words)-1] {
		fmt.Printf("%#x, ", word)
	}
	fmt.Printf("%#x}\n\n", words[len(words)-1])
}

var (
	u       = bigFromBase10("6518589491078791937")
	sm9u    = bigFromBase10("6917529027646912906")  //600000000058f98a
	bitSize = uint(64 * 4)
)

func genpara() {
	fmt.Println("// u is the BN parameter that determines the prime.")
	fmt.Printf("var u = bigFromBase10(\"%v\")\n\n", u)

	p := mulPoly([]int64{1, 6, 24, 36, 36}, u)
	fmt.Println("// p is a prime over which we form a basic field: 36u⁴+36u³+24u²+6u+1.")
	fmt.Printf("var p = bigFromBase10(\"%v\")\n\n", p)
	if !p.ProbablyPrime(20) {
		log.Fatal("p not prime")
	}

	Order := mulPoly([]int64{1, 6, 18, 36, 36}, u)
	fmt.Println("// Order is the number of elements in both G₁ and G₂: 36u⁴+36u³+18u²+6u+1.")
	fmt.Printf("var Order = bigFromBase10(\"%v\")\n\n", Order)
	if !Order.ProbablyPrime(20) {
		log.Fatal("Order not prime")
	}

	// Create algebraic constants.

	// Can we build an imaginary extension
	temp1 := new(big.Int).SetInt64(1)
	temp1.Sub(p, temp1).Rsh(temp1, 1)
	if temp1.Bit(0) != 1 {
		log.Fatal("cannot build imaginary extension")
	}

	xi := newGFp2(p)
	xi.x.SetInt64(1)
	xi.y.SetInt64(3)

	exp := big.NewInt(1)
	exp.Sub(p, exp)
	if new(big.Int).Mod(exp, big.NewInt(6)).Sign() != 0 {
		log.Fatal("not divis by 6")
	}
	exp.Div(exp, big.NewInt(6))
	xi1 := newGFp2(p).Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiToPMinus1Over6 is ξ^((p-1)/6) where ξ = i+3.")
	fmt.Print("var xiToPMinus1Over6 = ")
	xi1.Println()

	exp.SetInt64(1).Sub(p, exp).Div(p, big.NewInt(3))
	xi2 := newGFp2(p).Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiToPMinus1Over3 is ξ^((p-1)/3) where ξ = i+3.")
	fmt.Print("var xiToPMinus1Over3 = ")
	xi2.Println()

	exp.SetInt64(1).Sub(p, exp).Div(p, big.NewInt(2))
	xi3 := newGFp2(p).Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiToPMinus1Over2 is ξ^((p-1)/2) where ξ = i+3.")
	fmt.Print("var xiToPMinus1Over2 = ")
	xi3.Println()

	temp2 := new(big.Int).Mul(p, p)

	exp.SetInt64(1).Sub(temp2, exp).Div(exp, big.NewInt(3))
	xi4 := newGFp2(p).Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiToPSquaredMinus1Over3 is ξ^((p²-1)/3) where ξ = i+3.")
	fmt.Print("var xiToPSquaredMinus1Over3 = ")
	xi4.PrintY()

	exp.SetInt64(1).Sub(temp2, exp).Add(exp, exp).Div(exp, big.NewInt(3))
	xi5 := newGFp2(p).Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiTo2PSquaredMinus2Over3 is ξ^((2p²-2)/3) where ξ = i+3 (a cubic root of unity, mod p).")
	fmt.Print("var xiTo2PSquaredMinus2Over3 = ")
	xi5.PrintY()

	exp.SetInt64(1).Sub(temp2, exp).Div(exp, big.NewInt(6))
	xi6 := newGFp2(p).Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiToPSquaredMinus1Over6 is ξ^((p²-1)/6) where ξ = i+3 (a cubic root of -1, mod p).")
	fmt.Print("var xiToPSquaredMinus1Over6 = ")
	xi6.PrintY()

	exp.SetInt64(1).Sub(p, exp).Add(exp, exp).Div(exp, big.NewInt(3))
	xi7 := newGFp2(p).Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiTo2PMinus2Over3 is ξ^((2p-2)/3) where ξ = i+3.")
	fmt.Print("var xiTo2PMinus2Over3 = ")
	xi7.Println()

	//xi8 := new(gfP2)
	//xi8.p = p
	//xi8.x = big.NewInt(0)
	//xi8.y,_ = new(big.Int).SetString("2338e7dbf670f3602324553813044cae8580d5c665af30b5887f568e3cb7f583",16)
	//xi9 := xi8.MontEncode(bitSize)
	//xi9.PrintY()

	// Create constants for montgomery multiplication.
	fmt.Println("// p2 is p, represented as little-endian 64-bit words.")
	fmt.Printf("var p2 = [%v]uint64{", bitSize/64)
	printWords(p)

	pMinusTwo := big.NewInt(2)
	pMinusTwo.Sub(p, pMinusTwo)
	fmt.Println("// pMinusTwo is p-2.")
	fmt.Printf("var pMinusTwo = [%v]uint64{", bitSize/64)
	printWords(pMinusTwo)

	R := big.NewInt(1)
	R.Lsh(R, bitSize)

	np := new(big.Int).Set(p)
	np.ModInverse(np, R).Neg(np).Mod(np, R)
	fmt.Printf("// np is the negative inverse of p, mod 2^%v.\n", bitSize)
	fmt.Printf("var np = [%v]uint64{", bitSize/64)
	printWords(np)

	rN1 := new(big.Int).Set(R)
	rN1.Mod(rN1, p).ModInverse(rN1, p)
	fmt.Printf("// rN1 is R^-1 where R = 2^%v mod p.\n", bitSize)
	fmt.Print("var rN1 = &gfP{")
	printWords(rN1)

	r2 := new(big.Int).Mul(R, R)
	r2.Mod(r2, p)
	fmt.Printf("// r2 is R^2 where R = 2^%v mod p.\n", bitSize)
	fmt.Printf("var r2 = &gfP{")
	printWords(r2)

	r3 := new(big.Int).Mul(R, R)
	r3.Mul(r3, R).Mod(r3, p)
	fmt.Printf("// r3 is R^3 where R = 2^%v mod p.\n", bitSize)
	fmt.Printf("var r3 = &gfP{")
	printWords(r3)

	sixPlusTwo := new(big.Int).Mul(u, big.NewInt(6))
	sixPlusTwo.Add(sixPlusTwo, big.NewInt(2))
	naf := make([]int8, 0)
	for sixPlusTwo.Sign() != 0 {
		if sixPlusTwo.Bit(0) == 1 {
			x := 2 - int8(2*sixPlusTwo.Bit(1)+sixPlusTwo.Bit(0))

			naf = append(naf, x)
			sixPlusTwo.Sub(sixPlusTwo, big.NewInt(int64(x)))
		} else {
			naf = append(naf, 0)
		}
		sixPlusTwo.Rsh(sixPlusTwo, 1)
	}
	fmt.Println("// sixuPlus2NAF is 6u+2 in non-adjacent form.")
	fmt.Printf("var sixuPlus2NAF = %#v\n\n", naf)
}

func gensm9para() {
	fmt.Println("// u is the BN parameter that determines the prime.")
	fmt.Printf("var u = bigFromBase10(\"%v\")\n\n", sm9u)

	p := mulPoly([]int64{1, 6, 24, 36, 36}, sm9u)
	fmt.Println("// p is a prime over which we form a basic field: 36u⁴+36u³+24u²+6u+1.")
	fmt.Printf("var p = bigFromBase10(\"%v\")\n\n", p)
	if !p.ProbablyPrime(20) {
		log.Fatal("p not prime")
	}

	Order := mulPoly([]int64{1, 6, 18, 36, 36}, sm9u)
	fmt.Println("// Order is the number of elements in both G₁ and G₂: 36u⁴+36u³+18u²+6u+1.")
	fmt.Printf("var Order = bigFromBase10(\"%v\")\n\n", Order)
	if !Order.ProbablyPrime(20) {
		log.Fatal("Order not prime")
	}

	// Create algebraic constants.
	xi := newGFp2(p)
	b,_ := new(big.Int).SetString("5b2000000151d378eb01d5a7fac763a290f949a58d3d776df2b7cd93f1a8a2be",16)
	xi.x.Set(b)
	fmt.Println("//ξ=bi, where b = (-1/2) mod p (in montEncode form).")
	fmt.Print("var bi = ")
	xi.MontEncode(bitSize)
	xi.PrintX()

	exp := big.NewInt(1)
	exp.Sub(p, exp)
	if new(big.Int).Mod(exp, big.NewInt(6)).Sign() != 0 {
		log.Fatal("not divis by 6")
	}
	exp.Div(exp, big.NewInt(6))
	xi1 := newGFp2(p).Sm9Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiToPMinus1Over6 is ξ^((p-1)/6) where ξ = bi.")
	fmt.Print("var xiToPMinus1Over6 = ")
	xi1.PrintY()

	exp.SetInt64(1).Sub(p, exp).Div(p, big.NewInt(3))
	xi2 := newGFp2(p).Sm9Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiToPMinus1Over3 is ξ^((p-1)/3) where ξ = bi.")
	fmt.Print("var xiToPMinus1Over3 = ")
	xi2.PrintY()

	exp.SetInt64(1).Sub(p, exp).Div(p, big.NewInt(2))
	xi3 := newGFp2(p).Sm9Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiToPMinus1Over2 is ξ^((p-1)/2) where ξ = bi.")
	fmt.Print("var xiToPMinus1Over2 = ")
	xi3.PrintY()

	temp2 := new(big.Int).Mul(p, p)

	exp.SetInt64(1).Sub(temp2, exp).Div(exp, big.NewInt(3))
	xi4 := newGFp2(p).Sm9Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiToPSquaredMinus1Over3 is ξ^((p²-1)/3) where ξ = bi.")
	fmt.Print("var xiToPSquaredMinus1Over3 = ")
	xi4.PrintY()

	exp.SetInt64(1).Sub(temp2, exp).Add(exp, exp).Div(exp, big.NewInt(3))
	xi5 := newGFp2(p).Sm9Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiTo2PSquaredMinus2Over3 is ξ^((2p²-2)/3) where ξ = bi.")
	fmt.Print("var xiTo2PSquaredMinus2Over3 = ")
	xi5.PrintY()

	exp.SetInt64(1).Sub(temp2, exp).Div(exp, big.NewInt(6))
	xi6 := newGFp2(p).Sm9Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiToPSquaredMinus1Over6 is ξ^((p²-1)/6) where ξ = bi.")
	fmt.Print("var xiToPSquaredMinus1Over6 = ")
	xi6.PrintY()

	exp.SetInt64(1).Sub(p, exp).Add(exp, exp).Div(exp, big.NewInt(3))
	xi7 := newGFp2(p).Sm9Exp(xi, exp).MontEncode(bitSize)
	fmt.Println("// xiTo2PMinus2Over3 is ξ^((2p-2)/3) where ξ = bi.")
	fmt.Print("var xiTo2PMinus2Over3 = ")
	xi7.PrintY()

	// Create constants for montgomery multiplication.
	fmt.Println("// p2 is p, represented as little-endian 64-bit words.")
	fmt.Printf("var p2 = [%v]uint64{", bitSize/64)
	printWords(p)

	pMinusTwo := big.NewInt(2)
	pMinusTwo.Sub(p, pMinusTwo)
	fmt.Println("// pMinusTwo is p-2.")
	fmt.Printf("var pMinusTwo = [%v]uint64{", bitSize/64)
	printWords(pMinusTwo)

	R := big.NewInt(1)
	R.Lsh(R, bitSize)

	np := new(big.Int).Set(p)
	np.ModInverse(np, R).Neg(np).Mod(np, R)
	fmt.Printf("// np is the negative inverse of p, mod 2^%v.\n", bitSize)
	fmt.Printf("var np = [%v]uint64{", bitSize/64)
	printWords(np)

	rN1 := new(big.Int).Set(R)
	rN1.Mod(rN1, p).ModInverse(rN1, p)
	fmt.Printf("// rN1 is R^-1 where R = 2^%v mod p.\n", bitSize)
	fmt.Print("var rN1 = &gfP{")
	printWords(rN1)

	r2 := new(big.Int).Mul(R, R)
	r2.Mod(r2, p)
	fmt.Printf("// r2 is R^2 where R = 2^%v mod p.\n", bitSize)
	fmt.Printf("var r2 = &gfP{")
	printWords(r2)

	r3 := new(big.Int).Mul(R, R)
	r3.Mul(r3, R).Mod(r3, p)
	fmt.Printf("// r3 is R^3 where R = 2^%v mod p.\n", bitSize)
	fmt.Printf("var r3 = &gfP{")
	printWords(r3)

	sixPlusTwo := new(big.Int).Mul(sm9u, big.NewInt(6))
	sixPlusTwo.Add(sixPlusTwo, big.NewInt(2))
	naf := make([]int8, 0)
	for sixPlusTwo.Sign() != 0 {
		if sixPlusTwo.Bit(0) == 1 {
			x := 2 - int8(2*sixPlusTwo.Bit(1)+sixPlusTwo.Bit(0))

			naf = append(naf, x)
			sixPlusTwo.Sub(sixPlusTwo, big.NewInt(int64(x)))
		} else {
			naf = append(naf, 0)
		}
		sixPlusTwo.Rsh(sixPlusTwo, 1)
	}
	fmt.Println("// sixuPlus2NAF is 6u+2 in non-adjacent form.")
	fmt.Printf("var sixuPlus2NAF = %#v\n\n", naf)
}

func main() {
	//genpara()
	gensm9para()
}
