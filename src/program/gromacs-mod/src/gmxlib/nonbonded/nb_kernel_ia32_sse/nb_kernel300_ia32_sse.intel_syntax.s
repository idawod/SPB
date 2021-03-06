;#
;# $Id: nb_kernel300_ia32_sse.intel_syntax.s,v 1.1.2.1 2006/03/01 15:18:30 lindahl Exp $
;#
;# Gromacs 4.0                         Copyright (c) 1991-2003 
;# David van der Spoel, Erik Lindahl
;#
;# This program is free software; you can redistribute it and/or
;# modify it under the terms of the GNU General Public License
;# as published by the Free Software Foundation; either version 2
;# of the License, or (at your option) any later version.
;#
;# To help us fund GROMACS development, we humbly ask that you cite
;# the research papers on the package. Check out http://www.gromacs.org
;# 
;# And Hey:
;# Gnomes, ROck Monsters And Chili Sauce
;#

;# These files require GNU binutils 2.10 or later, since we
;# use intel syntax for portability, or a recent version 
;# of NASM that understands Extended 3DNow and SSE2 instructions.
;# (NASM is normally only used with MS Visual C++).
;# Since NASM and gnu as disagree on some definitions and use 
;# completely different preprocessing options I have to introduce a
;# trick: NASM uses ';' for comments, while gnu as uses '#' on x86.
;# Gnu as treats ';' as a line break, i.e. ignores it. This is the
;# reason why all comments need both symbols...
;# The source is written for GNU as, with intel syntax. When you use
;# NASM we redefine a couple of things. The false if-statement around 
;# the following code is seen by GNU as, but NASM doesn't see it, so 
;# the code inside is read by NASM but not gcc.

; .if 0    # block below only read by NASM
%define .section	section
%define .long		dd
%define .align		align
%define .globl		global
;# NASM only wants 'dword', not 'dword ptr'.
%define ptr
.equiv          .equiv                  2
   %1 equ %2
%endmacro
; .endif                   # End of NASM-specific block
; .intel_syntax noprefix   # Line only read by gnu as


	

.globl nb_kernel300_ia32_sse
.globl _nb_kernel300_ia32_sse
nb_kernel300_ia32_sse:	
_nb_kernel300_ia32_sse:	
.equiv          nb300_p_nri,            8
.equiv          nb300_iinr,             12
.equiv          nb300_jindex,           16
.equiv          nb300_jjnr,             20
.equiv          nb300_shift,            24
.equiv          nb300_shiftvec,         28
.equiv          nb300_fshift,           32
.equiv          nb300_gid,              36
.equiv          nb300_pos,              40
.equiv          nb300_faction,          44
.equiv          nb300_charge,           48
.equiv          nb300_p_facel,          52
.equiv          nb300_argkrf,           56
.equiv          nb300_argcrf,           60
.equiv          nb300_Vc,               64
.equiv          nb300_type,             68
.equiv          nb300_p_ntype,          72
.equiv          nb300_vdwparam,         76
.equiv          nb300_Vvdw,             80
.equiv          nb300_p_tabscale,       84
.equiv          nb300_VFtab,            88
.equiv          nb300_invsqrta,         92
.equiv          nb300_dvda,             96
.equiv          nb300_p_gbtabscale,     100
.equiv          nb300_GBtab,            104
.equiv          nb300_p_nthreads,       108
.equiv          nb300_count,            112
.equiv          nb300_mtx,              116
.equiv          nb300_outeriter,        120
.equiv          nb300_inneriter,        124
.equiv          nb300_work,             128
	;# stack offsets for local variables  
	;# bottom of stack is cache-aligned for sse use 
.equiv          nb300_ix,               0
.equiv          nb300_iy,               16
.equiv          nb300_iz,               32
.equiv          nb300_iq,               48
.equiv          nb300_dx,               64
.equiv          nb300_dy,               80
.equiv          nb300_dz,               96
.equiv          nb300_two,              112
.equiv          nb300_tsc,              128
.equiv          nb300_qq,               144
.equiv          nb300_fs,               160
.equiv          nb300_vctot,            176
.equiv          nb300_fix,              192
.equiv          nb300_fiy,              208
.equiv          nb300_fiz,              224
.equiv          nb300_half,             240
.equiv          nb300_three,            256
.equiv          nb300_is3,              272
.equiv          nb300_ii3,              276
.equiv          nb300_innerjjnr,        280
.equiv          nb300_innerk,           284
.equiv          nb300_n,                288
.equiv          nb300_nn1,              292
.equiv          nb300_nri,              296
.equiv          nb300_facel,            300
.equiv          nb300_nouter,           304
.equiv          nb300_ninner,           308
.equiv          nb300_salign,           312
	push ebp
	mov ebp,esp	
    	push eax
    	push ebx
    	push ecx
    	push edx
	push esi
	push edi
	sub esp, 316		;# local stack space 
	mov  eax, esp
	and  eax, 0xf
	sub esp, eax
	mov [esp + nb300_salign], eax

	emms

	;# Move args passed by reference to stack
	mov ecx, [ebp + nb300_p_nri]
	mov esi, [ebp + nb300_p_facel]
	mov ecx, [ecx]
	mov esi, [esi]
	mov [esp + nb300_nri], ecx
	mov [esp + nb300_facel], esi

	;# zero iteration counters
	mov eax, 0
	mov [esp + nb300_nouter], eax
	mov [esp + nb300_ninner], eax


	mov eax, [ebp + nb300_p_tabscale]
	movss xmm3, [eax]
	shufps xmm3, xmm3, 0
	movaps [esp + nb300_tsc], xmm3

	;# create constant floating-point factors on stack
	mov eax, 0x3f000000     ;# constant 0.5 in IEEE (hex)
	mov [esp + nb300_half], eax
	movss xmm1, [esp + nb300_half]
	shufps xmm1, xmm1, 0    ;# splat to all elements
	movaps xmm2, xmm1       
	addps  xmm2, xmm2	;# constant 1.0
	movaps xmm3, xmm2
	addps  xmm2, xmm2	;# constant 2.0
	addps  xmm3, xmm2	;# constant 3.0
	movaps [esp + nb300_half],  xmm1
	movaps [esp + nb300_two],  xmm2
	movaps [esp + nb300_three],  xmm3

.nb300_threadloop:
        mov   esi, [ebp + nb300_count]          ;# pointer to sync counter
        mov   eax, [esi]
