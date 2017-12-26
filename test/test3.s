foo:
	addi	sp,sp,-32
	sw	s0,28(sp)
	addi	s0,sp,32
	li	a5,1
	sw	a5,-20(s0)
	li	a5,2
	sw	a5,-24(s0)
	lw	a4,-20(s0)
	lw	a5,-24(s0)
	bge	a4,a5,.L2
	lw	a4,-20(s0)
	lw	a5,-24(s0)
	add	a5,a4,a5
	sw	a5,-32(s0)
	j	.L4
.L2:
	lw	a4,-24(s0)
	lw	a5,-20(s0)
	sub	a5,a4,a5
	sw	a5,-28(s0)
.L4:
	nop
	lw	s0,28(sp)
	addi	sp,sp,32
	jr	ra
.globl _start
_start:
	addi	sp,sp,-16
	sw	ra,12(sp)
	sw	s0,8(sp)
	addi	s0,sp,16
	call	foo
	li	a5,0
	mv	a0,a5
	lw	ra,12(sp)
	lw	s0,8(sp)
	addi	sp,sp,16
	jr	ra
	.ident	"GCC: (GNU) 7.2.0"
