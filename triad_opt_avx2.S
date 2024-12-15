// Z = Y + alpha * X

#define ALIGN_4 .p2align 4

#define N       %rdi
#define ALPHA   %rsi
#define X       %rdx
#define Y       %rcx
#define Z       %r8
#define I       %r9

#define SIZE    8
#define UNROLL  8

#if defined (USE_NT)
#define VMOVX  vmovntpd
#define NAME    triad_opt_avx2_nt

#elif defined (USE_RFO)
#define VMOVX  vmovupd
#define NAME    triad_opt_avx2_rfo

#else
#error "Store type is undefined"
#endif

  .text
  .align 256
  .globl NAME
  .type NAME, @function
NAME:
  mov (N), N
	mov	 N,  I
#if UNROLL==8
  sar $3,  I
#endif
#if UNROLL==16
  sar $4,  I
#endif
	vbroadcastsd	(ALPHA), %ymm0

  ALIGN_4

.L1:
  vmovupd     (X), %ymm1
	vfmadd213pd	(Y), %ymm0, %ymm1
  VMOVX    %ymm1, (Z)

  vmovupd     4 * SIZE(X), %ymm2
	vfmadd213pd	4 * SIZE(Y), %ymm0, %ymm2
  VMOVX    %ymm2, 4 * SIZE(Z)

#if UNROLL > 8
  vmovupd     8 * SIZE(X), %ymm3
	vfmadd213pd	8 * SIZE(Y), %ymm0, %ymm3
  VMOVX    %ymm3, 8 * SIZE(Z)

  vmovupd     12 * SIZE(X), %ymm4
	vfmadd213pd	12 * SIZE(Y), %ymm0, %ymm4
  VMOVX    %ymm4, 12 * SIZE(Z)

  add $16 * SIZE, X
  add $16 * SIZE, Y
  add $16 * SIZE, Z
#else
  add $8 * SIZE, X
  add $8 * SIZE, Y
  add $8 * SIZE, Z
#endif

  dec I
  jg  .L1
	ALIGN_4

#if UNROLL > 8
.L2:
  test $8, N
  jle .L21

  vmovupd     (X), %ymm1
	vfmadd213pd	(Y), %ymm0, %ymm1
  VMOVX    %ymm1, (Z)

  vmovupd     4 * SIZE(X), %ymm2
	vfmadd213pd	4 * SIZE(Y), %ymm0, %ymm2
  VMOVX    %ymm2, 4 * SIZE(Z)

  add $8 * SIZE, X
  add $8 * SIZE, Y
  add $8 * SIZE, Z
	ALIGN_4
#endif

.L21:
  test $4, N
  jle .L22

  vmovupd     (X), %ymm1
	vfmadd213pd	(Y), %ymm0, %ymm1
  VMOVX    %ymm1, (Z)

  add $4 * SIZE, X
  add $4 * SIZE, Y
  add $4 * SIZE, Z
	ALIGN_4

.L22:
  test $2, N
  jle .L23

  vmovupd     (X), %xmm1
	vfmadd213pd	(Y), %xmm0, %xmm1
  VMOVX    %xmm1, (Z)

  add $2 * SIZE, X
  add $2 * SIZE, Y
  add $2 * SIZE, Z
	ALIGN_4

.L23:
  test $1, N
  jle .L3

  vmovsd     (X), %xmm1
	vfmadd213sd	(Y), %xmm0, %xmm1
  vmovlpd    %xmm1, (Z)

.L3:
  vzeroupper

  ret
  .size  NAME, .-NAME