.nb300_spinlock:
        mov   ebx, eax                          ;# ebx=*count=nn0
        add   ebx, 1                           ;# ebx=nn1=nn0+10
        lock
        cmpxchg [esi], ebx                      ;# write nn1 to *counter,
                                                ;# if it hasnt changed.
                                                ;# or reread *counter to eax.
        pause                                   ;# -> better p4 performance
        jnz .nb300_spinlock

        ;# if(nn1>nri) nn1=nri
        mov ecx, [esp + nb300_nri]
        mov edx, ecx
        sub ecx, ebx
        cmovle ebx, edx                         ;# if(nn1>nri) nn1=nri
        ;# Cleared the spinlock if we got here.
        ;# eax contains nn0, ebx contains nn1.
        mov [esp + nb300_n], eax
        mov [esp + nb300_nn1], ebx
        sub ebx, eax                            ;# calc number of outer lists
	mov esi, eax				;# copy n to esi
        jg  .nb300_outerstart
        jmp .nb300_end

.nb300_outerstart:
	;# ebx contains number of outer iterations
	add ebx, [esp + nb300_nouter]
	mov [esp + nb300_nouter], ebx

.nb300_outer:
	mov   eax, [ebp + nb300_shift]      ;# eax = pointer into shift[] 
	mov   ebx, [eax + esi*4]		;# ebx=shift[n] 
	
	lea   ebx, [ebx + ebx*2]    ;# ebx=3*is 
	mov   [esp + nb300_is3],ebx    	;# store is3 

	mov   eax, [ebp + nb300_shiftvec]   ;# eax = base of shiftvec[] 

	movss xmm0, [eax + ebx*4]
	movss xmm1, [eax + ebx*4 + 4]
	movss xmm2, [eax + ebx*4 + 8] 

	mov   ecx, [ebp + nb300_iinr]       ;# ecx = pointer into iinr[] 	
	mov   ebx, [ecx + esi*4]	    ;# ebx =ii 

	mov   edx, [ebp + nb300_charge]
	movss xmm3, [edx + ebx*4]	
	mulss xmm3, [esp + nb300_facel]
	shufps xmm3, xmm3, 0

	lea   ebx, [ebx + ebx*2]	;# ebx = 3*ii=ii3 
	mov   eax, [ebp + nb300_pos]    ;# eax = base of pos[]  

	addss xmm0, [eax + ebx*4]
	addss xmm1, [eax + ebx*4 + 4]
	addss xmm2, [eax + ebx*4 + 8]

	movaps [esp + nb300_iq], xmm3
	
	shufps xmm0, xmm0, 0
	shufps xmm1, xmm1, 0
	shufps xmm2, xmm2, 0

	movaps [esp + nb300_ix], xmm0
	movaps [esp + nb300_iy], xmm1
	movaps [esp + nb300_iz], xmm2

	mov   [esp + nb300_ii3], ebx
	
	;# clear vctot and i forces 
	xorps xmm4, xmm4
	movaps [esp + nb300_vctot], xmm4
	movaps [esp + nb300_fix], xmm4
	movaps [esp + nb300_fiy], xmm4
	movaps [esp + nb300_fiz], xmm4
	
	mov   eax, [ebp + nb300_jindex]
	mov   ecx, [eax + esi*4]	     ;# jindex[n] 
	mov   edx, [eax + esi*4 + 4]	     ;# jindex[n+1] 
	sub   edx, ecx               ;# number of innerloop atoms 

	mov   esi, [ebp + nb300_pos]
	mov   edi, [ebp + nb300_faction]	
	mov   eax, [ebp + nb300_jjnr]
	shl   ecx, 2
	add   eax, ecx
	mov   [esp + nb300_innerjjnr], eax     ;# pointer to jjnr[nj0] 
	mov   ecx, edx
	sub   edx,  4
	add   ecx, [esp + nb300_ninner]
	mov   [esp + nb300_ninner], ecx
	add   edx, 0
	mov   [esp + nb300_innerk], edx    ;# number of innerloop atoms 
	jge   .nb300_unroll_loop
	jmp   .nb300_finish_inner
