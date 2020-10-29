#include <ruby.h>
#include <unistd.h>
#include <fcntl.h>
static void set_nonblocking(int fd)
{
	int flags = fcntl(fd, F_GETFL);

	/*
	 * do not check < 0 here, one day we may have enough FD flags
	 * to require negative bit
	 */
	if (flags == -1)
		rb_sys_fail("fcntl(F_GETFL)");
	if ((flags & O_NONBLOCK) == O_NONBLOCK)
		return;
	flags = fcntl(fd, F_SETFL, flags | O_NONBLOCK);
	if (flags < 0)
		rb_sys_fail("fcntl(F_SETFL)");
}
