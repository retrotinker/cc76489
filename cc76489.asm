	nam	SN76489AN player for Coco
	ttl	CoCo76489 

TIMVAL	equ	$0112		Extended BASIC's free-running time counter

PIA0D0	equ	$ff00		CoCo hardware definitions
PIA0C0	equ	$ff01
PIA0D1	equ	$ff02
PIA0C1	equ	$ff03

PIA1D0	equ	$ff20
PIA1C0	equ	$ff21
PIA1D1	equ	$ff22
PIA1C1	equ	$ff23

SSPRREG	equ	$ff7d
SSPDREG	equ	$ff7e

TXTBASE	equ	$0400		memory map-related definitions
TXTSIZE	equ	$0200

	ifdef	ROM
START	equ	$c000
DATA	equ	(TXTBASE+TXTSIZE)
	else
START	equ	$0e00
	endif

	org	START

INIT	sts	savestk		save status for return to Color BASIC
	pshs	cc
	puls	a
	sta	savecc

	jsr	savpias		save PIA configuration

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

	lda	#$34		Enable sound from cartridge
	sta	PIA0C0
	lda	#$3f
	sta	PIA0C1
	lda	#$3c
	sta	PIA1C1

	* put text init and screen display here!

RESTART	ldx	#songdat

	lda	#$40
.1?	sync			wait for vsync interrupt
	tst	PIA0D1
	deca
	bne	.1?

LOOP	sync			wait for vsync interrupt
	tst	PIA0D1

	lda	,x+
	beq	LOOP
	cmpa	#$ff
	beq	RESTART

COUNT	ldb	,x+
	stb	$ff40
	deca
	bne	COUNT

	ifdef MON09
	jsr	chkuart
	endif

	bra	LOOP

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
* Clear text screen
*
clrtscn	lda	#' '
	ldy	#TXTBASE
.1?	sta	,y+
	cmpy	#(TXTBASE+512)
	blt	.1?
	rts

*
* Save PIA configuration data
*
savpias	ldx	#PIA0D0
	ldy	#savpdat
	ldd	#$0202
	pshs	d
.1?	ldd	,x
	std	,y++
	andb	#$fb
	stb	1,x
	lda	,x
	sta	,y+
	orb	#$04
	stb	1,x
	dec	,s
	beq	.2?
	leax	2,x
	bra	.1?
.2?	lda	#$02
	sta	,s
	dec	1,s
	beq	.3?
	leax	($20-$2),x
	bra	.1?
.3?	leas	2,s
	rts

*
* Restore PIA configuration data
*
rstpias	ldx	#PIA0D0
	ldy	#savpdat
	ldd	#$0202
	pshs	d
.1?	ldb	1,x
	andb	#$fb
	stb	1,x
	lda	2,y
	sta	,x
	orb	#$04
	stb	1,x
	ldd	,y
	std	,x
	leay	3,y
	dec	,s
	beq	.2?
	leax	2,x
	bra	.1?
.2?	lda	#$02
	sta	,s
	dec	1,s
	beq	.3?
	leax	($20-$2),x
	bra	.1?
.3?	leas	2,s
	rts

	ifdef MON09
*
* Check for user break (development only)
*
chkuart	lda	$ff69		Check for serial port activity
	bita	#$08
	beq	chkurex
	lda	$ff68
	jmp	[$fffe]		Re-enter monitor
chkurex	rts
	endif

*
* Exit the player
*
exit 	equ	*
	ifdef MON09
	jmp	[$fffe]		Reset!
	else
	jsr	clrtscn		clear text screen
	jsr	rstpias		restore PIA configuration
	lda	savecc		reenable any interrupts
	pshs	a
	puls	cc
	lds	savestk		restore stack pointer
	rts			return to RSDOS
	endif

*
* Data Declarations
*
songdat	includebin	"songinfo.dat"

*
* Variable Declarations
*
	ifdef	ROM
	org	DATA
	endif
savestk	rmb	2
savecc	rmb	1
savpdat	rmb	12

	end	START