.nb300_unroll_loop:	
	;# quad-unroll innerloop here 
	mov   edx, [esp + nb300_innerjjnr]     ;# pointer to jjnr[k] 
	mov   eax, [edx]	
	mov   ebx, [edx + 4]              
	mov   ecx, [edx + 8]            
	mov   edx, [edx + 12]         ;# eax-edx=jnr1-4 
	add dword ptr [esp + nb300_innerjjnr],  16 ;# advance pointer (unrolled 4) 

	mov esi, [ebp + nb300_charge]    ;# base of charge[] 
	
	movss xmm3, [esi + eax*4]
	movss xmm4, [esi + ecx*4]
	movss xmm6, [esi + ebx*4]
	movss xmm7, [esi + edx*4]

	movaps xmm2, [esp + nb300_iq]
	shufps xmm3, xmm6, 0 
	shufps xmm4, xmm7, 0 
	shufps xmm3, xmm4, 136  ;# constant 10001000 ;# all charges in xmm3  
	mulps  xmm3, xmm2

	movaps [esp + nb300_qq], xmm3	
	
	mov esi, [ebp + nb300_pos]       ;# base of pos[] 

	lea   eax, [eax + eax*2]     ;# replace jnr with j3 
	lea   ebx, [ebx + ebx*2]	

	lea   ecx, [ecx + ecx*2]     ;# replace jnr with j3 
	lea   edx, [edx + edx*2]	

	;# move four coordinates to xmm0-xmm2 	

	movlps xmm4, [esi + eax*4]
	movlps xmm5, [esi + ecx*4]
	movss xmm2, [esi + eax*4 + 8]
	movss xmm6, [esi + ecx*4 + 8]

	movhps xmm4, [esi + ebx*4]
	movhps xmm5, [esi + edx*4]

	movss xmm0, [esi + ebx*4 + 8]
	movss xmm1, [esi + edx*4 + 8]

	shufps xmm2, xmm0, 0
	shufps xmm6, xmm1, 0
	
	movaps xmm0, xmm4
	movaps xmm1, xmm4

	shufps xmm2, xmm6, 136  ;# constant 10001000
	
	shufps xmm0, xmm5, 136  ;# constant 10001000
	shufps xmm1, xmm5, 221  ;# constant 11011101		

	;# move ix-iz to xmm4-xmm6 
	movaps xmm4, [esp + nb300_ix]
	movaps xmm5, [esp + nb300_iy]
	movaps xmm6, [esp + nb300_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# store dr 
	movaps [esp + nb300_dx], xmm4
	movaps [esp + nb300_dy], xmm5
	movaps [esp + nb300_dz], xmm6
	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb300_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb300_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 
	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb300_tsc]

	movhlps xmm5, xmm4
	cvttps2pi mm6, xmm4
	cvttps2pi mm7, xmm5	;# mm6/mm7 contain lu indices 
	cvtpi2ps xmm6, mm6
	cvtpi2ps xmm5, mm7
	movlhps xmm6, xmm5
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 
	pslld mm6, 2
	pslld mm7, 2

	movd mm0, eax	
	movd mm1, ebx
	movd mm2, ecx
	movd mm3, edx

	mov  esi, [ebp + nb300_VFtab]
	movd eax, mm6
	psrlq mm6, 32
	movd ecx, mm7
	psrlq mm7, 32
	movd ebx, mm6
	movd edx, mm7
		
	movlps xmm5, [esi + eax*4]
	movlps xmm7, [esi + ecx*4]
	movhps xmm5, [esi + ebx*4]
	movhps xmm7, [esi + edx*4] ;# got half coulomb table 

	movaps xmm4, xmm5
	shufps xmm4, xmm7, 136  ;# constant 10001000
	shufps xmm5, xmm7, 221  ;# constant 11011101

	movlps xmm7, [esi + eax*4 + 8]
	movlps xmm3, [esi + ecx*4 + 8]
	movhps xmm7, [esi + ebx*4 + 8]
	movhps xmm3, [esi + edx*4 + 8] ;# other half of coulomb table  
	movaps xmm6, xmm7
	shufps xmm6, xmm3, 136  ;# constant 10001000
	shufps xmm7, xmm3, 221  ;# constant 11011101
	;# coulomb table ready, in xmm4-xmm7  	
	
	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	mulps  xmm7, [esp + nb300_two]	;# two*Heps2 
	movaps xmm3, [esp + nb300_qq]
	addps  xmm7, xmm6
	addps  xmm7, xmm5 ;# xmm7=FF 
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  
	mulps  xmm3, xmm7 ;# fijC=FF*qq 
	;# at this point mm5 contains vcoul and mm3 fijC 
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addps  xmm5, [esp + nb300_vctot]
	movaps [esp + nb300_vctot], xmm5 

	xorps  xmm4, xmm4

	mulps xmm3, [esp + nb300_tsc]
	mulps xmm3, xmm0
	subps  xmm4, xmm3

	movaps xmm0, [esp + nb300_dx]
	movaps xmm1, [esp + nb300_dy]
	movaps xmm2, [esp + nb300_dz]

	movd eax, mm0	
	movd ebx, mm1
	movd ecx, mm2
	movd edx, mm3

	mov    edi, [ebp + nb300_faction]
	mulps  xmm0, xmm4
	mulps  xmm1, xmm4
	mulps  xmm2, xmm4
	;# xmm0-xmm2 contains tx-tz (partial force) 
	;# now update f_i 
	movaps xmm3, [esp + nb300_fix]
	movaps xmm4, [esp + nb300_fiy]
	movaps xmm5, [esp + nb300_fiz]
	addps  xmm3, xmm0
	addps  xmm4, xmm1
	addps  xmm5, xmm2
	movaps [esp + nb300_fix], xmm3
	movaps [esp + nb300_fiy], xmm4
	movaps [esp + nb300_fiz], xmm5
	;# the fj's - start by accumulating x & y forces from memory 
	movlps xmm4, [edi + eax*4]
	movlps xmm6, [edi + ecx*4]
	movhps xmm4, [edi + ebx*4]
	movhps xmm6, [edi + edx*4]

	movaps xmm3, xmm4
	shufps xmm3, xmm6, 136  ;# constant 10001000
	shufps xmm4, xmm6, 221  ;# constant 11011101			      

	;# now xmm3-xmm5 contains fjx, fjy, fjz 
	subps  xmm3, xmm0
	subps  xmm4, xmm1
	
	;# unpack them back so we can store them - first x & y in xmm3/xmm4 

	movaps xmm6, xmm3
	unpcklps xmm6, xmm4
	unpckhps xmm3, xmm4	
	;# xmm6(l)=x & y for j1, (h) for j2 
	;# xmm3(l)=x & y for j3, (h) for j4 
	movlps [edi + eax*4], xmm6
	movlps [edi + ecx*4], xmm3
	
	movhps [edi + ebx*4], xmm6
	movhps [edi + edx*4], xmm3

	;# and the z forces 
	movss  xmm4, [edi + eax*4 + 8]
	movss  xmm5, [edi + ebx*4 + 8]
	movss  xmm6, [edi + ecx*4 + 8]
	movss  xmm7, [edi + edx*4 + 8]
	subss  xmm4, xmm2
	shufps xmm2, xmm2, 229  ;# constant 11100101
	subss  xmm5, xmm2
	shufps xmm2, xmm2, 234  ;# constant 11101010
	subss  xmm6, xmm2
	shufps xmm2, xmm2, 255  ;# constant 11111111
	subss  xmm7, xmm2
	movss  [edi + eax*4 + 8], xmm4
	movss  [edi + ebx*4 + 8], xmm5
	movss  [edi + ecx*4 + 8], xmm6
	movss  [edi + edx*4 + 8], xmm7
	
	;# should we do one more iteration? 
	sub dword ptr [esp + nb300_innerk],  4
	jl    .nb300_finish_inner
	jmp   .nb300_unroll_loop
.nb300_finish_inner:
	;# check if at least two particles remain 
	add dword ptr [esp + nb300_innerk],  4
	mov   edx, [esp + nb300_innerk]
	and   edx, 2
	jnz   .nb300_dopair
	jmp   .nb300_checksingle
