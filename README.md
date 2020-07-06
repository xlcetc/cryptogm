# cryptogm in golang

An implementation of china crypto standards written in golang. This package includes sm2,sm3 and sm4 algorithms.
All algorithms have good performance with some optimization.
# Install 

```
go get github.com/xlcetc/cryptogm
```

# Benchmark

CPU: intel core i7-7700 @3.6GHz.

## sm2

```
BenchmarkSign-8               	   	     19392 ns/op 
BenchmarkVerify-8             	   	     30326 ns/op 
BenchmarkSignWithDigest-8     	   	     16701 ns/op 
BenchmarkVerifyWithDigest-8   	   	     26742 ns/op 
BenchmarkSignWithASN1-8       	   	     21251 ns/op 
BenchmarkVerifyWithASN1-8     	   	     30390 ns/op 
```

## sm3

```
BenchmarkHash8Bytes-8   	 220   ns/op	      36.44  MB/s
BenchmarkHash1K-8       	 2815  ns/op	      363.71 MB/s
BenchmarkHash8K-8       	 20422 ns/op	      401.13 MB/s
```

## sm4

```
BenchmarkSm4Ecb8Bytes-8       	623   ns/op	  12.83  MB/s
BenchmarkSm4Ecb1K-8             10526 ns/op	  97.29  MB/s
BenchmarkSm4Ecb8K-8        	80692 ns/op	  101.52 MB/s
BenchmarkSm4Cbc8Bytes-8         664   ns/op	  12.05  MB/s
BenchmarkSm4Cbc1K-8             12299 ns/op	  83.26  MB/s
BenchmarkSm4Cbc8K-8             95395 ns/op	  85.87  MB/s
```
