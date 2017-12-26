.globl _start
_start:
    addi sp,sp,-32
	sw	s0,28(sp)
    addi a1,a1,3
	addi s0,sp,32
    sw a1,-28(s0)
    lw a2,-28(s0)
    add a4,a2,a3
    sw a4,-20(s0)
    lw a3,-20(s0)