.nb300_dopair:	
	mov esi, [ebp + nb300_charge]

    mov   ecx, [esp + nb300_innerjjnr]
	
	mov   eax, [ecx]	
	mov   ebx, [ecx + 4]              
	add dword ptr [esp + nb300_innerjjnr],  8	
	xorps xmm7, xmm7
	movss xmm3, [esi + eax*4]		
	movss xmm6, [esi + ebx*4]
	shufps xmm3, xmm6, 0 
	shufps xmm3, xmm3, 8 ;# constant 00001000 ;# xmm3(0,1) has the charges 

	mulps  xmm3, [esp + nb300_iq]
	movlhps xmm3, xmm7
	movaps [esp + nb300_qq], xmm3

	mov edi, [ebp + nb300_pos]	
	
	lea   eax, [eax + eax*2]
	lea   ebx, [ebx + ebx*2]
	;# move coordinates to xmm0-xmm2 
	movlps xmm1, [edi + eax*4]
	movss xmm2, [edi + eax*4 + 8]	
	movhps xmm1, [edi + ebx*4]
	movss xmm0, [edi + ebx*4 + 8]	

	movlhps xmm3, xmm7
	
	shufps xmm2, xmm0, 0
	
	movaps xmm0, xmm1

	shufps xmm2, xmm2, 136  ;# constant 10001000
	
	shufps xmm0, xmm0, 136  ;# constant 10001000
	shufps xmm1, xmm1, 221  ;# constant 11011101
			
	mov    edi, [ebp + nb300_faction]
	;# move ix-iz to xmm4-xmm6 
	xorps   xmm7, xmm7
	
	movaps xmm4, [esp + nb300_ix]
	movaps xmm5, [esp + nb300_iy]
	movaps xmm6, [esp + nb300_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# store dr 
	movaps [esp + nb300_dx], xmm4
	movaps [esp + nb300_dy], xmm5
	movaps [esp + nb300_dz], xmm6
	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb300_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb300_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 
	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb300_tsc]

	cvttps2pi mm6, xmm4     ;# mm6 contain lu indices 
	cvtpi2ps xmm6, mm6
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 

	pslld mm6, 2

	mov  esi, [ebp + nb300_VFtab]
	movd ecx, mm6
	psrlq mm6, 32
	movd edx, mm6

	movlps xmm5, [esi + ecx*4]
	movhps xmm5, [esi + edx*4] ;# got half coulomb table 
	movaps xmm4, xmm5
	shufps xmm4, xmm4, 136  ;# constant 10001000
	shufps xmm5, xmm7, 221  ;# constant 11011101
	
	movlps xmm7, [esi + ecx*4 + 8]
	movhps xmm7, [esi + edx*4 + 8]
	movaps xmm6, xmm7
	shufps xmm6, xmm6, 136  ;# constant 10001000
	shufps xmm7, xmm7, 221  ;# constant 11011101
	;# table ready in xmm4-xmm7 

	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	mulps  xmm7, [esp + nb300_two]	;# two*Heps2 
	movaps xmm3, [esp + nb300_qq]
	addps  xmm7, xmm6
	addps  xmm7, xmm5 ;# xmm7=FF 
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  
	mulps  xmm3, xmm7 ;# fijC=FF*qq 
	;# at this point mm5 contains vcoul and mm3 fijC 
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addps  xmm5, [esp + nb300_vctot]
	movaps [esp + nb300_vctot], xmm5 

	xorps  xmm4, xmm4

	mulps xmm3, [esp + nb300_tsc]
	mulps xmm3, xmm0
	subps  xmm4, xmm3

	movaps xmm0, [esp + nb300_dx]
	movaps xmm1, [esp + nb300_dy]
	movaps xmm2, [esp + nb300_dz]

	mulps  xmm0, xmm4
	mulps  xmm1, xmm4
	mulps  xmm2, xmm4
	;# xmm0-xmm2 contains tx-tz (partial force) 
	;# now update f_i 
	movaps xmm3, [esp + nb300_fix]
	movaps xmm4, [esp + nb300_fiy]
	movaps xmm5, [esp + nb300_fiz]
	addps  xmm3, xmm0
	addps  xmm4, xmm1
	addps  xmm5, xmm2
	movaps [esp + nb300_fix], xmm3
	movaps [esp + nb300_fiy], xmm4
	movaps [esp + nb300_fiz], xmm5
	;# update the fj's 
	movss   xmm3, [edi + eax*4]
	movss   xmm4, [edi + eax*4 + 4]
	movss   xmm5, [edi + eax*4 + 8]
	subss   xmm3, xmm0
	subss   xmm4, xmm1
	subss   xmm5, xmm2	
	movss   [edi + eax*4], xmm3
	movss   [edi + eax*4 + 4], xmm4
	movss   [edi + eax*4 + 8], xmm5	

	shufps  xmm0, xmm0, 225  ;# constant 11100001
	shufps  xmm1, xmm1, 225  ;# constant 11100001
	shufps  xmm2, xmm2, 225  ;# constant 11100001

	movss   xmm3, [edi + ebx*4]
	movss   xmm4, [edi + ebx*4 + 4]
	movss   xmm5, [edi + ebx*4 + 8]
	subss   xmm3, xmm0
	subss   xmm4, xmm1
	subss   xmm5, xmm2	
	movss   [edi + ebx*4], xmm3
	movss   [edi + ebx*4 + 4], xmm4
	movss   [edi + ebx*4 + 8], xmm5	

.nb300_checksingle:				
	mov   edx, [esp + nb300_innerk]
	and   edx, 1
	jnz    .nb300_dosingle
	jmp    .nb300_updateouterdata
.nb300_dosingle:
	mov esi, [ebp + nb300_charge]
	mov edi, [ebp + nb300_pos]
	mov   ecx, [esp + nb300_innerjjnr]
	mov   eax, [ecx]	
	xorps  xmm6, xmm6
	movss xmm6, [esi + eax*4]	;# xmm6(0) has the charge 	
	mulps  xmm6, [esp + nb300_iq]
	movaps [esp + nb300_qq], xmm6
		
	lea   eax, [eax + eax*2]
	
	;# move coordinates to xmm0-xmm2 
	movss xmm0, [edi + eax*4]	
	movss xmm1, [edi + eax*4 + 4]	
	movss xmm2, [edi + eax*4 + 8]	 
	
	movaps xmm4, [esp + nb300_ix]
	movaps xmm5, [esp + nb300_iy]
	movaps xmm6, [esp + nb300_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# store dr 
	movaps [esp + nb300_dx], xmm4
	movaps [esp + nb300_dy], xmm5
	movaps [esp + nb300_dz], xmm6
	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb300_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb300_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 

	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb300_tsc]

	cvttps2pi mm6, xmm4     ;# mm6 contain lu indices 
	cvtpi2ps xmm6, mm6
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 

	pslld mm6, 2

	mov  esi, [ebp + nb300_VFtab]
	movd ebx, mm6
	
	movlps xmm4, [esi + ebx*4]
	movlps xmm6, [esi + ebx*4 + 8]
	movaps xmm5, xmm4
	movaps xmm7, xmm6
	shufps xmm5, xmm5, 1
	shufps xmm7, xmm7, 1
	;# table ready in xmm4-xmm7 

	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	mulps  xmm7, [esp + nb300_two]	;# two*Heps2 
	movaps xmm3, [esp + nb300_qq]
	addps  xmm7, xmm6
	addps  xmm7, xmm5 ;# xmm7=FF 
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  
	mulps  xmm3, xmm7 ;# fijC=FF*qq 
	;# at this point mm5 contains vcoul and mm3 fijC 
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addss  xmm5, [esp + nb300_vctot]
	movss [esp + nb300_vctot], xmm5 

	xorps xmm4, xmm4

	mulps xmm3, [esp + nb300_tsc]
	mulps xmm3, xmm0
	subps  xmm4, xmm3
	mov    edi, [ebp + nb300_faction]

	movaps xmm0, [esp + nb300_dx]
	movaps xmm1, [esp + nb300_dy]
	movaps xmm2, [esp + nb300_dz]

	mulps  xmm0, xmm4
	mulps  xmm1, xmm4
	mulps  xmm2, xmm4
	;# xmm0-xmm2 contains tx-tz (partial force) 
	;# now update f_i 
	movaps xmm3, [esp + nb300_fix]
	movaps xmm4, [esp + nb300_fiy]
	movaps xmm5, [esp + nb300_fiz]
	addss  xmm3, xmm0
	addss  xmm4, xmm1
	addss  xmm5, xmm2
	movaps [esp + nb300_fix], xmm3
	movaps [esp + nb300_fiy], xmm4
	movaps [esp + nb300_fiz], xmm5
	;# update fj 
	
	movss   xmm3, [edi + eax*4]
	movss   xmm4, [edi + eax*4 + 4]
	movss   xmm5, [edi + eax*4 + 8]
	subss   xmm3, xmm0
	subss   xmm4, xmm1
	subss   xmm5, xmm2	
	movss   [edi + eax*4], xmm3
	movss   [edi + eax*4 + 4], xmm4
	movss   [edi + eax*4 + 8], xmm5	
