#if !defined(HAVE_ACCEPT4) || !defined(SOCK_CLOEXEC) || !defined(SOCK_NONBLOCK)
#  ifndef _GNU_SOURCE
#    define _GNU_SOURCE
#  endif
#  include <sys/types.h>
#  include <sys/socket.h>
#  ifndef SOCK_CLOEXEC
#    if (02000000 == O_NONBLOCK)
#      define SOCK_CLOEXEC 1
#      define SOCK_NONBLOCK 2
#    else
#      define SOCK_CLOEXEC 02000000
#      define SOCK_NONBLOCK O_NONBLOCK
#    endif
#  endif
#endif /* !HAVE_ACCEPT4 */

/* accept4() is currently a Linux-only goodie */
static int
my_accept4(int sockfd, struct sockaddr *addr, socklen_t *addrlen, int flags)
{
	int fd = accept(sockfd, addr, addrlen);

	if (fd >= 0) {
		if ((flags & SOCK_CLOEXEC) == SOCK_CLOEXEC)
			(void)fcntl(fd, F_SETFD, FD_CLOEXEC);

		/*
		 * Some systems inherit O_NONBLOCK across accept().
		 * We also expect our users to use MSG_DONTWAIT under
		 * Linux, so fcntl() is completely unnecessary
		 * in most cases...
		 */
		if ((flags & SOCK_NONBLOCK) == SOCK_NONBLOCK) {
			int fl = fcntl(fd, F_GETFL);

			/*
			 * unconditional, OSX 10.4 (and maybe other *BSDs)
			 * F_GETFL returns a false O_NONBLOCK with TCP sockets
			 * (but not UNIX sockets) [ruby-talk:274079]
			 */
			(void)fcntl(fd, F_SETFL, fl | O_NONBLOCK);
		}

		/*
		 * nothing we can do about fcntl() errors in this wrapper
		 * function, let the user (Ruby) code figure it out
		 */
		errno = 0;
	}
	return fd;
}

typedef int accept_fn_t(int, struct sockaddr *, socklen_t *, int);
#ifdef HAVE_ACCEPT4
static accept_fn_t *accept_fn = accept4;
#else
static accept_fn_t *accept_fn = my_accept4;
#endif
