disk.img: SOUL.x LOCO.x
	mksd.sh --so SOUL.x --user LOCO.x

# ----------------------------------
# SOUL object files -- Add your SOUL object files here 
SOUL_OBJS=soul.o 

# ----------------------------------
# Compiling/Assembling/Linking Tools and flags
AS=arm-eabi-as
AS_FLAGS=-g

CC=arm-eabi-gcc
CC_FLAGS=-g

LD=arm-eabi-ld
LD_FLAGS=-g
# ----------------------------------

# ----------------------------------
# Generic Rules
api_robot2.o: api_robot2.s
	$(AS) $(AS_FLAGS) $< -o $@

soul.o: soul.s
	$(AS) $(AS_FLAGS) $< -o $@

loco.o: loco.c
	$(CC) $(CC_FLAGS) -c $< -o $@

# ----------------------------------
# Specific Rules
SOUL.x: $(SOUL_OBJS)
	$(LD) $^ -o $@ $(LD_FLAGS) --section-start=.iv=0x778005e0 -Ttext=0x77800700 -Tdata=0x77801800 -e 0x778005e0

LOCO.x: loco.o api_robot2.o
	$(LD) $^ -o $@ $(LD_FLAGS) -Ttext=0x77802000