.nb300_updateouterdata:
	mov   ecx, [esp + nb300_ii3]
	mov   edi, [ebp + nb300_faction]
	mov   esi, [ebp + nb300_fshift]
	mov   edx, [esp + nb300_is3]

	;# accumulate i forces in xmm0, xmm1, xmm2 
	movaps xmm0, [esp + nb300_fix]
	movaps xmm1, [esp + nb300_fiy]
	movaps xmm2, [esp + nb300_fiz]

	movhlps xmm3, xmm0
	movhlps xmm4, xmm1
	movhlps xmm5, xmm2
	addps  xmm0, xmm3
	addps  xmm1, xmm4
	addps  xmm2, xmm5 ;# sum is in 1/2 in xmm0-xmm2 

	movaps xmm3, xmm0	
	movaps xmm4, xmm1	
	movaps xmm5, xmm2	

	shufps xmm3, xmm3, 1
	shufps xmm4, xmm4, 1
	shufps xmm5, xmm5, 1
	addss  xmm0, xmm3
	addss  xmm1, xmm4
	addss  xmm2, xmm5	;# xmm0-xmm2 has single force in pos0 

	;# increment i force 
	movss  xmm3, [edi + ecx*4]
	movss  xmm4, [edi + ecx*4 + 4]
	movss  xmm5, [edi + ecx*4 + 8]
	addss  xmm3, xmm0
	addss  xmm4, xmm1
	addss  xmm5, xmm2
	movss  [edi + ecx*4],     xmm3
	movss  [edi + ecx*4 + 4], xmm4
	movss  [edi + ecx*4 + 8], xmm5

	;# increment fshift force  
	movss  xmm3, [esi + edx*4]
	movss  xmm4, [esi + edx*4 + 4]
	movss  xmm5, [esi + edx*4 + 8]
	addss  xmm3, xmm0
	addss  xmm4, xmm1
	addss  xmm5, xmm2
	movss  [esi + edx*4],     xmm3
	movss  [esi + edx*4 + 4], xmm4
	movss  [esi + edx*4 + 8], xmm5

	;# get n from stack
	mov esi, [esp + nb300_n]
        ;# get group index for i particle 
        mov   edx, [ebp + nb300_gid]      	;# base of gid[]
        mov   edx, [edx + esi*4]		;# ggid=gid[n]

	;# accumulate total potential energy and update it 
	movaps xmm7, [esp + nb300_vctot]
	;# accumulate 
	movhlps xmm6, xmm7
	addps  xmm7, xmm6	;# pos 0-1 in xmm7 have the sum now 
	movaps xmm6, xmm7
	shufps xmm6, xmm6, 1
	addss  xmm7, xmm6		

	;# add earlier value from mem 
	mov   eax, [ebp + nb300_Vc]
	addss xmm7, [eax + edx*4] 
	;# move back to mem 
	movss [eax + edx*4], xmm7 
	
        ;# finish if last 
        mov ecx, [esp + nb300_nn1]
	;# esi already loaded with n
	inc esi
        sub ecx, esi
        jecxz .nb300_outerend

        ;# not last, iterate outer loop once more!  
        mov [esp + nb300_n], esi
        jmp .nb300_outer
.nb300_outerend:
        ;# check if more outer neighborlists remain
        mov   ecx, [esp + nb300_nri]
	;# esi already loaded with n above
        sub   ecx, esi
        jecxz .nb300_end
        ;# non-zero, do one more workunit
        jmp   .nb300_threadloop
.nb300_end:
	emms

	mov eax, [esp + nb300_nouter]
	mov ebx, [esp + nb300_ninner]
	mov ecx, [ebp + nb300_outeriter]
	mov edx, [ebp + nb300_inneriter]
	mov [ecx], eax
	mov [edx], ebx

	mov eax, [esp + nb300_salign]
	add esp, eax
	add esp, 316
	pop edi
	pop esi
    	pop edx
    	pop ecx
    	pop ebx
    	pop eax
	leave
	ret


	

.globl nb_kernel300nf_ia32_sse
.globl _nb_kernel300nf_ia32_sse
nb_kernel300nf_ia32_sse:	
_nb_kernel300nf_ia32_sse:	
.equiv          nb300nf_p_nri,          8
.equiv          nb300nf_iinr,           12
.equiv          nb300nf_jindex,         16
.equiv          nb300nf_jjnr,           20
.equiv          nb300nf_shift,          24
.equiv          nb300nf_shiftvec,       28
.equiv          nb300nf_fshift,         32
.equiv          nb300nf_gid,            36
.equiv          nb300nf_pos,            40
.equiv          nb300nf_faction,        44
.equiv          nb300nf_charge,         48
.equiv          nb300nf_p_facel,        52
.equiv          nb300nf_argkrf,         56
.equiv          nb300nf_argcrf,         60
.equiv          nb300nf_Vc,             64
.equiv          nb300nf_type,           68
.equiv          nb300nf_p_ntype,        72
.equiv          nb300nf_vdwparam,       76
.equiv          nb300nf_Vvdw,           80
.equiv          nb300nf_p_tabscale,     84
.equiv          nb300nf_VFtab,          88
.equiv          nb300nf_invsqrta,       92
.equiv          nb300nf_dvda,           96
.equiv          nb300nf_p_gbtabscale,   100
.equiv          nb300nf_GBtab,          104
.equiv          nb300nf_p_nthreads,     108
.equiv          nb300nf_count,          112
.equiv          nb300nf_mtx,            116
.equiv          nb300nf_outeriter,      120
.equiv          nb300nf_inneriter,      124
.equiv          nb300nf_work,           128
	;# stack offsets for local variables  
	;# bottom of stack is cache-aligned for sse use 
