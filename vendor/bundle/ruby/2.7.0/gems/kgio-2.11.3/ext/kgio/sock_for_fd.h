#ifndef SOCK_FOR_FD_H
#define SOCK_FOR_FD_H
#include <ruby.h>
#ifdef HAVE_RUBY_IO_H
#  include <ruby/io.h>
#else
#  include <stdio.h>
#  include <rubyio.h>
#endif

#if defined(MakeOpenFile) && \
    defined(HAVE_RB_IO_T) && (HAVE_RB_IO_T == 1) && \
    defined(HAVE_RB_IO_ASCII8BIT_BINMODE) && \
    defined(HAVE_ST_FD) && \
    defined(HAVE_ST_MODE)
#  define SOCK_FOR_FD (19)
#  define FMODE_NOREVLOOKUP 0x100
#elif defined(MakeOpenFile) && \
      (defined(OpenFile) || defined(HAVE_RB_IO_T)) && \
      defined(HAVE_RB_FDOPEN) && \
      defined(HAVE_ST_F) && \
      defined(HAVE_ST_F2) && \
      defined(HAVE_ST_MODE)
#  define SOCK_FOR_FD (18)
#else
#  define SOCK_FOR_FD (-1)
#endif

#if SOCK_FOR_FD == 19  /* modeled after ext/socket/init.c */
static VALUE sock_for_fd(VALUE klass, int fd)
{
	VALUE sock;
	rb_io_t *fp;

	rb_update_max_fd(fd); /* 1.9.3+ API */
	sock = rb_obj_alloc(klass);
	MakeOpenFile(sock, fp);
	fp->fd = fd;
	fp->mode = FMODE_READWRITE|FMODE_DUPLEX|FMODE_NOREVLOOKUP;
	rb_io_ascii8bit_binmode(sock);
	rb_io_synchronized(fp);
	return sock;
}
#elif SOCK_FOR_FD == 18 /* modeled after init_sock() in ext/socket/socket.c */
static VALUE sock_for_fd(VALUE klass, int fd)
{
	VALUE sock = rb_obj_alloc(klass);
	OpenFile *fp;

	MakeOpenFile(sock, fp);
	fp->f = rb_fdopen(fd, "r");
	fp->f2 = rb_fdopen(fd, "w");
	fp->mode = FMODE_READWRITE;
	rb_io_synchronized(fp);
	return sock;
}
#else /* Rubinius, et al. */
static ID id_for_fd;
static VALUE sock_for_fd(VALUE klass, int fd)
{
	return rb_funcall(klass, id_for_fd, 1, INT2NUM(fd));
}
static void init_sock_for_fd(void)
{
	id_for_fd = rb_intern("for_fd");
}
#endif /* sock_for_fd */
#if SOCK_FOR_FD > 0
#  define init_sock_for_fd() for (;0;)
#endif
#endif /* SOCK_FOR_FD_H */
