CC        = icx -std=c99 -Wall
CPPOPTS   = -DNTRIALS=200
COPTS     = -O3 -fno-alias -fno-builtin -qopenmp -qmkl -xCORE-AVX512 -qopt-zmm-usage=high
LOPTS     = -O3 -fno-builtin -qopenmp -qmkl -xCORE-AVX512 -z noexecstack

#CPPOPTS  += -DALIGNMENT=262144
#COPTS    += -qopt-prefetch=5 -qopt-prefetch-distance=128,16

all: triad-ref-nt.bin triad-opt-avx2-nt.bin triad-opt-avx512-nt.bin \
	 triad-ref-rfo.bin triad-opt-avx2-rfo.bin triad-opt-avx512-rfo.bin

bench_ref_nt.o: bench.c
	$(CC) -DFNAME=triad_ref_nt -c $(CPPOPTS) $(COPTS) -o $@ $<
triad_ref_nt.o: triad_ref.c
	$(CC) -c $(CPPOPTS) $(COPTS) -DFNAME=triad_ref_nt -qopt-streaming-stores=always -o $@ $<
triad-ref-nt.bin: bench_ref_nt.o triad_ref_nt.o
	$(CC) $(LOPTS) -o $@ $^

bench_opt_avx2_nt.o: bench.c
	$(CC) -DFNAME=triad_opt_avx2_nt -c $(CPPOPTS) $(COPTS) -o $@ $<
triad_opt_avx2_nt.o: triad_opt_avx2.S
	$(CC) -c $(CPPOPTS) $(COPTS) -DUSE_NT -o $@ $<
triad-opt-avx2-nt.bin: bench_opt_avx2_nt.o triad_opt_avx2_nt.o
	$(CC) $(LOPTS) -o $@ $^

bench_opt_avx512_nt.o: bench.c
	$(CC) -DFNAME=triad_opt_avx512_nt -c $(CPPOPTS) $(COPTS) -o $@ $<
triad_opt_avx512_nt.o: triad_opt_avx512.S
	$(CC) -c $(CPPOPTS) $(COPTS) -DUSE_NT -o $@ $<
triad-opt-avx512-nt.bin: bench_opt_avx512_nt.o triad_opt_avx512_nt.o
	$(CC) $(LOPTS) -o $@ $^

bench_ref_rfo.o: bench.c
	$(CC) -DFNAME=triad_ref_rfo -c $(CPPOPTS) $(COPTS) -o $@ $<
triad_ref_rfo.o: triad_ref.c
	$(CC) -c $(CPPOPTS) $(COPTS) -DFNAME=triad_ref_rfo -qopt-streaming-stores=never -o $@ $<
triad-ref-rfo.bin: bench_ref_rfo.o triad_ref_rfo.o
	$(CC) $(LOPTS) -o $@ $^

bench_opt_avx2_rfo.o: bench.c
	$(CC) -DFNAME=triad_opt_avx2_rfo -c $(CPPOPTS) $(COPTS) -o $@ $<
triad_opt_avx2_rfo.o: triad_opt_avx2.S
	$(CC) -c $(CPPOPTS) $(COPTS) -DUSE_RFO -o $@ $<
triad-opt-avx2-rfo.bin: bench_opt_avx2_rfo.o triad_opt_avx2_rfo.o
	$(CC) $(LOPTS) -o $@ $^

bench_opt_avx512_rfo.o: bench.c
	$(CC) -DFNAME=triad_opt_avx512_rfo -c $(CPPOPTS) $(COPTS) -o $@ $<
triad_opt_avx512_rfo.o: triad_opt_avx512.S
	$(CC) -c $(CPPOPTS) $(COPTS) -DUSE_RFO -o $@ $<
triad-opt-avx512-rfo.bin: bench_opt_avx512_rfo.o triad_opt_avx512_rfo.o
	$(CC) $(LOPTS) -o $@ $^


clean:
	rm -rf *.o *.bin

.PHONY: all clean 
