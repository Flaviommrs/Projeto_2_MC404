all:
	arm-eabi-as -g soul.s -o soul.o
	arm-eabi-ld soul.o -o soul -g --section-start=.iv=0x778005e0 -Ttext=0x77800700 -Tdata=0x77801800 -e 0x778005e0
	arm-eabi-as faz_nada.s -o faz_nada.o
	arm-eabi-ld faz_nada.o -o faz_nada -Ttext=0x77802000 
	mksd.sh --so soul --user faz_nada
	arm-sim --rom=/home/specg12-1/mc404/simulador/dumboot.bin --sd=disk.img
