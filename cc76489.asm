	nam	SN76489AN player for Coco
	ttl	CoCo76489 

CURPOS	equ	$0088		Text screen cursor position for ROM terminal

PIA0D0	equ	$ff00		CoCo hardware definitions
PIA0C0	equ	$ff01
PIA0D1	equ	$ff02
PIA0C1	equ	$ff03

PIA1D0	equ	$ff20
PIA1C0	equ	$ff21
PIA1D1	equ	$ff22
PIA1C1	equ	$ff23

TXTBASE	equ	$0400		memory map-related definitions
TXTSIZE	equ	$0200
PLAYRAM	equ	(TXTBASE+TXTSIZE)

NUMSNGS	equ	5		HARD-CODED NUMBER OF SONGS IN DATA SECTION!!

	ifdef	ROM
START	equ	$c000
	else
START	equ	$0e00
	endif

	org	START

	ifndef	ROM
	lda	#$03		setup MPI as needed
	sta	$ff7f
	endif

INIT	lds	#TXTBASE	relocate stack

	orcc	#$50		disable IRQ and FIRQ

	lda	PIA0C0		disable hsync interrupt generation
	anda	#$fc
	sta	PIA0C0
	tst	PIA0D0		clear any pending hsync interrupts
	lda	PIA0C1		enable vsync interrupt generation
	ora	#$01
	sta	PIA0C1
	tst	PIA0D1
	sync			wait for vsync interrupt

	jsr	txtinit		put text init and screen display here!

	lda	#$9f		Disable channel 0
	sta	$ff41
	nop
	nop
	nop
	nop
	lda	#$bf		Disable channel 1
	sta	$ff41
	nop
	nop
	nop
	nop
	lda	#$df		Disable channel 2
	sta	$ff41
	nop
	nop
	nop
	nop
	lda	#$ff		Disable channel 3
	sta	$ff41

	lda	#$34		Enable sound from cartridge
	sta	PIA0C0
	lda	#$3f
	sta	PIA0C1
	lda	#$3c
	sta	PIA1C1

	ldx	#RESTART	copy player code to RAM
	ldy	#PLAYRAM
.1?	lda	,x+
	sta	,y+
	cmpx	#txtinit
	bne	.1?

	jmp	PLAYRAM

RESTART	leas	-1,s		Store current ROM bank on stack
	clr	,s
	clr	$ff40

	lda	#NUMSNGS	Store count of songs in ROM data on stack
	pshs	a

	ldx	#songdat	point X at song data

LOOP	lbsr	clrtscn

	clra
.1?	sync			wait for vsync interrupt
	tst	PIA0D1
	deca
	bne	.1?

	bsr	PLAYSNG

	lda	#$9f		Disable channel 0
	sta	$ff41
	nop
	nop
	nop
	nop
	lda	#$bf		Disable channel 1
	sta	$ff41
	nop
	nop
	nop
	nop
	lda	#$df		Disable channel 2
	sta	$ff41
	nop
	nop
	nop
	nop
	lda	#$ff		Disable channel 3
	sta	$ff41

	dec	,s
	bne	LOOP

	leas	2,s
	bra	RESTART

*
* Play song
*
PLAYSNG	lda	,x+		move past header
	bsr	ckbkovf

.1?	leax	1,x
	bsr	ckbkovf
	deca
	bne	.1?

SNGTTL	ldd	#TXTBASE	write title to screen
	std	CURPOS
	ldb	,x+
	bsr	ckbkovf

.1?	lda	,x+
	bsr	ckbkovf
        cmpa	#$61		convert lowercase -> uppercase
        blt	.2?
        cmpa	#$7a
        bgt	.2?
        anda	#$df
.2?	jsr	[$a002]
	decb
	bne	.1?

	ldd	#(TXTBASE+96)	write author to screen
	std	CURPOS
	ldb	,x+
	bsr	ckbkovf

.1?	lda	,x+
	bsr	ckbkovf
        cmpa	#$61		convert lowercase -> uppercase
        blt	.2?
        cmpa	#$7a
        bgt	.2?
        anda	#$df
.2?	jsr	[$a002]
	decb
	bne	.1?

.1?	sync			wait for vsync interrupt
	tst	PIA0D1
	lda	,x+
	bsr	ckbkovf
	tsta
	beq	.1?
	cmpa	#$ff
	beq	.3?
.2?	ldb	,x+
	bsr	ckbkovf
	stb	$ff41
	nop
	nop
	nop
	nop
	deca
	bne	.2?
	bra	.1?
.3?	rts

*
* ckbkovf
*
ckbkovf	pshs	a
	ifdef	ROM
	cmpx	#$fe00
	blt	.1?
	lda	6,s		two function calls below RESTART, offset into stack accordingly
	inca
	sta	6,s
	sta	$ff40
	ldx	#$c000
	endif
.1?	puls	a
	rts

*
* Clear text screen
*
clrtscn	lda	#' '
	ldy	#TXTBASE
.1?	sta	,y+
	cmpy	#(TXTBASE+512)
	blt	.1?
	rts

*
* txtinit -- setup text screen
*
txtinit	clr	$ffc0		clr v0
	clr	$ffc2		clr v1
	clr	$ffc4		clr v2
	clr	PIA1D1		setup vdg

	clr	$ffc6		set video base to $0400
	clr	$ffc9
	clr	$ffca
	clr	$ffcc
	clr	$ffce
	clr	$ffd0
	clr	$ffd2

	rts

*
* Data Declarations
*
songdat
	ifndef	ROM
	includebin	"songinfo.dat"
	endif

	end	START
