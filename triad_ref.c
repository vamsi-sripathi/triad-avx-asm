void FNAME(long long *p_n, double *p_alpha, double *p_x, double *p_y, double *p_z)
{

  long long n  = *p_n;
  double alpha = *p_alpha;

#pragma unroll(2)
#if FNAME == triad_ref_nt
#pragma vector always dynamic_align nontemporal
#else
#pragma vector always
#endif
  for (long long i=0; i<n; i++) {
    p_z[i] = p_y[i] + alpha * p_x[i];
  }
}