.equiv          nb300nf_ix,             0
.equiv          nb300nf_iy,             16
.equiv          nb300nf_iz,             32
.equiv          nb300nf_iq,             48
.equiv          nb300nf_tsc,            64
.equiv          nb300nf_qq,             80
.equiv          nb300nf_vctot,          96
.equiv          nb300nf_half,           112
.equiv          nb300nf_three,          128
.equiv          nb300nf_is3,            144
.equiv          nb300nf_ii3,            148
.equiv          nb300nf_innerjjnr,      152
.equiv          nb300nf_innerk,         156
.equiv          nb300nf_n,              160
.equiv          nb300nf_nn1,            164
.equiv          nb300nf_nri,            168
.equiv          nb300nf_facel,          172
.equiv          nb300nf_nouter,         176
.equiv          nb300nf_ninner,         180
.equiv          nb300nf_salign,         184
	push ebp
	mov ebp,esp	
    	push eax
    	push ebx
    	push ecx
    	push edx
	push esi
	push edi
	sub esp, 188		;# local stack space 
	mov  eax, esp
	and  eax, 0xf
	sub esp, eax
	mov [esp + nb300nf_salign], eax

	emms

	;# Move args passed by reference to stack
	mov ecx, [ebp + nb300nf_p_nri]
	mov esi, [ebp + nb300nf_p_facel]
	mov ecx, [ecx]
	mov esi, [esi]
	mov [esp + nb300nf_nri], ecx
	mov [esp + nb300nf_facel], esi

	;# zero iteration counters
	mov eax, 0
	mov [esp + nb300nf_nouter], eax
	mov [esp + nb300nf_ninner], eax


	mov eax, [ebp + nb300nf_p_tabscale]
	movss xmm3, [eax]
	shufps xmm3, xmm3, 0
	movaps [esp + nb300nf_tsc], xmm3

	;# create constant floating-point factors on stack
	mov eax, 0x3f000000     ;# constant 0.5 in IEEE (hex)
	mov [esp + nb300nf_half], eax
	movss xmm1, [esp + nb300nf_half]
	shufps xmm1, xmm1, 0    ;# splat to all elements
	movaps xmm2, xmm1       
	addps  xmm2, xmm2	;# constant 1.0
	movaps xmm3, xmm2
	addps  xmm2, xmm2	;# constant 2.0
	addps  xmm3, xmm2	;# constant 3.0
	movaps [esp + nb300nf_half],  xmm1
	movaps [esp + nb300nf_three],  xmm3

.nb300nf_threadloop:
        mov   esi, [ebp + nb300nf_count]          ;# pointer to sync counter
        mov   eax, [esi]
.nb300nf_spinlock:
        mov   ebx, eax                          ;# ebx=*count=nn0
        add   ebx, 1                           ;# ebx=nn1=nn0+10
        lock
        cmpxchg [esi], ebx                      ;# write nn1 to *counter,
                                                ;# if it hasnt changed.
                                                ;# or reread *counter to eax.
        pause                                   ;# -> better p4 performance
        jnz .nb300nf_spinlock

        ;# if(nn1>nri) nn1=nri
        mov ecx, [esp + nb300nf_nri]
        mov edx, ecx
        sub ecx, ebx
        cmovle ebx, edx                         ;# if(nn1>nri) nn1=nri
        ;# Cleared the spinlock if we got here.
        ;# eax contains nn0, ebx contains nn1.
        mov [esp + nb300nf_n], eax
        mov [esp + nb300nf_nn1], ebx
        sub ebx, eax                            ;# calc number of outer lists
	mov esi, eax				;# copy n to esi
        jg  .nb300nf_outerstart
        jmp .nb300nf_end
.nb300nf_outerstart:
	;# ebx contains number of outer iterations
	add ebx, [esp + nb300nf_nouter]
	mov [esp + nb300nf_nouter], ebx

.nb300nf_outer:
	mov   eax, [ebp + nb300nf_shift]      ;# eax = pointer into shift[] 
	mov   ebx, [eax + esi*4]		;# ebx=shift[n] 
	
	lea   ebx, [ebx + ebx*2]    ;# ebx=3*is 
	mov   [esp + nb300nf_is3],ebx    	;# store is3 

	mov   eax, [ebp + nb300nf_shiftvec]   ;# eax = base of shiftvec[] 

	movss xmm0, [eax + ebx*4]
	movss xmm1, [eax + ebx*4 + 4]
	movss xmm2, [eax + ebx*4 + 8] 

	mov   ecx, [ebp + nb300nf_iinr]       ;# ecx = pointer into iinr[] 	
	mov   ebx, [ecx + esi*4]	    ;# ebx =ii 

	mov   edx, [ebp + nb300nf_charge]
	movss xmm3, [edx + ebx*4]	
	mulss xmm3, [esp + nb300nf_facel]
	shufps xmm3, xmm3, 0

	lea   ebx, [ebx + ebx*2]	;# ebx = 3*ii=ii3 
	mov   eax, [ebp + nb300nf_pos]    ;# eax = base of pos[]  

	addss xmm0, [eax + ebx*4]
	addss xmm1, [eax + ebx*4 + 4]
	addss xmm2, [eax + ebx*4 + 8]

	movaps [esp + nb300nf_iq], xmm3
	
	shufps xmm0, xmm0, 0
	shufps xmm1, xmm1, 0
	shufps xmm2, xmm2, 0

	movaps [esp + nb300nf_ix], xmm0
	movaps [esp + nb300nf_iy], xmm1
	movaps [esp + nb300nf_iz], xmm2

	mov   [esp + nb300nf_ii3], ebx
	
	;# clear vctot and i forces 
	xorps xmm4, xmm4
	movaps [esp + nb300nf_vctot], xmm4
	
	mov   eax, [ebp + nb300nf_jindex]
	mov   ecx, [eax + esi*4]	     ;# jindex[n] 
	mov   edx, [eax + esi*4 + 4]	     ;# jindex[n+1] 
	sub   edx, ecx               ;# number of innerloop atoms 

	mov   esi, [ebp + nb300nf_pos]
	mov   eax, [ebp + nb300nf_jjnr]
	shl   ecx, 2
	add   eax, ecx
	mov   [esp + nb300nf_innerjjnr], eax     ;# pointer to jjnr[nj0] 
	mov   ecx, edx
	sub   edx,  4
	add   ecx, [esp + nb300nf_ninner]
	mov   [esp + nb300nf_ninner], ecx
	add   edx, 0
	mov   [esp + nb300nf_innerk], edx    ;# number of innerloop atoms 
	jge   .nb300nf_unroll_loop
	jmp   .nb300nf_finish_inner
