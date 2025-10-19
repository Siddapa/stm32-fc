
bin/blink.elf:     file format elf32-littlearm


Disassembly of section .text:

08000000 <main-0x14c>:
 8000000:	20005000 	andcs	r5, r0, r0
 8000004:	0800014d 	stmdaeq	r0, {r0, r2, r3, r6, r8}
	...

0800014c <main>:
 800014c:	b480      	push	{r7}
 800014e:	b083      	sub	sp, #12
 8000150:	af00      	add	r7, sp, #0
 8000152:	4b1a      	ldr	r3, [pc, #104]	; (80001bc <main+0x70>)
 8000154:	681b      	ldr	r3, [r3, #0]
 8000156:	4a19      	ldr	r2, [pc, #100]	; (80001bc <main+0x70>)
 8000158:	f043 0310 	orr.w	r3, r3, #16
 800015c:	6013      	str	r3, [r2, #0]
 800015e:	4b18      	ldr	r3, [pc, #96]	; (80001c0 <main+0x74>)
 8000160:	681b      	ldr	r3, [r3, #0]
 8000162:	4a17      	ldr	r2, [pc, #92]	; (80001c0 <main+0x74>)
 8000164:	f423 1340 	bic.w	r3, r3, #3145728	; 0x300000
 8000168:	6013      	str	r3, [r2, #0]
 800016a:	4b15      	ldr	r3, [pc, #84]	; (80001c0 <main+0x74>)
 800016c:	681b      	ldr	r3, [r3, #0]
 800016e:	4a14      	ldr	r2, [pc, #80]	; (80001c0 <main+0x74>)
 8000170:	f443 1380 	orr.w	r3, r3, #1048576	; 0x100000
 8000174:	6013      	str	r3, [r2, #0]
 8000176:	4b13      	ldr	r3, [pc, #76]	; (80001c4 <main+0x78>)
 8000178:	681b      	ldr	r3, [r3, #0]
 800017a:	4a12      	ldr	r2, [pc, #72]	; (80001c4 <main+0x78>)
 800017c:	f443 5300 	orr.w	r3, r3, #8192	; 0x2000
 8000180:	6013      	str	r3, [r2, #0]
 8000182:	2300      	movs	r3, #0
 8000184:	607b      	str	r3, [r7, #4]
 8000186:	e003      	b.n	8000190 <main+0x44>
 8000188:	bf00      	nop
 800018a:	687b      	ldr	r3, [r7, #4]
 800018c:	3301      	adds	r3, #1
 800018e:	607b      	str	r3, [r7, #4]
 8000190:	687b      	ldr	r3, [r7, #4]
 8000192:	4a0d      	ldr	r2, [pc, #52]	; (80001c8 <main+0x7c>)
 8000194:	4293      	cmp	r3, r2
 8000196:	d9f7      	bls.n	8000188 <main+0x3c>
 8000198:	4b0a      	ldr	r3, [pc, #40]	; (80001c4 <main+0x78>)
 800019a:	681b      	ldr	r3, [r3, #0]
 800019c:	4a09      	ldr	r2, [pc, #36]	; (80001c4 <main+0x78>)
 800019e:	f423 5300 	bic.w	r3, r3, #8192	; 0x2000
 80001a2:	6013      	str	r3, [r2, #0]
 80001a4:	2300      	movs	r3, #0
 80001a6:	603b      	str	r3, [r7, #0]
 80001a8:	e003      	b.n	80001b2 <main+0x66>
 80001aa:	bf00      	nop
 80001ac:	683b      	ldr	r3, [r7, #0]
 80001ae:	3301      	adds	r3, #1
 80001b0:	603b      	str	r3, [r7, #0]
 80001b2:	683b      	ldr	r3, [r7, #0]
 80001b4:	4a05      	ldr	r2, [pc, #20]	; (80001cc <main+0x80>)
 80001b6:	4293      	cmp	r3, r2
 80001b8:	d9f7      	bls.n	80001aa <main+0x5e>
 80001ba:	e7dc      	b.n	8000176 <main+0x2a>
 80001bc:	40021018 	andmi	r1, r2, r8, lsl r0
 80001c0:	40011004 	andmi	r1, r1, r4
 80001c4:	4001100c 	andmi	r1, r1, ip
 80001c8:	00061a7f 	andeq	r1, r6, pc, ror sl
 80001cc:	000f423f 	andeq	r4, pc, pc, lsr r2	; <UNPREDICTABLE>
