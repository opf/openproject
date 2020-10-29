#ifndef KGIO_H
#define KGIO_H

#include <ruby.h>
#ifdef HAVE_RUBY_IO_H
#  include <ruby/io.h>
#else
#  include <rubyio.h>
#endif
#ifdef HAVE_RUBY_THREAD_H
#  include <ruby/thread.h>
#endif
#include <errno.h>
#include <sys/types.h>
#include <sys/socket.h>
#include <sys/un.h>
#include <netinet/in.h>
#include <fcntl.h>
#include <unistd.h>
#include <arpa/inet.h>
#include <assert.h>
#include <netdb.h>

#include "ancient_ruby.h"

void init_kgio_wait(void);
void init_kgio_read(void);
void init_kgio_write(void);
void init_kgio_writev(void);
void init_kgio_accept(void);
void init_kgio_connect(void);
void init_kgio_autopush(void);
void init_kgio_poll(void);
void init_kgio_tryopen(void);

void kgio_autopush_accept(VALUE, VALUE);
void kgio_autopush_recv(VALUE);
void kgio_autopush_send(VALUE);

VALUE kgio_call_wait_writable(VALUE io);
VALUE kgio_call_wait_readable(VALUE io);
#if defined(HAVE_RB_THREAD_CALL_WITHOUT_GVL) && defined(HAVE_RUBY_THREAD_H)
#  define KGIO_WITHOUT_GVL(fn,data1,ubf,data2) \
      rb_thread_call_without_gvl((fn),(data1),(ubf),(data2))
#elif defined(HAVE_RB_THREAD_BLOCKING_REGION)
typedef  VALUE(*kgio_blocking_fn_t)(void*);
#  define KGIO_WITHOUT_GVL(fn,data1,ubf,data2) \
      rb_thread_blocking_region((kgio_blocking_fn_t)(fn),(data1),(ubf),(data2))
#endif /* HAVE_RB_THREAD_CALL_WITHOUT_GVL || HAVE_RB_THREAD_BLOCKING_REGION */

#if defined(KGIO_WITHOUT_GVL) && defined(HAVE_POLL)
#  define USE_KGIO_POLL
#endif /* USE_KGIO_POLL */

#ifndef HAVE_RB_UPDATE_MAX_FD
#  define rb_update_max_fd(fd) for (;0;)
#endif

/*
 * 2012/12/13 - Linux 3.7 was released on 2012/12/10 with TFO.
 * Headers distributed with glibc will take some time to catch up and
 * be officially released.  Most GNU/Linux distros will take a few months
 * to a year longer. "Enterprise" distros will probably take 5-7 years.
 * So keep these until 2017 at least...
 */
#ifdef __linux__
#  ifndef MSG_FASTOPEN
#    define MSG_FASTOPEN	0x20000000 /* for clients */
#  endif
#  ifndef TCP_FASTOPEN
#    define TCP_FASTOPEN	23 /* for listeners */
#  endif
   /* we _may_ have TFO support */
#  define KGIO_TFO_MAYBE (1)
#else /* rely entirely on standard system headers */
#  define KGIO_TFO_MAYBE (0)
#endif

extern unsigned kgio_tfo;
NORETURN(void kgio_raise_empty_bt(VALUE, const char *));
NORETURN(void kgio_wr_sys_fail(const char *));
NORETURN(void kgio_rd_sys_fail(const char *));

/*
 * we know MSG_DONTWAIT works properly on all stream sockets under Linux
 * we can define this macro for other platforms as people care and
 * notice.
 */
#  if defined(__linux__)
#    define USE_MSG_DONTWAIT
#  endif

#ifdef USE_MSG_DONTWAIT
/* we don't need these variants, we call kgio_autopush_send/recv directly */
static inline void kgio_autopush_write(VALUE io) { }
#else
static inline void kgio_autopush_write(VALUE io) { kgio_autopush_send(io); }
#endif

/* prefer rb_str_subseq because we don't use negative offsets */
#ifndef HAVE_RB_STR_SUBSEQ
#define MY_STR_SUBSEQ(str,beg,len) rb_str_substr((str),(beg),(len))
#else
#define MY_STR_SUBSEQ(str,beg,len) rb_str_subseq((str),(beg),(len))
#endif

#endif /* KGIO_H */