.nb300nf_unroll_loop:	
	;# quad-unroll innerloop here 
	mov   edx, [esp + nb300nf_innerjjnr]     ;# pointer to jjnr[k] 
	mov   eax, [edx]	
	mov   ebx, [edx + 4]              
	mov   ecx, [edx + 8]            
	mov   edx, [edx + 12]         ;# eax-edx=jnr1-4 
	add dword ptr [esp + nb300nf_innerjjnr],  16 ;# advance pointer (unrolled 4) 

	mov esi, [ebp + nb300nf_charge]    ;# base of charge[] 
	
	movss xmm3, [esi + eax*4]
	movss xmm4, [esi + ecx*4]
	movss xmm6, [esi + ebx*4]
	movss xmm7, [esi + edx*4]

	movaps xmm2, [esp + nb300nf_iq]
	shufps xmm3, xmm6, 0 
	shufps xmm4, xmm7, 0 
	shufps xmm3, xmm4, 136  ;# constant 10001000 ;# all charges in xmm3  
	mulps  xmm3, xmm2

	movaps [esp + nb300nf_qq], xmm3	
	
	mov esi, [ebp + nb300nf_pos]       ;# base of pos[] 

	lea   eax, [eax + eax*2]     ;# replace jnr with j3 
	lea   ebx, [ebx + ebx*2]	

	lea   ecx, [ecx + ecx*2]     ;# replace jnr with j3 
	lea   edx, [edx + edx*2]	

	;# move four coordinates to xmm0-xmm2 	

	movlps xmm4, [esi + eax*4]
	movlps xmm5, [esi + ecx*4]
	movss xmm2, [esi + eax*4 + 8]
	movss xmm6, [esi + ecx*4 + 8]

	movhps xmm4, [esi + ebx*4]
	movhps xmm5, [esi + edx*4]

	movss xmm0, [esi + ebx*4 + 8]
	movss xmm1, [esi + edx*4 + 8]

	shufps xmm2, xmm0, 0
	shufps xmm6, xmm1, 0
	
	movaps xmm0, xmm4
	movaps xmm1, xmm4

	shufps xmm2, xmm6, 136  ;# constant 10001000
	
	shufps xmm0, xmm5, 136  ;# constant 10001000
	shufps xmm1, xmm5, 221  ;# constant 11011101		

	;# move ix-iz to xmm4-xmm6 
	movaps xmm4, [esp + nb300nf_ix]
	movaps xmm5, [esp + nb300nf_iy]
	movaps xmm6, [esp + nb300nf_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb300nf_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb300nf_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 
	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb300nf_tsc]

	movhlps xmm5, xmm4
	cvttps2pi mm6, xmm4
	cvttps2pi mm7, xmm5	;# mm6/mm7 contain lu indices 
	cvtpi2ps xmm6, mm6
	cvtpi2ps xmm5, mm7
	movlhps xmm6, xmm5
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 
	pslld mm6, 2
	pslld mm7, 2

	movd mm0, eax	
	movd mm1, ebx
	movd mm2, ecx
	movd mm3, edx

	mov  esi, [ebp + nb300nf_VFtab]
	movd eax, mm6
	psrlq mm6, 32
	movd ecx, mm7
	psrlq mm7, 32
	movd ebx, mm6
	movd edx, mm7
		
	movlps xmm5, [esi + eax*4]
	movlps xmm7, [esi + ecx*4]
	movhps xmm5, [esi + ebx*4]
	movhps xmm7, [esi + edx*4] ;# got half coulomb table 

	movaps xmm4, xmm5
	shufps xmm4, xmm7, 136  ;# constant 10001000
	shufps xmm5, xmm7, 221  ;# constant 11011101

	movlps xmm7, [esi + eax*4 + 8]
	movlps xmm3, [esi + ecx*4 + 8]
	movhps xmm7, [esi + ebx*4 + 8]
	movhps xmm3, [esi + edx*4 + 8] ;# other half of coulomb table  
	movaps xmm6, xmm7
	shufps xmm6, xmm3, 136  ;# constant 10001000
	shufps xmm7, xmm3, 221  ;# constant 11011101
	;# coulomb table ready, in xmm4-xmm7  	
	
	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	movaps xmm3, [esp + nb300nf_qq]
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  

	;# at this point xmm5 contains vcoul 
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addps  xmm5, [esp + nb300nf_vctot]
	movaps [esp + nb300nf_vctot], xmm5 

	;# should we do one more iteration? 
	sub dword ptr [esp + nb300nf_innerk],  4
	jl    .nb300nf_finish_inner
	jmp   .nb300nf_unroll_loop
.nb300nf_finish_inner:
	;# check if at least two particles remain 
	add dword ptr [esp + nb300nf_innerk],  4
	mov   edx, [esp + nb300nf_innerk]
	and   edx, 2
	jnz   .nb300nf_dopair
	jmp   .nb300nf_checksingle
.nb300nf_dopair:	
	mov esi, [ebp + nb300nf_charge]

    mov   ecx, [esp + nb300nf_innerjjnr]
	
	mov   eax, [ecx]	
	mov   ebx, [ecx + 4]              
	add dword ptr [esp + nb300nf_innerjjnr],  8	
	xorps xmm7, xmm7
	movss xmm3, [esi + eax*4]		
	movss xmm6, [esi + ebx*4]
	shufps xmm3, xmm6, 0 
	shufps xmm3, xmm3, 8 ;# constant 00001000 ;# xmm3(0,1) has the charges 

	mulps  xmm3, [esp + nb300nf_iq]
	movlhps xmm3, xmm7
	movaps [esp + nb300nf_qq], xmm3

	mov edi, [ebp + nb300nf_pos]	
	
	lea   eax, [eax + eax*2]
	lea   ebx, [ebx + ebx*2]
	;# move coordinates to xmm0-xmm2 
	movlps xmm1, [edi + eax*4]
	movss xmm2, [edi + eax*4 + 8]	
	movhps xmm1, [edi + ebx*4]
	movss xmm0, [edi + ebx*4 + 8]	

	movlhps xmm3, xmm7
	
	shufps xmm2, xmm0, 0
	
	movaps xmm0, xmm1

	shufps xmm2, xmm2, 136  ;# constant 10001000
	
	shufps xmm0, xmm0, 136  ;# constant 10001000
	shufps xmm1, xmm1, 221  ;# constant 11011101
			
	;# move ix-iz to xmm4-xmm6 
	xorps   xmm7, xmm7
	
	movaps xmm4, [esp + nb300nf_ix]
	movaps xmm5, [esp + nb300nf_iy]
	movaps xmm6, [esp + nb300nf_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb300nf_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb300nf_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 
	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb300nf_tsc]

	cvttps2pi mm6, xmm4     ;# mm6 contain lu indices 
	cvtpi2ps xmm6, mm6
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 

	pslld mm6, 2

	mov  esi, [ebp + nb300nf_VFtab]
	movd ecx, mm6
	psrlq mm6, 32
	movd edx, mm6

	movlps xmm5, [esi + ecx*4]
	movhps xmm5, [esi + edx*4] ;# got half coulomb table 
	movaps xmm4, xmm5
	shufps xmm4, xmm4, 136  ;# constant 10001000
	shufps xmm5, xmm7, 221  ;# constant 11011101
	
	movlps xmm7, [esi + ecx*4 + 8]
	movhps xmm7, [esi + edx*4 + 8]
	movaps xmm6, xmm7
	shufps xmm6, xmm6, 136  ;# constant 10001000
	shufps xmm7, xmm7, 221  ;# constant 11011101
	;# table ready in xmm4-xmm7 

	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	movaps xmm3, [esp + nb300nf_qq]
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV  
	;# at this point mm5 contains vcoul 
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addps  xmm5, [esp + nb300nf_vctot]
	movaps [esp + nb300nf_vctot], xmm5 

