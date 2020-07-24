// Copyright 2020 cetc-30. All rights reserved.
// Use of this source code is governed by a BSD-style
// license that can be found in the LICENSE file.
// Author:Jiang Mengshan
// Email:jiangmengshan@cetcxl.com

#include "textflag.h"

#define xorm(p1, p2)    \
    XORL p1, p2;  \
    MOVL p2, p1

#define XDWORD0 Y4
#define XDWORD1 Y5
#define XDWORD2 Y6
#define XDWORD3 Y7

#define XWORD0 X4
#define XWORD1 X5
#define XWORD2 X6
#define XWORD3 X7

#define XTMP0 Y0
#define XTMP1 Y1
#define XTMP2 Y2
#define XTMP3 Y3
#define XTMP4 Y8
#define XTMP5 Y11

#define XFER  Y9

#define BYTE_FLIP_MASK 	Y13 // mask to convert LE -> BE
#define X_BYTE_FLIP_MASK X13

#define NUM_BYTES DX
#define INP	DI

#define CTX SI // Beginning of digest in memory (a, b, c, ... , h)

#define a AX
#define b BX
#define c CX
#define d R8
#define e DX
#define f R9
#define g R10
#define h R11
#define TBL BP

#define SRND SI // SRND is same register as CTX

#define offset R12

#define y0 R13
#define y1 R14
#define y2 R15
#define y3 DI

// Offsets
#define XFER_SIZE 2*64*4
#define _XMM_SAVE_SIZE 2*64*4
#define INP_END_SIZE 8
#define INP_SIZE 8

#define _XFER 0
#define _XMM_SAVE _XFER + _XMM_SAVE_SIZE
#define _INP_END _XMM_SAVE + XFER_SIZE
#define _INP _INP_END + INP_END_SIZE
#define STACK_SIZE _INP + INP_SIZE


