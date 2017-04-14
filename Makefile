.PHONY: all clean

CFLAGS=-Wall

#TARGETS=cc76489.bin cc76489.wav cc76489.dsk cc76489.ccc cc76489.s19
TARGETS=cc76489.s19 cc76489.wav cc76489.dsk
EXTRA=cc76489.bin cc76489.8k cc76489.16k cc76489.32k

all: $(TARGETS)

%.bin: %.asm
	lwasm -9 -l -f decb -o $@ $<

%.s19: %.asm
	lwasm -DMON09 -9 -l -f srec -o $@ $<

%.ccc: %.asm
	lwasm -DROM -9 -l -f raw -o $@ $<

%.wav: %.bin
	cecb bulkerase $@
	cecb copy -2 -b -g $< \
		$(@),$$(echo $< | cut -c1-8 | tr [:lower:] [:upper:])

cc76489.bin: songinfo.dat
cc76489.s19: songinfo.dat

cc76489.dsk: cc76489.bin COPYING
	rm -f $@
	decb dskini $@
	decb copy -2 -b $< $@,$$(echo $< | tr [:lower:] [:upper:])
	decb copy -3 -a -l COPYING $@,COPYING

cc76489.8k: cc76489.ccc
	rm -f $@
	dd if=/dev/zero bs=2k count=4 | \
		tr '\000' '\377' > $@
	dd if=$< of=$@ conv=notrunc

cc76489.16k: cc76489.8k
	cat $< > $@
	cat $< >> $@

cc76489.32k: cc76489.16k
	cat $< > $@
	cat $< >> $@

clean:
	$(RM) $(TARGETS) $(EXTRA)