.nb300nf_checksingle:				
	mov   edx, [esp + nb300nf_innerk]
	and   edx, 1
	jnz    .nb300nf_dosingle
	jmp    .nb300nf_updateouterdata
.nb300nf_dosingle:
	mov esi, [ebp + nb300nf_charge]
	mov edi, [ebp + nb300nf_pos]
	mov   ecx, [esp + nb300nf_innerjjnr]
	mov   eax, [ecx]	
	xorps  xmm6, xmm6
	movss xmm6, [esi + eax*4]	;# xmm6(0) has the charge 	
	mulps  xmm6, [esp + nb300nf_iq]
	movaps [esp + nb300nf_qq], xmm6
		
	lea   eax, [eax + eax*2]
	
	;# move coordinates to xmm0-xmm2 
	movss xmm0, [edi + eax*4]	
	movss xmm1, [edi + eax*4 + 4]	
	movss xmm2, [edi + eax*4 + 8]	 
	
	movaps xmm4, [esp + nb300nf_ix]
	movaps xmm5, [esp + nb300nf_iy]
	movaps xmm6, [esp + nb300nf_iz]

	;# calc dr 
	subps xmm4, xmm0
	subps xmm5, xmm1
	subps xmm6, xmm2

	;# square it 
	mulps xmm4,xmm4
	mulps xmm5,xmm5
	mulps xmm6,xmm6
	addps xmm4, xmm5
	addps xmm4, xmm6
	;# rsq in xmm4 

	rsqrtps xmm5, xmm4
	;# lookup seed in xmm5 
	movaps xmm2, xmm5
	mulps xmm5, xmm5
	movaps xmm1, [esp + nb300nf_three]
	mulps xmm5, xmm4	;# rsq*lu*lu 			
	movaps xmm0, [esp + nb300nf_half]
	subps xmm1, xmm5	;# constant 30-rsq*lu*lu 
	mulps xmm1, xmm2	
	mulps xmm0, xmm1	;# xmm0=rinv 

	mulps xmm4, xmm0	;# xmm4=r 
	mulps xmm4, [esp + nb300nf_tsc]

	cvttps2pi mm6, xmm4     ;# mm6 contain lu indices 
	cvtpi2ps xmm6, mm6
	subps xmm4, xmm6	
	movaps xmm1, xmm4	;# xmm1=eps 
	movaps xmm2, xmm1	
	mulps  xmm2, xmm2	;# xmm2=eps2 

	pslld mm6, 2

	mov  esi, [ebp + nb300nf_VFtab]
	movd ebx, mm6
	
	movlps xmm4, [esi + ebx*4]
	movlps xmm6, [esi + ebx*4 + 8]
	movaps xmm5, xmm4
	movaps xmm7, xmm6
	shufps xmm5, xmm5, 1
	shufps xmm7, xmm7, 1
	;# table ready in xmm4-xmm7 

	mulps  xmm6, xmm1	;# xmm6=Geps 
	mulps  xmm7, xmm2	;# xmm7=Heps2 
	addps  xmm5, xmm6
	addps  xmm5, xmm7	;# xmm5=Fp 	
	movaps xmm3, [esp + nb300nf_qq]
	mulps  xmm5, xmm1 ;# xmm5=eps*Fp 
	addps  xmm5, xmm4 ;# xmm5=VV 
	mulps  xmm5, xmm3 ;# vcoul=qq*VV 
	;# at this point mm5 contains vcoul 
	;# increment vcoul - then we can get rid of mm5 
	;# update vctot 
	addss  xmm5, [esp + nb300nf_vctot]
	movss [esp + nb300nf_vctot], xmm5 

.nb300nf_updateouterdata:
	;# get n from stack
	mov esi, [esp + nb300nf_n]
        ;# get group index for i particle 
        mov   edx, [ebp + nb300nf_gid]      	;# base of gid[]
        mov   edx, [edx + esi*4]		;# ggid=gid[n]

	;# accumulate total potential energy and update it 
	movaps xmm7, [esp + nb300nf_vctot]
	;# accumulate 
	movhlps xmm6, xmm7
	addps  xmm7, xmm6	;# pos 0-1 in xmm7 have the sum now 
	movaps xmm6, xmm7
	shufps xmm6, xmm6, 1
	addss  xmm7, xmm6		

	;# add earlier value from mem 
	mov   eax, [ebp + nb300nf_Vc]
	addss xmm7, [eax + edx*4] 
	;# move back to mem 
	movss [eax + edx*4], xmm7 
	
        ;# finish if last 
        mov ecx, [esp + nb300nf_nn1]
	;# esi already loaded with n
	inc esi
        sub ecx, esi
        jecxz .nb300nf_outerend

        ;# not last, iterate outer loop once more!  
        mov [esp + nb300nf_n], esi
        jmp .nb300nf_outer
.nb300nf_outerend:
        ;# check if more outer neighborlists remain
        mov   ecx, [esp + nb300nf_nri]
	;# esi already loaded with n above
        sub   ecx, esi
        jecxz .nb300nf_end
        ;# non-zero, do one more workunit
        jmp   .nb300nf_threadloop
.nb300nf_end:
	emms

	mov eax, [esp + nb300nf_nouter]
	mov ebx, [esp + nb300nf_ninner]
	mov ecx, [ebp + nb300nf_outeriter]
	mov edx, [ebp + nb300nf_inneriter]
	mov [ecx], eax
	mov [edx], ebx

	mov eax, [esp + nb300nf_salign]
	add esp, eax
	add esp, 188
	pop edi
	pop esi
    	pop edx
    	pop ecx
    	pop ebx
    	pop eax
	leave
	ret