#define First_16_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3) \
    ;                                          \ //  1/4
    MOVL a, y1;                                \ // 
    VPALIGNR $12, XDWORD0, XDWORD1, XTMP0;     \ //  #--1--(W[-13],W[-12],W[-11],W[-10])
    RORXL $20, a, y0;                          \ //  #ROTATELEFT(A,12)
    XORL b, y1;                                \ // 
    MOVL y0, y2;                               \ //  #ROTATELEFT(A,12)
    VPSLLD $7, XTMP0, XTMP1;                   \ //  #--2--((W[-13],W[-12],W[-11],W[-10]) << 7)
    ADDL e, y0;                                \ // 
    XORL c, y1;                                \ //  #FF0(A, B, C)
    ADDL 0(TBL), y0;                           \ //  #offset
    ADDL $4, TBL;                              \
    MOVL e, y3;                                \ // 
    RORXL $25, y0, y0;                         \ //  #ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    VPSRLD $25, XTMP0, XTMP2;                  \ //  #--3--((W[-13],W[-12],W[-11],W[-10] >> 25)
    XORL f, y3;                                \ // 
    XORL y0, y2;                               \ //  #ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL d, y1;                                \ //  #FF0(A, B, C)+D
    VPXOR XTMP1, XTMP2, XTMP0;                 \ //  #--4--((W[-13],W[-12],W[-11],W[-10] <<< 17)
    RORXL $23, b, b;                           \ //  #ROTATELEFT(B,9);
    ADDL y1, y2;                               \ //  #FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL h, y0;                                \ //  #H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL (_XFER+0*4)(SP)(SRND*1), y2;          \ //  #FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    XORL g, y3;                                \ //  #GG0(E,F,G)
    ADDL (_XMM_SAVE+0*4)(SP)(SRND*1), y0;      \ //  #H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    VPALIGNR $8, XDWORD2, XDWORD3, XTMP2;      \ //  #--5--(W[-6],W[-5],W[-4],W[-3])
    RORXL $13, f, f;                           \ //  #ROTATELEFT(F,19);
    ADDL y0, y3;                               \ //  #GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    VPXOR XTMP2, XTMP0, XTMP0;                 \ //  #--6--(W[-6],W[-5],W[-4],W[-3])^((W[-13],W[-12],W[-11],W[-10] <<< 17)
    RORXL $23, y3, h;                          \ // 
    MOVL y2, d;                                \ // 
    VPSHUFD $57, XDWORD3, XTMP1;               \ //  #--7--(W[-3],W[-2],W[-1],W[0])
    XORL y3, h;                                \ // 
    RORXL $15, y3, y1;                         \ // 
    VPSLLD $15, XTMP1, XTMP2;                  \ //  #--8--((W[-3],W[-2],W[-1],W[0]) << 15)
    XORL y1, h;                                \ //  #P0(GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j])
    ;                                          \ // 
    ;                                          \ //  2/4
    MOVL d, y1;                                \      
    RORXL $20, d, y0;                          \ // #ROTATELEFT(A,12)
    XORL a, y1;                                \      
    MOVL y0, y2;                               \ // #ROTATELEFT(A,12)
    VPSRLD $17, XTMP1, XTMP1;                  \ // #--9--((W[-3],W[-2],W[-1],W[0]) >> 17)
    ADDL h, y0;                                \ //
    XORL b, y1;                                \ // #FF0(A, B, C)
    ADDL 0(TBL), y0;                           \ // #offset
    ADDL $4, TBL;                              \
    VPXOR XTMP1, XTMP2, XTMP1;                 \ // #--10--((W[-3],W[-2],W[-1],W[0]) <<< 15)
    MOVL h, y3;                                \ //
    RORXL $25, y0, y0;                         \ // #ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL c, y1;                                \ // #FF0(A, B, C)+D
    VPALIGNR $12, XDWORD1, XDWORD2, XTMP2;     \ // #--11--(W[-9],W[-8],W[-7],W[-6])
    XORL e, y3;                                \ //
    XORL y0, y2;                               \ // #ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    RORXL $23, a, a;                           \ // #ROTATELEFT(B,9);
    VPXOR XDWORD0, XTMP2, XTMP2;               \ // #--12--(W[-9],W[-8],W[-7],W[-6]) ^ (W[-16],W[-15],W[-14],W[-13])
    ADDL y1, y2;                               \ // #FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL g, y0;                                \ // #H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL (_XFER+1*4)(SP)(SRND*1), y2;          \ // #FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    VPXOR XTMP2, XTMP1, XTMP1;                 \ // #--13--(W[-9],W[-8],W[-7],W[-6]) ^ (W[-16],W[-15],W[-14],W[-13])^((W[-3],W[-2],W[-1],W[0]) <<< 15)
    XORL f, y3;                                \ // #GG0(E,F,G)
    ADDL (_XMM_SAVE+1*4)(SP)(SRND*1),y0;       \ // #H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, e, e;                           \ // #ROTATELEFT(F,19);
    VPSLLD $15, XTMP1, XTMP3;                  \ // #--14--P1(x)--> X << 15
    ADDL y0, y3;                               \ // #GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    MOVL y2, c;                                \ //
    RORXL $23, y3, g;                          \ //
    VPSRLD $17, XTMP1, XTMP4;                  \ // #--15--P1(x)--> X >> 17
    XORL y3, g;                                \ //
    RORXL $15, y3, y1;                         \ //
    VPXOR XTMP3, XTMP4, XTMP3;                 \ // #--16--P1(x)--> x <<< 15
    XORL y1, g;                                \ // #P0(GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j])  
    ;                                          \ //
    ;                                          \ // 3/4
    MOVL c, y1;                                \ //
    VPSLLD $23, XTMP1, XTMP4;                  \ // #--17--P1(x)--> X << 23
    RORXL $20, c, y0;                          \ // #ROTATELEFT(A,12)
    XORL d, y1;                                \ //
    MOVL y0, y2;                               \ // #ROTATELEFT(A,12)
    VPSRLD $9, XTMP1, XTMP5;                   \ // #--18--P1(x)--> X >> 9
    ADDL g, y0;                                \ //
    XORL a, y1;                                \ // #FF0(A, B, C)
    VPXOR XTMP5, XTMP4, XTMP4;                 \ // #--19--P1(x)--> X <<< 23
    ADDL 0(TBL), y0;                           \ // #offset
    ADDL $4, TBL;                              \
    MOVL g, y3;                                \ //
    RORXL $23, d, d;                           \ // #ROTATELEFT(B,9);
    VPXOR XTMP3, XTMP1, XTMP1;                 \ // #--20--P1(x)--> x ^ (x <<< 15)
    RORXL $25, y0, y0;                         \ // #ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL b, y1;                                \ // #FF0(A, B, C)+D
    XORL h, y3;                                \ //
    VPXOR XTMP4, XTMP1, XTMP1;                 \ // #--21--P1(x)==x ^ (x <<< 15) ^ (X <<< 23)
    XORL y0, y2;                               \ // #ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL f, y0;                                \ // #H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    VPXOR XTMP0, XTMP1, XTMP1;                 \ // #--22--(W[0],W[1],W[2],W[3])
    ADDL y1, y2;                               \ // #FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    XORL e, y3;                                \ // #GG0(E,F,G)
    ADDL (_XFER+2*4)(SP)(SRND*1), y2;          \ // #FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    VPSHUFD $0,XTMP1,XTMP3;                    \ // #--23--(W[0],W[0],W[0],W[0])
    ADDL (_XMM_SAVE+2*4)(SP)(SRND*1),y0;       \ // #H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    MOVL y2, b;                                \ //
    VPSLLQ $15, XTMP3, XTMP3;                  \ // #--24--(W[0],W[0] <<< 15,W[0],W[0])
    ADDL y0, y3;                               \ // #GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, h, h;                           \ // #ROTATELEFT(F,19);
    VPSHUFD $85,XTMP3,XTMP3 ;                  \ // #--25--
    RORXL $23, y3, f;                          \ //
    XORL y3, f;                                \ //
    VPXOR XTMP3, XTMP2, XTMP2;                 \ // #--26--((W[0] <<< 15) ^ XTMP2,W[0],W[0],W[0])
    RORXL $15, y3, y1;                         \ //
    VPSHUFD $255,XTMP2,XTMP3;                  \ // #--27--(X,X,X,X)
    XORL y1, f;                                \ // #P0(GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j])
    ;                                          \ //
    ;                                          \ // 4/4
    MOVL b, y1;                                \ //
    VPSLLQ $15, XTMP3, XTMP4;                  \ // #--28--(X,X <<< 15,X,X)
    RORXL $20, b, y0;                          \ // #ROTATELEFT(A,12)
    XORL c, y1;                                \ //
    VPSLLQ $23, XTMP3, XTMP5;                  \ // #--29--(X,X <<< 23,X,X)
    MOVL y0, y2;                               \ // #ROTATELEFT(A,12)
    MOVL f, y3;                                \ //
    ADDL f, y0;                                \ //
    VPXOR XTMP5,XTMP4, XTMP4;                  \ // #--30--(X,(X <<< 23) ^ (X <<< 15),X,X)
    XORL d, y1;                                \ // #FF0(A, B, C)
    ADDL 0(TBL), y0;                           \ // #offset
    ADDL $4, TBL;                              \
    XORL g, y3;                                \ //
    VPSHUFD $85,XTMP4,XTMP4;                   \ // #--31--((X <<< 23) ^ (X <<< 15),(X <<< 23) ^ (X <<< 15),(X <<< 23) ^ (X <<< 15),(X <<< 23) ^ (X <<< 15))
    RORXL $23, c, c;                           \ // #ROTATELEFT(B,9);
    RORXL $25, y0, y0;                         \ // #ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    XORL h, y3;                                \ // #GG0(E,F,G)
    VPXOR   XTMP4,XTMP3,XTMP3;                 \ // #--32-((X <<< 23) ^ (X <<< 15) ^ X,(X <<< 23) ^ (X <<< 15) ^ X,(X <<< 23) ^ (X <<< 15) ^ X,(X <<< 23) ^ (X <<< 15) ^ X)
    XORL y0, y2;                               \ // #ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL a, y1;                                \ // #FF0(A, B, C)+D
    ADDL e, y0;                                \ // #H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    VPXOR XTMP3, XTMP0, XTMP0;                 \ // #--33--
    ADDL y1, y2;                               \ // #FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL (_XMM_SAVE+3*4)(SP)(SRND*1),y0;       \ // #H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    ADDL (_XFER+3*4)(SP)(SRND*1), y2;          \ // #FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    VPALIGNR $12,XTMP0, XTMP1, XTMP0;          \ // #--34--
    ADDL y0, y3;                               \ // #GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    MOVL y2, a;                                \ //
    RORXL $23, y3, e;                          \ //
    VPSHUFD $57, XTMP0, XTMP0;                 \ // #--35--
    RORXL $13, g, g;                           \ // #ROTATELEFT(F,19);
    XORL y3, e;                                \ //
    RORXL $15, y3, y1;                         \ //
    VMOVDQA XTMP0, XDWORD0;                    \ // #--36--
    XORL y1, e

