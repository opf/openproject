#ifdef KGIO_WITHOUT_GVL
#  if   defined(HAVE_RB_THREAD_IO_BLOCKING_REGION)
/* temporary API for Ruby 1.9.3 */
VALUE rb_thread_io_blocking_region(rb_blocking_function_t *, void *, int);
#  elif defined(HAVE_RB_THREAD_CALL_WITHOUT_GVL)
#    define rb_thread_io_blocking_region(fn,data,fd) \
            rb_thread_call_without_gvl((fn),(data),RUBY_UBF_IO,0)
#  elif defined(HAVE_RB_THREAD_BLOCKING_REGION)
#    define rb_thread_io_blocking_region(fn,data,fd) \
            rb_thread_blocking_region((fn),(data),RUBY_UBF_IO,0)
#  endif
#endif
