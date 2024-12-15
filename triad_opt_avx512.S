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
#define NAME   triad_opt_avx512_nt

#elif defined (USE_RFO)
#define VMOVX  vmovupd
#define NAME   triad_opt_avx512_rfo

#else
#error "Store type is undefined"
#endif

//#define PF_LD
//#define PF_ST
//#define PF_LD_ST

#if defined (PF_LD_ST)
#define PF_LD
#define PF_ST
#endif

#define PFLX     prefetcht0
#define PFSX     prefetchw
//#define PFSX     prefetchnta
#define PF_DIST 1024

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
	vbroadcastsd	(ALPHA), %zmm0

  ALIGN_4

.L1:
  vmovupd     (X), %zmm1
	vfmadd213pd	(Y), %zmm0, %zmm1
  VMOVX       %zmm1, (Z)

#ifdef PF_LD
  PFLX      PF_DIST * SIZE(X)
  PFLX      PF_DIST * SIZE(Y)
#endif
#if defined (USE_RFO) && defined (PF_ST)
  PFSX      PF_DIST * SIZE(Z)
#endif

#if UNROLL > 8
  vmovupd     8 * SIZE(X), %zmm2
	vfmadd213pd	8 * SIZE(Y), %zmm0, %zmm2
  VMOVX       %zmm2, 8 * SIZE(Z)

#ifdef PF_LD
  PFLX      (PF_DIST + 8) * SIZE(X)
  PFLX      (PF_DIST + 8) * SIZE(Y)
#endif
#if defined (USE_RFO) && defined (PF_ST)
  PFSX      (PF_DIST + 8) * SIZE(Z)
#endif

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

  vmovupd     (X), %zmm1
	vfmadd213pd	(Y), %zmm0, %zmm1
  VMOVX       %zmm1, (Z)
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
  VMOVX       %ymm1, (Z)
  add $4 * SIZE, X
  add $4 * SIZE, Y
  add $4 * SIZE, Z
	ALIGN_4

.L22:
  test $2, N
  jle .L23

  vmovupd     (X), %xmm1
	vfmadd213pd	(Y), %xmm0, %xmm1
  VMOVX       %xmm1, (Z)
  add $2 * SIZE, X
  add $2 * SIZE, Y
  add $2 * SIZE, Z
	ALIGN_4

.L23:
  test $1, N
  jle .L3

  vmovsd      (X), %xmm1
	vfmadd213sd	(Y), %xmm0, %xmm1
  vmovlpd     %xmm1, (Z)

.L3:
  vzeroupper

  ret
  .size  NAME, .-NAME