#define Second_36_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3) \
    ;                                          \ // 1/4
    VPALIGNR $12, XDWORD0, XDWORD1, XTMP0;     \ // #--1--(W[-13],W[-12],W[-11],W[-10])
    MOVL b, y1;                                \ //
    MOVL c, y2;                                \ //
    RORXL $20, a, y0;                          \ // #ROTATELEFT(A,12)
    VPSLLD $7, XTMP0, XTMP1;                   \ // #--2--((W[-13],W[-12],W[-11],W[-10]) << 7)
    ORL c, y1;                                 \ // #(B|C)
    ANDL b, y2;                                \ // #(B&C)
    MOVL y0, y3;                               \ // #ROTATELEFT(A,12)
    ANDL a, y1;                                \ // #A&(B|C)
    VPSRLD $25, XTMP0, XTMP2;                  \ // #--3--((W[-13],W[-12],W[-11],W[-10] >> 25)
    RORXL $23, b, b;                           \ // #ROTATELEFT(B,9);
    ADDL e, y0;                                \ // 
    ORL y2, y1;                                \ // #FF1(x,y,z)
    VPXOR XTMP1, XTMP2, XTMP0;                 \ // #--4--((W[-13],W[-12],W[-11],W[-10] <<< 17)
    ADDL 0(TBL), y0;                           \ // #offset
    ADDL $4, TBL;                              \
    ADDL d, y1;                                \ // #FF1(A, B, C)+D
    MOVL f, y2;                                \ // 
    RORXL $25, y0, y0;                         \ // #SS1=ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    VPALIGNR $8, XDWORD2, XDWORD3, XTMP2;      \ // #--5--(W[-6],W[-5],W[-4],W[-3])
    XORL g, y2;                                \ // 
    XORL y0, y3;                               \ // #SS2=ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    VPXOR XTMP2, XTMP0, XTMP0;                 \ // #--6--(W[-6],W[-5],W[-4],W[-3])^((W[-13],W[-12],W[-11],W[-10] <<< 17)
    ADDL y1, y3;                               \ // #FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL h, y0;                                \ // #H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ANDL e, y2;                                \ // 
    ADDL (_XFER+0*4)(SP)(SRND*1), y3;          \ // #FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    VPSHUFD $57, XDWORD3,XTMP1;                \ // #--7--(W[-3],W[-2],W[-1],W[0])
    ADDL (_XMM_SAVE+0*4)(SP)(SRND*1), y0;      \ // #H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    XORL g, y2;                                \ // 
    MOVL y3, d;                                \ // 
    RORXL $13, f, f;                           \ // #ROTATELEFT(F,19);
    ADDL y2, y0;                               \ // #GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    VPSLLD $15, XTMP1, XTMP2;                  \ // #--8--((W[-3],W[-2],W[-1],W[0]) << 15)
    MOVL a, y1;                                \ //
    RORXL $23, y0, h;                          \ // 
    RORXL $15, y0, y3;                         \ // 
    XORL y0, h;                                \ // 
    VPSRLD $17, XTMP1, XTMP1;                  \ // #--9--((W[-3],W[-2],W[-1],W[0]) >> 17)
    MOVL b, y2;                                \ //
    XORL y3, h;                                \ // #P0(GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j])
    ;                                          \ // 
    ;                                          \ // 2/4
    VPXOR XTMP1, XTMP2, XTMP1;                 \ // #--10--((W[-3],W[-2],W[-1],W[0]) <<< 15)
    RORXL $20, d, y0;                          \ // #ROTATELEFT(A,12)
    ORL b, y1;                                 \ // #(B|C)
    VPALIGNR $12, XDWORD1, XDWORD2, XTMP2;     \ // #--11--(W[-9],W[-8],W[-7],W[-6])
    ANDL a, y2;                                \ // #(B&C)
    MOVL y0, y3;                               \ // #ROTATELEFT(A,12)
    ANDL d, y1;                                \ // #A&(B|C)
    VPXOR XDWORD0, XTMP2, XTMP2;               \ // #--12--(W[-9],W[-8],W[-7],W[-6]) ^ (W[-16],W[-15],W[-14],W[-13])
    RORXL $23, a, a;                           \ // #ROTATELEFT(B,9);
    ADDL h, y0;                                \ // 
    ORL y2, y1;                                \ // #FF1(x,y,z)
    VPXOR XTMP2, XTMP1, XTMP1;                 \ // #--13--(W[-9],W[-8],W[-7],W[-6]) ^ (W[-16],W[-15],W[-14],W[-13])^((W[-3],W[-2],W[-1],W[0]) <<< 15)
    ADDL 0(TBL), y0;                           \ // #offset
    ADDL $4, TBL;                              \ //
    ADDL c, y1;                                \ //#FF1(A, B, C)+D
    VPSLLD $15, XTMP1, XTMP3;                  \ //#--14--P1(x)--> X << 15
    RORXL $25, y0, y0;                         \ //#SS1=ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    MOVL e, y2;                                \ //
    VPSRLD $17, XTMP1, XTMP4;                  \ //#--15--P1(x)--> X >> 17
    XORL y0, y3;                               \ //#SS2=ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    XORL f, y2;                                \ //
    ADDL g, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    VPXOR XTMP3, XTMP4, XTMP3;                 \ //#--16--P1(x)--> x <<< 15
    MOVL e, y1;                                \ //
    ANDL h, y2;                                \ //
    ADDL (_XMM_SAVE+1*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    VPSLLD $23, XTMP1, XTMP4;                  \ //#--17--P1(x)--> X << 23
    XORL f, y2;                                \ //
    ADDL (_XFER+1*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    RORXL $13, e, e;                           \ //#ROTATELEFT(F,19);
    MOVL y3, c;                                \ //
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    VPSRLD $9, XTMP1, XTMP5;                   \ //#--18--P1(x)--> X >> 9
    MOVL d, y1;                                \ //
    RORXL $23, y0, g;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, g;                                \ //
    VPXOR XTMP5, XTMP4, XTMP4;                 \ //#--19--P1(x)--> X <<< 23
    MOVL a, y2;                                \ //
    XORL y3, g;                                \ //
    ;                                          \ //
    ;                                          \ //3/4
    RORXL $20, c, y0;                          \ //#ROTATELEFT(A,12)
    VPXOR XTMP3, XTMP1, XTMP1;                 \ //#--20--P1(x)--> x ^ (x <<< 15)
    ORL a, y1;                                 \ //#(B|C)
    ANDL d, y2;                                \ //#(B&C)
    MOVL y0, y3;                               \ //#ROTATELEFT(A,12)
    ANDL c, y1;                                \ //#A&(B|C)
    VPXOR XTMP4, XTMP1, XTMP1;                 \ //#--21--P1(x)==x ^ (x <<< 15) ^ (X <<< 23)
    RORXL $23, d, d;                           \ //#ROTATELEFT(B,9);
    ADDL g, y0;                                \ //
    ORL y2, y1;                                \ //#FF1(x,y,z)
    VPXOR XTMP0, XTMP1, XTMP1;                 \ //#--22--(W[0],W[1],W[2],W[3])
    ADDL 0(TBL), y0;                           \ //// #offset
    ADDL $4, TBL;                              \
    MOVL h, y2;                                \ //
    ADDL b, y1;                                \ //#FF1(A, B, C)+D
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    VPSHUFD $0,XTMP1,XTMP3;                    \ //#--23--(W[0],W[0],W[0],W[0])
    XORL e, y2;                                \ //
    XORL y0, y3;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL f, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    VPSLLQ $15, XTMP3, XTMP3;                  \ //#--24--(W[0],W[0] <<< 15,W[0],W[0])
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ANDL g, y2;                                \ //
    ADDL (_XFER+2*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    VPSHUFD $85,XTMP3,XTMP3;                   \ //#--25--
    ADDL (_XMM_SAVE+2*4)(SP)(SRND*1),y0;       \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    XORL e, y2;                                \ //
    MOVL y3, b;                                \ //
    VPXOR XTMP3, XTMP2, XTMP2;                 \ //#--26--((W[0] <<< 15) ^ XTMP2,W[0],W[0],W[0])
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, h, h;                           \ //#ROTATELEFT(F,19)
    MOVL c, y1;                                \ //
    RORXL $23, y0, f;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, f;                                \ //
    VPSHUFD $255,XTMP2,XTMP3;                  \ //#--27--(X,X,X,X)
    MOVL d, y2;                                \ //
    XORL y3, f;                                \ //
    ;                                          \ //
    ;                                          \ //4/4
    VPSLLQ $15, XTMP3, XTMP4;                  \ //#--28--(X,X <<< 15,X,X)
    RORXL $20, b, y0;                          \ //#ROTATELEFT(A,12)
    ORL d, y1;                                 \ //#(B|C)
    VPSLLQ $23, XTMP3, XTMP5;                  \ //#--29--(X,X <<< 23,X,X)
    ANDL c, y2;                                \ //#(B&C)
    MOVL y0, y3;                               \ //#ROTATELEFT(A,12)
    ANDL b, y1;                                \ //#A&(B|C)
    VPXOR XTMP5,XTMP4, XTMP4;                  \ //#--30--(X,(X <<< 23) ^ (X <<< 15),X,X)
    RORXL $23, c, c;                           \ //#ROTATELEFT(B,9);
    ADDL f, y0;                                \ //
    ORL y2, y1;                                \ //#FF1(x,y,z)
    VPSHUFD $85, XTMP4, XTMP4;                 \ //#--31--((X <<< 23) ^ (X <<< 15),(X <<< 23) ^ (X <<< 15),(X <<< 23) ^ (X <<< 15),(X <<< 23) ^ (X <<< 15))
    ADDL 0(TBL), y0;                           \ //// #offset
    ADDL $4, TBL;                              \
    MOVL g, y2;                                \ //
    ADDL a, y1;                                \ //#FF1(A, B, C)+D
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    VPXOR 	XTMP4, XTMP3, XTMP3;               \ //#--32-((X <<< 23) ^ (X <<< 15) ^ X,(X <<< 23) ^ (X <<< 15) ^ X,(X <<< 23) ^ (X <<< 15) ^ X,(X <<< 23) ^ (X <<< 15) ^ X)
    XORL h, y2;                                \ //
    XORL y0, y3;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL e, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    VPXOR XTMP3, XTMP0, XTMP0;                 \ //#--33--
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ANDL f, y2;                                \ //
    ADDL (_XFER+3*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    VPALIGNR $12,XTMP0, XTMP1, XTMP0;          \ //#--34--
    XORL h, y2;                                \ //
    ADDL (_XMM_SAVE+3*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    MOVL y3, a;                                \ //
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    VPSHUFD $57, XTMP0, XTMP0;                 \ //#--35--
    RORXL $13, g, g;                           \ //#ROTATELEFT(F,19);
    RORXL $23, y0, e;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, e;                                \ //
    VMOVDQA XTMP0, XDWORD0;                    \ //#--36--
    XORL y3, e;                                \ //


#define Third_12_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h) \
    ;                                          \ //1/4
    MOVL b, y1;                                \ //
    RORXL $20, a, y0;                          \ //#ROTATELEFT(A,12)
    MOVL c, y2;                                \ //
    ORL c, y1;                                 \ //#(B|C)
    MOVL y0, y3;                               \ //#ROTATELEFT(A,12)
    ANDL b, y2;                                \ //#(B&C)
    ANDL a, y1;                                \ //#A&(B|C)
    ADDL e, y0;                                \ //
    ORL y2, y1;                                \ //#FF1(x,y,z)
    ADDL 0(TBL), y0;                           \ ////// #offset
    ADDL $4, TBL;                              \
    ADDL d, y1;                                \ //#FF1(A, B, C)+D
    MOVL f, y2;                                \ //
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    XORL g, y2;                                \ //
    XORL y0, y3;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL h, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL (_XMM_SAVE+0*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    ANDL e, y2;                                \ //
    ADDL (_XFER+0*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    RORXL $23, b, b	;                          \ //#ROTATELEFT(B,9);
    XORL g, y2;                                \ //
    MOVL y3, d;                                \ //
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, f, f;                           \ //#ROTATELEFT(F,19);
    MOVL a, y1;                                \ //
    RORXL $23, y0, h;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, h;                                \ //
    MOVL b, y2;                                \ //
    RORXL $20, d, y0;                          \ //#ROTATELEFT(A,12)
    XORL y3, h;                                \ //
    ;                                          \ //
    ;                                          \ //2/4
    ORL b, y1;                                 \ //#(B|C)
    MOVL y0, y3;                               \ //#ROTATELEFT(A,12)
    ANDL a, y2;                                \ //#(B&C)
    ANDL d, y1;                                \ //#A&(B|C)
    ADDL h, y0;                                \ //
    ORL y2, y1;                                \ //#FF1(x,y,z)
    ADDL 0(TBL), y0;                           \ ////// #offset
    ADDL $4, TBL;                              \
    ADDL c, y1;                                \ //#FF1(A, B, C)+D
    MOVL e, y2;                                \ //
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    XORL f, y2;                                \ //
    XORL y0, y3;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL g, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL (_XMM_SAVE+1*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    ANDL h, y2;                                \ //
    ADDL (_XFER+1*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    RORXL $23, a, a;                           \ //#ROTATELEFT(B,9);
    XORL f, y2;                                \ //
    MOVL y3, c;                                \ //
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, e, e;                           \ //#ROTATELEFT(F,19);
    MOVL d, y1;                                \ //
    RORXL $23, y0, g;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, g;                                \ //
    MOVL a, y2;                                \ //
    RORXL $20, c, y0;                          \ //#ROTATELEFT(A,12)
    XORL y3, g;                                \ //
    ;                                          \ //
    ;                                          \ //3/4
    ORL a, y1;                                 \ //#(B|C)
    MOVL y0, y3;                               \ //#ROTATELEFT(A,12)
    ANDL d, y2;                                \ //#(B&C)
    ANDL c, y1;                                \ //#A&(B|C)
    ADDL g, y0;                                \ //
    ORL y2, y1;                                \ //#FF1(x,y,z)
    ADDL 0(TBL), y0;                           \ ////// #offset
    ADDL $4, TBL;                              \
    ADDL b, y1;                                \ //#FF1(A, B, C)+D
    MOVL h, y2;                                \ //
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    XORL e, y2;                                \ //
    XORL y0, y3;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL f, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL (_XMM_SAVE+2*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    ANDL g, y2;                                \ //
    ADDL (_XFER+2*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    RORXL $23, d, d;                           \ //#ROTATELEFT(B,9);
    XORL e, y2;                                \ //
    MOVL y3, b;                                \ //
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, h, h;                           \ //#ROTATELEFT(F,19);
    MOVL c, y1;                                \ //
    RORXL $23, y0, f;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, f;                                \ //
    MOVL d, y2;                                \ //
    RORXL $20, b, y0;                          \ //#ROTATELEFT(A,12)
    XORL y3, f;                                \ //
    ;                                          \ //
    ;                                          \ //4/4
    ORL d, y1;                                 \ //#(B|C)
    MOVL y0, y3;                               \ //#ROTATELEFT(A,12)
    ANDL c, y2;                                \ //#(B&C)
    ANDL b, y1;                                \ //#A&(B|C)
    ADDL f, y0;                                \ //
    ORL y2, y1;                                \ //#FF1(x,y,z)
    ADDL 0(TBL), y0;                           \ 
    ADDL $4, TBL;                              \ // offset
    ADDL a, y1;                                \ //#FF1(A, B, C)+D
    MOVL g, y2;                                \ //
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    XORL h, y2;                                \ //
    XORL y0, y3;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL e, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL (_XMM_SAVE+3*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    ANDL f, y2;                                \ //
    ADDL (_XFER+3*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    RORXL $23, c, c;                           \ //#ROTATELEFT(B,9);
    XORL h, y2;                                \ //
    MOVL y3, a;                                \ //
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, g, g;                           \ //#ROTATELEFT(F,19);
    RORXL $23, y0, e;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, e;                                \ //
    XORL y3, e;                                \ //



#define First_16_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h) \
    ;                                          \ //  1/4
    ;                                          \ 
    MOVL a, y1;                                \ //
    RORXL $20, a, y0;                          \ //#ROTATELEFT(A,12)
    MOVL e, y3;                                \ //
    XORL b, y1;                                \ //
    MOVL y0, y2;                               \ //#ROTATELEFT(A,12)
    ADDL e, y0;                                \ //
    XORL c, y1;                                \ //#FF0(A, B, C)
    ADDL 0(TBL), y0;                           \ 
    ADDL $4, TBL;                              \ // offset
    XORL f, y3;                                \ //
    ADDL d, y1;                                \ //#FF0(A, B, C)+D
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    RORXL $23, b,  b;                          \ //#ROTATELEFT(B,9);
    XORL y0, y2;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    XORL g, y3;                                \ //#GG0(E,F,G)
    ADDL y1, y2;                               \ //#FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL h, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL (_XFER+0*4)(SP)(SRND*1), y2;          \ //#FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    ADDL (_XMM_SAVE+0*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    MOVL y2, d;                                \ //
    ADDL y0, y3;                               \ //#GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, f, f;                           \ //#ROTATELEFT(F,19);
    RORXL $23, y3, h;                          \ //
    RORXL $15, y3, y1;                         \ //
    XORL y3, h;                                \ //
    XORL y1, h;                                \ //#P0(GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j])
    ;                                          \ //
    ;                                          \ // 2/4
    MOVL d, y1;                                \ //
    RORXL $20, d, y0;                          \ //#ROTATELEFT(A,12)
    XORL a, y1;                                \ //
    MOVL h, y3;                                \ //
    MOVL y0, y2;                               \ //#ROTATELEFT(A,12)
    ADDL h, y0;                                \ //
    XORL b, y1;                                \ //#FF0(A, B, C)
    ADDL 0(TBL), y0;                           \ 
    ADDL $4, TBL;                              \ // offset
    XORL e, y3;                                \ //
    ADDL c, y1;                                \ //#FF0(A, B, C)+D
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    RORXL $23, a,  a;                          \ //#ROTATELEFT(B,9);
    XORL y0, y2;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    XORL f, y3;                                \ //#GG0(E,F,G)
    ADDL y1, y2;                               \ //#FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL g, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL (_XFER+1*4)(SP)(SRND*1), y2;          \ //#FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    ADDL (_XMM_SAVE+1*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    MOVL y2, c;                                \ //
    ADDL y0, y3;                               \ //#GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, e, e;                           \ //#ROTATELEFT(F,19);
    RORXL $23, y3, g;                          \ //
    RORXL $15, y3, y1;                         \ //
    XORL y3, g;                                \ //
    XORL y1, g;                                \ //#P0(GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j])
    ;                                          \ //
    ;                                          \ // 3/4
    MOVL c, y1;                                \ //
    RORXL $20, c, y0;                          \ //#ROTATELEFT(A,12)
    XORL d, y1;                                \ //
    MOVL g, y3;                                \ //
    MOVL y0, y2;                               \ //#ROTATELEFT(A,12)
    ADDL g, y0;                                \ //
    XORL a, y1;                                \ //#FF0(A, B, C)
    ADDL 0(TBL), y0;                           \ 
    ADDL $4, TBL;                              \ // offset
    XORL h, y3;                                \ //
    ADDL b, y1;                                \ //#FF0(A, B, C)+D
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    RORXL $23, d,  d;                          \ //#ROTATELEFT(B,9);
    XORL y0, y2;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    XORL e, y3;                                \ //#GG0(E,F,G)
    ADDL y1, y2;                               \ //#FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL f, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL (_XFER+2*4)(SP)(SRND*1), y2;          \ //#FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    ADDL (_XMM_SAVE+2*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    MOVL y2, b;                                \ //
    ADDL y0, y3;                               \ //#GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, h, h;                           \ //#ROTATELEFT(F,19);
    RORXL $23, y3, f;                          \ //
    RORXL $15, y3, y1;                         \ //
    XORL y3, f;                                \ //
    XORL y1, f;                                \ //#P0(GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j])
    ;                                          \ //
    ;                                          \ // 4/4
    MOVL b, y1;                                \ //
    RORXL $20, b, y0;                          \ //#ROTATELEFT(A,12)
    XORL c, y1;                                \ //
    MOVL f, y3;                                \ //
    MOVL y0, y2;                               \ //#ROTATELEFT(A,12)
    ADDL f, y0;                                \ //
    XORL d, y1;                                \ //#FF0(A, B, C)
    ADDL 0(TBL), y0;                           \ 
    ADDL $4, TBL;                              \ // offset
    XORL g, y3;                                \ //
    ADDL a, y1;                                \ //#FF0(A, B, C)+D
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    RORXL $23, c,  c;                          \ //#ROTATELEFT(B,9);
    XORL y0, y2;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    XORL h, y3;                                \ //#GG0(E,F,G)
    ADDL y1, y2;                               \ //#FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL e, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL (_XFER+3*4)(SP)(SRND*1), y2;          \ //#FF0(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    ADDL (_XMM_SAVE+3*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    MOVL y2, a;                                \ //
    ADDL y0, y3;                               \ //#GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, g, g;                           \ //#ROTATELEFT(F,19);
    RORXL $23, y3, e;                          \ //
    RORXL $15, y3, y1;                         \ //
    XORL y3, e;                                \ //
    XORL y1, e;                                \ //#P0(GG0(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j])


#define Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h) \
    ;                                          \ //
    ;                                          \ // 1/4
    MOVL b, y1;                                \ //
    MOVL c, y2;                                \ //
    RORXL $20, a, y0;                          \ //#ROTATELEFT(A,12)
    ORL c, y1;                                 \ //#(B|C)
    ANDL b, y2;                                \ //#(B&C)
    MOVL y0, y3;                               \ //#ROTATELEFT(A,12)
    ANDL a, y1;                                \ //#A&(B|C)
    ADDL e, y0;                                \ //
    ORL y2, y1;                                \ //#FF1(x,y,z)
    ADDL 0(TBL), y0;                           \ 
    ADDL $4, TBL;                              \ // offset
    MOVL f, y2;                                \ //
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL d, y1;                                \ //#FF1(A, B, C)+D
    XORL y0, y3;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL h, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    XORL g, y2;                                \ //
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL (_XMM_SAVE+0*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    ANDL e, y2;                                \ //
    ADDL (_XFER+0*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    RORXL $23, b, b;                           \ //#ROTATELEFT(B,9);
    XORL g, y2;                                \ //
    MOVL y3, d;                                \ //
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, f, f;                           \ //#ROTATELEFT(F,19);
    RORXL $23, y0, h;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, h;                                \ //
    XORL y3, h;                                \ //
    ;                                          \ //
    ;                                          \ // 2/4
    MOVL a, y1;                                \ //
    MOVL b, y2;                                \ //
    RORXL $20, d, y0;                          \ //#ROTATELEFT(A,12)
    ORL b, y1;                                 \ //#(B|C)
    ANDL a, y2;                                \ //#(B&C)
    MOVL y0, y3;                               \ //#ROTATELEFT(A,12)
    ANDL d, y1;                                \ //#A&(B|C)
    ADDL h, y0;                                \ //
    ORL y2, y1;                                \ //#FF1(x,y,z)
    ADDL 0(TBL), y0;                           \ 
    ADDL $4, TBL;                              \ // offset
    MOVL e, y2;                                \ //
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL c, y1;                                \ //#FF1(A, B, C)+D
    XORL y0, y3;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL g, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    XORL f, y2;                                \ //
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL (_XMM_SAVE+1*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    ANDL h, y2;                                \ //
    ADDL (_XFER+1*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    RORXL $23, a, a;                           \ //#ROTATELEFT(B,9);
    XORL f, y2;                                \ //
    MOVL y3, c;                                \ //
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, e, e;                           \ //#ROTATELEFT(F,19);
    RORXL $23, y0, g;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, g;                                \ //
    XORL y3, g;                                \ //
    ;                                          \ //
    ;                                          \ // 3/4
    MOVL d, y1;                                \ //
    MOVL a, y2;                                \ //
    RORXL $20, c, y0;                          \ //#ROTATELEFT(A,12)
    ORL a, y1;                                 \ //#(B|C)
    ANDL d, y2;                                \ //#(B&C)
    MOVL y0, y3;                               \ //#ROTATELEFT(A,12)
    ANDL c, y1;                                \ //#A&(B|C)
    ADDL g, y0;                                \ //
    ORL y2, y1;                                \ //#FF1(x,y,z)
    ADDL 0(TBL), y0;                           \ 
    ADDL $4, TBL;                              \ // offset
    MOVL h, y2;                                \ //
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL b, y1;                                \ //#FF1(A, B, C)+D
    XORL y0, y3;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL f, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    XORL e, y2;                                \ //
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL (_XMM_SAVE+2*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    ANDL g, y2;                                \ //
    ADDL (_XFER+2*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    RORXL $23, d, d;                           \ //#ROTATELEFT(B,9);
    XORL e, y2;                                \ //
    MOVL y3, b;                                \ //
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, h, h;                           \ //#ROTATELEFT(F,19);
    RORXL $23, y0, f;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, f;                                \ //
    XORL y3, f;                                \ //
    ;                                          \ //
    ;                                          \ // 4/4
    MOVL c, y1;                                \ //
    MOVL d, y2;                                \ //
    RORXL $20, b, y0;                          \ //#ROTATELEFT(A,12)
    ORL d, y1;                                 \ //#(B|C)
    ANDL c, y2;                                \ //#(B&C)
    MOVL y0, y3;                               \ //#ROTATELEFT(A,12)
    ANDL b, y1;                                \ //#A&(B|C)
    ADDL f, y0;                                \ //
    ORL y2, y1;                                \ //#FF1(x,y,z)
    ADDL 0(TBL), y0;                           \ 
    ADDL $4, TBL;                              \ // offset
    MOVL g, y2;                                \ //
    RORXL $25, y0, y0;                         \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    ADDL a, y1;                                \ //#FF1(A, B, C)+D
    XORL y0, y3;                               \ //#ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL e, y0;                                \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)
    XORL h, y2;                                \ //
    ADDL y1, y3;                               \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)
    ADDL (_XMM_SAVE+3*4)(SP)(SRND*1), y0;      \ //#H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    ANDL f, y2;                                \ //
    ADDL (_XFER+3*4)(SP)(SRND*1), y3;          \ //#FF1(A, B, C)+D+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7) ^ ROTATELEFT(A,12)+W'[j]
    RORXL $23, c, c;                           \ //#ROTATELEFT(B,9);
    XORL h, y2;                                \ //
    MOVL y3, a;                                \ //
    ADDL y2, y0;                               \ //#GG1(E,F,G)+H+ROTATELEFT(ROTATELEFT(A,12) + E + k, 7)+W[j]
    RORXL $13, g, g;                           \ //#ROTATELEFT(F,19);
    RORXL $23, y0, e;                          \ //
    RORXL $15, y0, y3;                         \ //
    XORL y0, e;                                \ //
    XORL y3, e;                                \ //


TEXT ·block(SB), 0, $1048-32
    MOVQ dig+0(FP), CTX          // d.h[8]
    MOVQ p_base+8(FP), INP
    MOVQ p_len+16(FP), NUM_BYTES

    LEAQ -64(INP)(NUM_BYTES*1), NUM_BYTES // Pointer to the last block
    MOVQ NUM_BYTES, _INP_END(SP)

    CMPQ NUM_BYTES, INP
    JE   only_one_block

    // Load initial digest
    MOVL 0(CTX), a  // a = H0
    MOVL 4(CTX), b  // b = H1
    MOVL 8(CTX), c  // c = H2
    MOVL 12(CTX), d // d = H3
    MOVL 16(CTX), e // e = H4
    MOVL 20(CTX), f // f = H5
    MOVL 24(CTX), g // g = H6
    MOVL 28(CTX), h // h = H7

avx2_loop0: // at each iteration works with one block (512 bit)

    VMOVDQU (0*32)(INP), XTMP0
    VMOVDQU (1*32)(INP), XTMP1
    VMOVDQU (2*32)(INP), XTMP2
    VMOVDQU (3*32)(INP), XTMP3

    VMOVDQU PSHUFFLE_BYTE_FLIP_MASK<>(SB), BYTE_FLIP_MASK

    // Apply Byte Flip Mask: LE -> BE
    VPSHUFB BYTE_FLIP_MASK, XTMP0, XTMP0
    VPSHUFB BYTE_FLIP_MASK, XTMP1, XTMP1
    VPSHUFB BYTE_FLIP_MASK, XTMP2, XTMP2
    VPSHUFB BYTE_FLIP_MASK, XTMP3, XTMP3

    // Transpose data into high/low parts
    VPERM2I128 $0x20, XTMP2, XTMP0, XDWORD0 // w3, w2, w1, w0
    VPERM2I128 $0x31, XTMP2, XTMP0, XDWORD1 // w7, w6, w5, w4
    VPERM2I128 $0x20, XTMP3, XTMP1, XDWORD2 // w11, w10, w9, w8
    VPERM2I128 $0x31, XTMP3, XTMP1, XDWORD3 // w15, w14, w13, w12

    MOVQ $K256<>(SB), TBL // Loading address of table with offset-specific constants

last_block_enter:
    ADDQ    $64, INP
    MOVQ    INP, _INP(SP)
    XORQ    SRND, SRND

    // ################执行前16轮的迭代################
    VPXOR XDWORD0, XDWORD1, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD0, (_XMM_SAVE)(SP)(SRND*1)
    First_16_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3)

    ADDQ $32, SRND
    VPXOR XDWORD1, XDWORD2, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD1, (_XMM_SAVE)(SP)(SRND*1)
    First_16_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD1, XDWORD2, XDWORD3, XDWORD0)

    ADDQ $32, SRND
    VPXOR XDWORD2, XDWORD3, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD2, (_XMM_SAVE)(SP)(SRND*1)
    First_16_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD2, XDWORD3, XDWORD0, XDWORD1)

    ADDQ $32, SRND
    VPXOR XDWORD3, XDWORD0, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD3, (_XMM_SAVE)(SP)(SRND*1)
    First_16_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD3, XDWORD0, XDWORD1, XDWORD2)

    // ################再执行前36轮的迭代################
    ADDQ $32, SRND
    VPXOR XDWORD0, XDWORD1, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD0, (_XMM_SAVE)(SP)(SRND*1)
    Second_36_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3)

    ADDQ $32, SRND
    VPXOR XDWORD1, XDWORD2, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD1, (_XMM_SAVE)(SP)(SRND*1)
    Second_36_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD1, XDWORD2, XDWORD3, XDWORD0)

    ADDQ $32, SRND
    VPXOR XDWORD2, XDWORD3, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD2, (_XMM_SAVE)(SP)(SRND*1)
    Second_36_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD2, XDWORD3, XDWORD0, XDWORD1)

    ADDQ $32, SRND
    VPXOR XDWORD3, XDWORD0, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD3, (_XMM_SAVE)(SP)(SRND*1)
    Second_36_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD3, XDWORD0, XDWORD1, XDWORD2)

    ADDQ $32, SRND
    VPXOR XDWORD0, XDWORD1, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD0, (_XMM_SAVE)(SP)(SRND*1)
    Second_36_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3)

    ADDQ $32, SRND
    VPXOR XDWORD1, XDWORD2, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD1, (_XMM_SAVE)(SP)(SRND*1)
    Second_36_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD1, XDWORD2, XDWORD3, XDWORD0)

    ADDQ $32, SRND
    VPXOR XDWORD2, XDWORD3, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD2, (_XMM_SAVE)(SP)(SRND*1)
    Second_36_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD2, XDWORD3, XDWORD0, XDWORD1)

    ADDQ $32, SRND
    VPXOR XDWORD3, XDWORD0, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD3, (_XMM_SAVE)(SP)(SRND*1)
    Second_36_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD3, XDWORD0, XDWORD1, XDWORD2)

    ADDQ $32, SRND
    VPXOR XDWORD0, XDWORD1, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD0, (_XMM_SAVE)(SP)(SRND*1)
    Second_36_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h, XDWORD0, XDWORD1, XDWORD2, XDWORD3)

    // ################执行后12轮的迭代################
    ADDQ $32, SRND
    VPXOR XDWORD1, XDWORD2, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD1, (_XMM_SAVE)(SP)(SRND*1)
    Third_12_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h)

    ADDQ $32, SRND
    VPXOR XDWORD2, XDWORD3, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD2, (_XMM_SAVE)(SP)(SRND*1)
    Third_12_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h)

    ADDQ $32, SRND
    VPXOR XDWORD3, XDWORD0, XFER				// W'[j] = W[j] ^ W[j+4]
    VMOVDQU XFER, (_XFER)(SP)(SRND*1)
    VMOVDQU XDWORD3, (_XMM_SAVE)(SP)(SRND*1)
    Third_12_ROUNDS_AND_SCHED(a, b, c, d, e, f, g, h)

    MOVQ dig+0(FP), CTX
    MOVQ _INP(SP), INP
    MOVQ $K256<>(SB), TBL

    xorm(  0(CTX), a)
    xorm(  4(CTX), b)
    xorm(  8(CTX), c)
    xorm( 12(CTX), d)
    xorm( 16(CTX), e)
    xorm( 20(CTX), f)
    xorm( 24(CTX), g)
    xorm( 28(CTX), h)

    CMPQ _INP_END(SP), INP
    JB   done_hash

    XORQ SRND, SRND

    ADDQ $16, SRND
    First_16_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    First_16_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    First_16_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    First_16_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)
    ADDQ $32, SRND
    Second_48_ROUNDS_Without_SCHED(a, b, c, d, e, f, g, h)

    MOVQ dig+0(FP), CTX // d.h[8]
    MOVQ _INP(SP), INP
    ADDQ $64, INP

    xorm(  0(CTX), a)
    xorm(  4(CTX), b)
    xorm(  8(CTX), c)
    xorm( 12(CTX), d)
    xorm( 16(CTX), e)
    xorm( 20(CTX), f)
    xorm( 24(CTX), g)
    xorm( 28(CTX), h)

    CMPQ _INP_END(SP), INP
    JA   avx2_loop0
    JB   done_hash

do_last_block:
    VMOVDQU 0*16(INP),XWORD0
    VMOVDQU 1*16(INP),XWORD1
    VMOVDQU 2*16(INP),XWORD2
    VMOVDQU 3*16(INP),XWORD3

    VMOVDQU PSHUFFLE_BYTE_FLIP_MASK<>(SB), BYTE_FLIP_MASK

    VPSHUFB X_BYTE_FLIP_MASK, XWORD0, XWORD0
    VPSHUFB X_BYTE_FLIP_MASK, XWORD1, XWORD1
    VPSHUFB X_BYTE_FLIP_MASK, XWORD2, XWORD2
    VPSHUFB X_BYTE_FLIP_MASK, XWORD3, XWORD3

    MOVQ $K256<>(SB), TBL

    JMP	last_block_enter

only_one_block:
    // 加载初始的摘要值
    MOVL    (4*0)(CTX),a
    MOVL    (4*1)(CTX),b
    MOVL    (4*2)(CTX),c
    MOVL    (4*3)(CTX),d
    MOVL    (4*4)(CTX),e
    MOVL    (4*5)(CTX),f
    MOVL    (4*6)(CTX),g
    MOVL    (4*7)(CTX),h

    JMP do_last_block
    
done_hash:
    VZEROUPPER
    RET

DATA PSHUFFLE_BYTE_FLIP_MASK<>+0x00(SB)/8, $0x0405060700010203
DATA PSHUFFLE_BYTE_FLIP_MASK<>+0x08(SB)/8, $0x0c0d0e0f08090a0b
DATA PSHUFFLE_BYTE_FLIP_MASK<>+0x10(SB)/8, $0x0405060700010203
DATA PSHUFFLE_BYTE_FLIP_MASK<>+0x18(SB)/8, $0x0c0d0e0f08090a0b
GLOBL PSHUFFLE_BYTE_FLIP_MASK<>(SB), 8, $32

DATA K256<>+0x00(SB)/4, $0x79CC4519
DATA K256<>+0x04(SB)/4, $0xF3988A32
DATA K256<>+0x08(SB)/4, $0xE7311465
DATA K256<>+0x0c(SB)/4, $0xCE6228CB
DATA K256<>+0x10(SB)/4, $0x9CC45197
DATA K256<>+0x14(SB)/4, $0x3988A32F
DATA K256<>+0x18(SB)/4, $0x7311465E
DATA K256<>+0x1c(SB)/4, $0xE6228CBC

DATA K256<>+0x20(SB)/4, $0xCC451979
DATA K256<>+0x24(SB)/4, $0x988A32F3
DATA K256<>+0x28(SB)/4, $0x311465E7
DATA K256<>+0x2c(SB)/4, $0x6228CBCE
DATA K256<>+0x30(SB)/4, $0xC451979C
DATA K256<>+0x34(SB)/4, $0x88A32F39
DATA K256<>+0x38(SB)/4, $0x11465E73
DATA K256<>+0x3c(SB)/4, $0x228CBCE6

DATA K256<>+0x40(SB)/4, $0x9D8A7A87
DATA K256<>+0x44(SB)/4, $0x3B14F50F
DATA K256<>+0x48(SB)/4, $0x7629EA1E
DATA K256<>+0x4c(SB)/4, $0xEC53D43C
DATA K256<>+0x50(SB)/4, $0xD8A7A879
DATA K256<>+0x54(SB)/4, $0xB14F50F3
DATA K256<>+0x58(SB)/4, $0x629EA1E7
DATA K256<>+0x5c(SB)/4, $0xC53D43CE

DATA K256<>+0x60(SB)/4, $0x8A7A879D
DATA K256<>+0x64(SB)/4, $0x14F50F3B
DATA K256<>+0x68(SB)/4, $0x29EA1E76
DATA K256<>+0x6c(SB)/4, $0x53D43CEC
DATA K256<>+0x70(SB)/4, $0xA7A879D8
DATA K256<>+0x74(SB)/4, $0x4F50F3B1
DATA K256<>+0x78(SB)/4, $0x9EA1E762
DATA K256<>+0x7c(SB)/4, $0x3D43CEC5

DATA K256<>+0x80(SB)/4, $0x7A879D8A
DATA K256<>+0x84(SB)/4, $0xF50F3B14
DATA K256<>+0x88(SB)/4, $0xEA1E7629
DATA K256<>+0x8c(SB)/4, $0xD43CEC53
DATA K256<>+0x90(SB)/4, $0xA879D8A7
DATA K256<>+0x94(SB)/4, $0x50F3B14F
DATA K256<>+0x98(SB)/4, $0xA1E7629E
DATA K256<>+0x9c(SB)/4, $0x43CEC53D

DATA K256<>+0xa0(SB)/4, $0x879D8A7A
DATA K256<>+0xa4(SB)/4, $0x0F3B14F5
DATA K256<>+0xa8(SB)/4, $0x1E7629EA
DATA K256<>+0xac(SB)/4, $0x3CEC53D4
DATA K256<>+0xb0(SB)/4, $0x79D8A7A8
DATA K256<>+0xb4(SB)/4, $0xF3B14F50
DATA K256<>+0xb8(SB)/4, $0xE7629EA1
DATA K256<>+0xbc(SB)/4, $0xCEC53D43

DATA K256<>+0xc0(SB)/4, $0x9D8A7A87
DATA K256<>+0xc4(SB)/4, $0x3B14F50F
DATA K256<>+0xc8(SB)/4, $0x7629EA1E
DATA K256<>+0xcc(SB)/4, $0xEC53D43C
DATA K256<>+0xd0(SB)/4, $0xD8A7A879
DATA K256<>+0xd4(SB)/4, $0xB14F50F3
DATA K256<>+0xd8(SB)/4, $0x629EA1E7
DATA K256<>+0xdc(SB)/4, $0xC53D43CE

DATA K256<>+0xe0(SB)/4, $0x8A7A879D
DATA K256<>+0xe4(SB)/4, $0x14F50F3B
DATA K256<>+0xe8(SB)/4, $0x29EA1E76
DATA K256<>+0xec(SB)/4, $0x53D43CEC
DATA K256<>+0xf0(SB)/4, $0xA7A879D8
DATA K256<>+0xf4(SB)/4, $0x4F50F3B1
DATA K256<>+0xf8(SB)/4, $0x9EA1E762
DATA K256<>+0xfc(SB)/4, $0x3D43CEC5

DATA K256<>+0x100(SB)/4, $0x7A879D8A
DATA K256<>+0x104(SB)/4, $0xF50F3B14
DATA K256<>+0x108(SB)/4, $0xEA1E7629
DATA K256<>+0x10c(SB)/4, $0xD43CEC53
DATA K256<>+0x110(SB)/4, $0xA879D8A7
DATA K256<>+0x114(SB)/4, $0x50F3B14F
DATA K256<>+0x118(SB)/4, $0xA1E7629E
DATA K256<>+0x11c(SB)/4, $0x43CEC53D

DATA K256<>+0x120(SB)/4, $0x879D8A7A
DATA K256<>+0x124(SB)/4, $0x0F3B14F5
DATA K256<>+0x128(SB)/4, $0x1E7629EA
DATA K256<>+0x12c(SB)/4, $0x3CEC53D4
DATA K256<>+0x130(SB)/4, $0x79D8A7A8
DATA K256<>+0x134(SB)/4, $0xF3B14F50
DATA K256<>+0x138(SB)/4, $0xE7629EA1
DATA K256<>+0x13c(SB)/4, $0xCEC53D43
GLOBL K256<>(SB), (NOPTR + RODATA), $512



