#include "stdlib.h"
#include "stdio.h"
#include "string.h"
#include "math.h"
#include "omp.h"
#include "float.h"
#include "mkl.h"
#include "immintrin.h"

#define MAX_NUM_VECTORS (3)
#define MAX_THREADS     (256)

#ifndef NTRIALS
#define NTRIALS         (100)
#endif

#ifndef ALIGNMENT
#define ALIGNMENT  (64)
#endif

#define SCALAR   (3.0)
#define MAX_PRINT_COUNT  (10)

void FNAME(long long *, double *, double *, double *, double *);

void seq_triad(long long n, long long start, double **p_vectors)
{
  double *p_x = p_vectors[0] + start;
  double *p_y = p_vectors[1] + start;
  double *p_z = p_vectors[2] + start;
  double alpha = SCALAR;

  FNAME(&n, &alpha, p_x, p_y, p_z);
}

void omp_triad(long long n, double **p_vectors)
{
#pragma omp parallel
  {
    int nthrs = omp_get_num_threads();
    int ithr  = omp_get_thread_num();

    long long chunk = ((n/nthrs)/8)*8;
    int rem         = n - (chunk * nthrs);
    int rem_8e = rem/8;
    int tail   = n - (chunk * nthrs) - (rem_8e * 8);
    int start;

    if (ithr < rem_8e) {
      chunk += 8;
      start = ithr * chunk;
    } else {
      start = (ithr * chunk) + (rem_8e * 8);
    }

    if (tail) {
      if (ithr == (nthrs-1)) {
        chunk += tail;
      }
    }

    //printf ("TID=%d, chunk = %ld\n", ithr, chunk);
    seq_triad(chunk, start, p_vectors);
  }
}

int check_results (long long n, double **p_vectors)
{
    double *p_x = p_vectors[0];
    double *p_y = p_vectors[1];
    double *p_z = p_vectors[2];

    for (long long i=0, count=MAX_PRINT_COUNT; i<n; i++) {
      if (i < count) {
        printf ("Index-%ld: Expected = %lf, Observed = %lf\n",
                i, p_y[i] + SCALAR * p_x[i], p_z[i]);
      }
      if (p_z[i] != (p_y[i] + SCALAR * p_x[i])) {
        printf ("Index-%ld: Expected = %lf, Observed = %lf\n",
                i, p_y[i] + SCALAR * p_x[i], p_z[i]);
        return 1;
      }
    }

    return 0;
}

int main (int argc, char **argv)
{
  double *p_vectors[MAX_NUM_VECTORS] = {NULL};
  int num_vectors;
  long long n;

  if (argc != 3) {
    printf ("\nUSAGE: %s num_vectors elems_per_vector\n", argv[0]);
    exit (1);
  }

  num_vectors = atoi(argv[1]);
  n           = atol(argv[2]);

  if (num_vectors > MAX_NUM_VECTORS) {
    printf ("num_vectors = %d is not supported.. exiting..\n",
            num_vectors);
    exit(1);
  }

  double *p_iter_time   = (double *) _mm_malloc(sizeof(double)*NTRIALS, ALIGNMENT);

  for (int i=0; i<num_vectors; i++) {
    p_vectors[i] = (double *) _mm_malloc(sizeof(double)*n, ALIGNMENT);
  }

#pragma omp parallel
  {
    int nthrs = omp_get_num_threads();
    int ithr  = omp_get_thread_num();

    long long chunk = ((n/nthrs)/8)*8;
    int rem         = n - (chunk * nthrs);
    int rem_8e = rem/8;
    int tail   = n - (chunk * nthrs) - (rem_8e * 8);
    int start;

    if (ithr < rem_8e) {
      chunk += 8;
      start = ithr * chunk;
    } else {
      start = (ithr * chunk) + (rem_8e * 8);
    }

    if (tail) {
      if (ithr == (nthrs-1)) {
        chunk += tail;
      }
    }

    double *p_x0 = p_vectors[0] + start;
    for (long long j=0; j<chunk; j++) {
      p_x0[j] = (j%10 + ithr) * (1.0/7.0);
    }

    for (int i=1; i<num_vectors; i++) {
      double *p_xx = p_vectors[i] + start;
      for (long long j=0; j<chunk; j++) {
        p_xx[j] = i + p_x0[j];
      }
    }
  }

  double d_time, d_elapsed;
  d_time = dsecnd();
  d_time = dsecnd();
  double num_bytes_processed = num_vectors * n * sizeof(double);

  for (int i=0; i<NTRIALS; i++) {
    d_time = dsecnd();
    omp_triad(n, p_vectors);
    d_elapsed = dsecnd() - d_time;
    

    p_iter_time[i] = d_elapsed;
    printf ("Iter-%d: GB/s = %.2f\n", i, (num_bytes_processed/d_elapsed)*1.e-09);
    fflush(0);
  }

  double max_bw = FLT_MIN;
  double min_bw = FLT_MAX;
  double total_bw = 0.;

  for (int i=0; i<NTRIALS; i++) {
    double bw = (num_bytes_processed/p_iter_time[i])*1.e-09;
    if (bw > max_bw) {
      max_bw = bw;
    }
    if (bw < min_bw) {
      min_bw = bw;
    }
    total_bw += bw;
  }

  printf ("N = %ld, num_bytes_processed = %.2f GB; %.2f MB, GB/s: min_bw = %.2f, avg_bw = %.2f, max_bw = %.2f\n",
          n, num_bytes_processed*1.e-09, num_bytes_processed*1.e-06, min_bw, total_bw/NTRIALS, max_bw);

  if (check_results(n, p_vectors)) {
    printf ("validation failed!\n");
  } else {
    printf ("validation passed\n");
  }

  for (int i=0; i<num_vectors; i++) {
    _mm_free(p_vectors[i]);
  }
  _mm_free(p_iter_time);

  return 0;
}
