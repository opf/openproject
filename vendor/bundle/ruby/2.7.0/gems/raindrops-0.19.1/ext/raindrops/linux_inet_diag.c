#include <ruby.h>
#include <stdarg.h>
#include <ruby/st.h>
#include "my_fileno.h"
#ifdef __linux__

#ifdef HAVE_RB_THREAD_IO_BLOCKING_REGION
/* Ruby 1.9.3 and 2.0.0 */
VALUE rb_thread_io_blocking_region(rb_blocking_function_t *, void *, int);
#  define rd_fd_region(fn,data,fd) \
	rb_thread_io_blocking_region((fn),(data),(fd))
#elif defined(HAVE_RB_THREAD_CALL_WITHOUT_GVL) && \
	defined(HAVE_RUBY_THREAD_H) && HAVE_RUBY_THREAD_H
/* in case Ruby 2.0+ ever drops rb_thread_io_blocking_region: */
#  include <ruby/thread.h>
#  define COMPAT_FN (void *(*)(void *))
#  define rd_fd_region(fn,data,fd) \
	rb_thread_call_without_gvl(COMPAT_FN(fn),(data),RUBY_UBF_IO,NULL)
#else
#  error Ruby <= 1.8 not supported
#endif

#include <assert.h>
#include <errno.h>
#include <sys/socket.h>
#include <sys/types.h>
#include <netdb.h>
#include <unistd.h>
#include <fcntl.h>
#include <string.h>
#include <asm/types.h>
#include <netinet/in.h>
#include <arpa/inet.h>
#include <netinet/tcp.h>
#include <linux/netlink.h>
#include <linux/rtnetlink.h>
#include <linux/inet_diag.h>

union any_addr {
	struct sockaddr_storage ss;
	struct sockaddr sa;
	struct sockaddr_in in;
	struct sockaddr_in6 in6;
};

static size_t page_size;
static unsigned g_seq;
static VALUE cListenStats, cIDSock;
static ID id_new;

struct listen_stats {
	uint32_t active;
	uint32_t queued;
	uint32_t listener_p;
};

#define OPLEN (sizeof(struct inet_diag_bc_op) + \
	       sizeof(struct inet_diag_hostcond) + \
	       sizeof(struct sockaddr_storage))

struct nogvl_args {
	st_table *table;
	struct iovec iov[3]; /* last iov holds inet_diag bytecode */
	struct listen_stats stats;
	int fd;
};

#ifdef SOCK_CLOEXEC
#  define my_SOCK_RAW (SOCK_RAW|SOCK_CLOEXEC)
#  define FORCE_CLOEXEC(v) (v)
#else
#  define my_SOCK_RAW SOCK_RAW
static VALUE FORCE_CLOEXEC(VALUE io)
{
	int fd = my_fileno(io);
	int flags = fcntl(fd, F_SETFD, FD_CLOEXEC);
	if (flags == -1)
		rb_sys_fail("fcntl(F_SETFD, FD_CLOEXEC)");
	return io;
}
#endif

/*
 * call-seq:
 *	Raindrops::InetDiagSocket.new	-> Socket
 *
 * Creates a new Socket object for the netlink inet_diag facility
 */
static VALUE ids_s_new(VALUE klass)
{
	VALUE argv[3];

	argv[0] = INT2NUM(AF_NETLINK);
	argv[1] = INT2NUM(my_SOCK_RAW);
	argv[2] = INT2NUM(NETLINK_INET_DIAG);

	return FORCE_CLOEXEC(rb_call_super(3, argv));
}

/* creates a Ruby ListenStats Struct based on our internal listen_stats */
static VALUE rb_listen_stats(struct listen_stats *stats)
{
	VALUE active = UINT2NUM(stats->active);
	VALUE queued = UINT2NUM(stats->queued);

	return rb_struct_new(cListenStats, active, queued);
}

static int st_free_data(st_data_t key, st_data_t value, st_data_t ignored)
{
	xfree((void *)key);
	xfree((void *)value);

	return ST_DELETE;
}

/*
 * call-seq:
 *      remove_scope_id(ip_address)
 *
 * Returns copy of IP address with Scope ID removed,
 * if address has it (only IPv6 actually may have it).
 */
static VALUE remove_scope_id(const char *addr)
{
	VALUE rv = rb_str_new2(addr);
	long len = RSTRING_LEN(rv);
	char *ptr = RSTRING_PTR(rv);
	char *pct = memchr(ptr, '%', len);

	/*
	 * remove scoped portion
	 * Ruby equivalent: rv.sub!(/%([^\]]*)\]/, "]")
	 */
	if (pct) {
		size_t newlen = pct - ptr;
		char *rbracket = memchr(pct, ']', len - newlen);

		if (rbracket) {
			size_t move = len - (rbracket - ptr);

			memmove(pct, rbracket, move);
			newlen += move;

			rb_str_set_len(rv, newlen);
		} else {
			rb_raise(rb_eArgError,
				"']' not found in IPv6 addr=%s", ptr);
                }
        }
        return rv;
}

static int st_to_hash(st_data_t key, st_data_t value, VALUE hash)
{
	struct listen_stats *stats = (struct listen_stats *)value;

	if (stats->listener_p) {
		VALUE k = remove_scope_id((const char *)key);
		VALUE v = rb_listen_stats(stats);

		OBJ_FREEZE(k);
		rb_hash_aset(hash, k, v);
	}
	return st_free_data(key, value, 0);
}

static int st_AND_hash(st_data_t key, st_data_t value, VALUE hash)
{
	struct listen_stats *stats = (struct listen_stats *)value;

	if (stats->listener_p) {
		VALUE k = remove_scope_id((const char *)key);

		if (rb_hash_lookup(hash, k) == Qtrue) {
			VALUE v = rb_listen_stats(stats);
			OBJ_FREEZE(k);
			rb_hash_aset(hash, k, v);
		}
	}
	return st_free_data(key, value, 0);
}

static const char *addr_any(sa_family_t family)
{
	static const char ipv4[] = "0.0.0.0";
	static const char ipv6[] = "[::]";

	if (family == AF_INET)
		return ipv4;
	assert(family == AF_INET6 && "unknown family");
	return ipv6;
}

#ifdef __GNUC__
static void bug_warn_nogvl(const char *, ...)
	__attribute__((format(printf,1,2)));
#endif
static void bug_warn_nogvl(const char *fmt, ...)
{
	va_list ap;

	va_start(ap, fmt);
	vfprintf(stderr, fmt, ap);
	va_end(ap);

	fprintf(stderr, "Please report how you produced this at "\
	                "raindrops-public@yhbt.net\n");
	fflush(stderr);
}

static struct listen_stats *stats_for(st_table *table, struct inet_diag_msg *r)
{
	char *host, *key, *port, *old_key;
	size_t alloca_len;
	struct listen_stats *stats;
	socklen_t hostlen;
	socklen_t portlen = (socklen_t)sizeof("65535");
	int n;
	const void *src = r->id.idiag_src;

	switch (r->idiag_family) {
	case AF_INET: {
		hostlen = INET_ADDRSTRLEN;
		alloca_len = hostlen + portlen;
		host = key = alloca(alloca_len);
		break;
		}
	case AF_INET6: {
		hostlen = INET6_ADDRSTRLEN;
		alloca_len = 1 + hostlen + 1 + portlen;
		key = alloca(alloca_len);
		host = key + 1;
		break;
		}
	default:
		assert(0 && "unsupported address family, could that be IPv7?!");
	}
	if (!inet_ntop(r->idiag_family, src, host, hostlen)) {
		bug_warn_nogvl("BUG: inet_ntop: %s\n", strerror(errno));
		*key = '\0';
		*host = '\0';
	}
	hostlen = (socklen_t)strlen(host);
	switch (r->idiag_family) {
	case AF_INET:
		host[hostlen] = ':';
		port = host + hostlen + 1;
		break;
	case AF_INET6:
		key[0] = '[';
		host[hostlen] = ']';
		host[hostlen + 1] = ':';
		port = host + hostlen + 2;
		break;
	default:
		assert(0 && "unsupported address family, could that be IPv7?!");
	}

	n = snprintf(port, portlen, "%u", ntohs(r->id.idiag_sport));
	if (n <= 0) {
		bug_warn_nogvl("BUG: snprintf port: %d\n", n);
		*key = '\0';
	}

	if (st_lookup(table, (st_data_t)key, (st_data_t *)&stats))
		return stats;

	old_key = key;

	if (r->idiag_state == TCP_ESTABLISHED) {
		n = snprintf(key, alloca_len, "%s:%u",
				 addr_any(r->idiag_family),
				 ntohs(r->id.idiag_sport));
		if (n <= 0) {
			bug_warn_nogvl("BUG: snprintf: %d\n", n);
			*key = '\0';
		}
		if (st_lookup(table, (st_data_t)key, (st_data_t *)&stats))
			return stats;
		if (n <= 0) {
			key = xmalloc(1);
			*key = '\0';
		} else {
			old_key = key;
			key = xmalloc(n + 1);
			memcpy(key, old_key, n + 1);
		}
	} else {
		size_t old_len = strlen(old_key) + 1;
		key = xmalloc(old_len);
		memcpy(key, old_key, old_len);
	}
	stats = xcalloc(1, sizeof(struct listen_stats));
	st_insert(table, (st_data_t)key, (st_data_t)stats);
	return stats;
}

static void table_incr_active(st_table *table, struct inet_diag_msg *r)
{
	struct listen_stats *stats = stats_for(table, r);
	++stats->active;
}

static void table_set_queued(st_table *table, struct inet_diag_msg *r)
{
	struct listen_stats *stats = stats_for(table, r);
	stats->listener_p = 1;
	stats->queued = r->idiag_rqueue;
}

/* inner loop of inet_diag, called for every socket returned by netlink */
static inline void r_acc(struct nogvl_args *args, struct inet_diag_msg *r)
{
	/*
	 * inode == 0 means the connection is still in the listen queue
	 * and has not yet been accept()-ed by the server.  The
	 * inet_diag bytecode cannot filter this for us.
	 */
	if (r->idiag_inode == 0)
		return;
	if (r->idiag_state == TCP_ESTABLISHED) {
		if (args->table)
			table_incr_active(args->table, r);
		else
			args->stats.active++;
	} else { /* if (r->idiag_state == TCP_LISTEN) */
		if (args->table)
			table_set_queued(args->table, r);
		else
			args->stats.queued = r->idiag_rqueue;
	}
	/*
	 * we wont get anything else because of the idiag_states filter
	 */
}

static const char err_sendmsg[] = "sendmsg";
static const char err_recvmsg[] = "recvmsg";
static const char err_nlmsg[] = "nlmsg";

struct diag_req {
	struct nlmsghdr nlh;
	struct inet_diag_req r;
};

static void prep_msghdr(
	struct msghdr *msg,
	struct nogvl_args *args,
	struct sockaddr_nl *nladdr,
	size_t iovlen)
{
	memset(msg, 0, sizeof(struct msghdr));
	msg->msg_name = (void *)nladdr;
	msg->msg_namelen = sizeof(struct sockaddr_nl);
	msg->msg_iov = args->iov;
	msg->msg_iovlen = iovlen;
}

static void prep_diag_args(
	struct nogvl_args *args,
	struct sockaddr_nl *nladdr,
	struct rtattr *rta,
	struct diag_req *req,
	struct msghdr *msg)
{
	memset(req, 0, sizeof(struct diag_req));
	memset(nladdr, 0, sizeof(struct sockaddr_nl));

	nladdr->nl_family = AF_NETLINK;

	req->nlh.nlmsg_len = (unsigned int)(sizeof(struct diag_req) +
	                    RTA_LENGTH(args->iov[2].iov_len));
	req->nlh.nlmsg_type = TCPDIAG_GETSOCK;
	req->nlh.nlmsg_flags = NLM_F_ROOT | NLM_F_MATCH | NLM_F_REQUEST;
	req->nlh.nlmsg_pid = getpid();
	req->r.idiag_states = (1<<TCP_ESTABLISHED) | (1<<TCP_LISTEN);
	rta->rta_type = INET_DIAG_REQ_BYTECODE;
	rta->rta_len = RTA_LENGTH(args->iov[2].iov_len);

	args->iov[0].iov_base = req;
	args->iov[0].iov_len = sizeof(struct diag_req);
	args->iov[1].iov_base = rta;
	args->iov[1].iov_len = sizeof(struct rtattr);

	prep_msghdr(msg, args, nladdr, 3);
}

static void prep_recvmsg_buf(struct nogvl_args *args)
{
	/* reuse buffer that was allocated for bytecode */
	args->iov[0].iov_len = page_size;
	args->iov[0].iov_base = args->iov[2].iov_base;
}

/* does the inet_diag stuff with netlink(), this is called w/o GVL */
static VALUE diag(void *ptr)
{
	struct nogvl_args *args = ptr;
	struct sockaddr_nl nladdr;
	struct rtattr rta;
	struct diag_req req;
	struct msghdr msg;
	const char *err = NULL;
	unsigned seq = ++g_seq;

	prep_diag_args(args, &nladdr, &rta, &req, &msg);
	req.nlh.nlmsg_seq = seq;

	if (sendmsg(args->fd, &msg, 0) < 0) {
		err = err_sendmsg;
		goto out;
	}

	prep_recvmsg_buf(args);

	while (1) {
		ssize_t readed;
		size_t r;
		struct nlmsghdr *h = (struct nlmsghdr *)args->iov[0].iov_base;

		prep_msghdr(&msg, args, &nladdr, 1);
		readed = recvmsg(args->fd, &msg, 0);
		if (readed < 0) {
			if (errno == EINTR)
				continue;
			err = err_recvmsg;
			goto out;
		}
		if (readed == 0)
			goto out;
		r = (size_t)readed;
		for ( ; NLMSG_OK(h, r); h = NLMSG_NEXT(h, r)) {
			if (h->nlmsg_seq != seq)
				continue;
			if (h->nlmsg_type == NLMSG_DONE)
				goto out;
			if (h->nlmsg_type == NLMSG_ERROR) {
				err = err_nlmsg;
				goto out;
			}
			r_acc(args, NLMSG_DATA(h));
		}
	}
out:
	/* prepare to raise, free memory before reacquiring GVL */
	if (err && args->table) {
		int save_errno = errno;

		st_foreach(args->table, st_free_data, 0);
		st_free_table(args->table);
		errno = save_errno;
	}
	return (VALUE)err;
}

/* populates sockaddr_storage struct by parsing +addr+ */
static void parse_addr(union any_addr *inet, VALUE addr)
{
	char *host_ptr;
	char *check;
	char *colon = NULL;
	char *rbracket = NULL;
	void *dst;
	long host_len;
	int af, rc;
	uint16_t *portdst;
	unsigned long port;

	Check_Type(addr, T_STRING);
	host_ptr = StringValueCStr(addr);
	host_len = RSTRING_LEN(addr);
	if (*host_ptr == '[') { /* ipv6 address format (rfc2732) */
		rbracket = memchr(host_ptr + 1, ']', host_len - 1);

		if (rbracket == NULL)
			rb_raise(rb_eArgError, "']' not found in IPv6 addr=%s",
			         host_ptr);
		if (rbracket[1] != ':')
			rb_raise(rb_eArgError, "':' not found in IPv6 addr=%s",
			         host_ptr);
		colon = rbracket + 1;
		host_ptr++;
		*rbracket = 0;
		inet->ss.ss_family = af = AF_INET6;
		dst = &inet->in6.sin6_addr;
		portdst = &inet->in6.sin6_port;
	} else { /* ipv4 */
		colon = memchr(host_ptr, ':', host_len);
		inet->ss.ss_family = af = AF_INET;
		dst = &inet->in.sin_addr;
		portdst = &inet->in.sin_port;
	}

	if (!colon)
		rb_raise(rb_eArgError, "port not found in: `%s'", host_ptr);
	port = strtoul(colon + 1, &check, 10);
	*colon = 0;
	rc = inet_pton(af, host_ptr, dst);
	*colon = ':';
	if (rbracket) *rbracket = ']';
	if (*check || ((uint16_t)port != port))
		rb_raise(rb_eArgError, "invalid port: %s", colon + 1);
	if (rc != 1)
		rb_raise(rb_eArgError, "inet_pton failed for: `%s' with %d",
		         host_ptr, rc);
	*portdst = ntohs((uint16_t)port);
}

/* generates inet_diag bytecode to match all addrs */
static void gen_bytecode_all(struct iovec *iov)
{
	struct inet_diag_bc_op *op;
	struct inet_diag_hostcond *cond;

	/* iov_len was already set and base allocated in a parent function */
	assert(iov->iov_len == OPLEN && iov->iov_base && "iov invalid");
	op = iov->iov_base;
	op->code = INET_DIAG_BC_S_COND;
	op->yes = OPLEN;
	op->no = sizeof(struct inet_diag_bc_op) + OPLEN;
	cond = (struct inet_diag_hostcond *)(op + 1);
	cond->family = AF_UNSPEC;
	cond->port = -1;
	cond->prefix_len = 0;
}

/* generates inet_diag bytecode to match a single addr */
static void gen_bytecode(struct iovec *iov, union any_addr *inet)
{
	struct inet_diag_bc_op *op;
	struct inet_diag_hostcond *cond;

	/* iov_len was already set and base allocated in a parent function */
	assert(iov->iov_len == OPLEN && iov->iov_base && "iov invalid");
	op = iov->iov_base;
	op->code = INET_DIAG_BC_S_COND;
	op->yes = OPLEN;
	op->no = sizeof(struct inet_diag_bc_op) + OPLEN;

	cond = (struct inet_diag_hostcond *)(op + 1);
	cond->family = inet->ss.ss_family;
	switch (inet->ss.ss_family) {
	case AF_INET: {
		cond->port = ntohs(inet->in.sin_port);
		cond->prefix_len = inet->in.sin_addr.s_addr == 0 ? 0 :
				   sizeof(inet->in.sin_addr.s_addr) * CHAR_BIT;
		*cond->addr = inet->in.sin_addr.s_addr;
		}
		break;
	case AF_INET6: {
		cond->port = ntohs(inet->in6.sin6_port);
		cond->prefix_len = memcmp(&in6addr_any, &inet->in6.sin6_addr,
				          sizeof(struct in6_addr)) == 0 ?
				  0 : sizeof(inet->in6.sin6_addr) * CHAR_BIT;
		memcpy(&cond->addr, &inet->in6.sin6_addr,
		       sizeof(struct in6_addr));
		}
		break;
	default:
		assert(0 && "unsupported address family, could that be IPv7?!");
	}
}

/*
 * n.b. we may safely raise here because an error will cause diag()
 * to free args->table
 */
static void nl_errcheck(VALUE r)
{
	const char *err = (const char *)r;

	if (err) {
		if (err == err_nlmsg)
			rb_raise(rb_eRuntimeError, "NLMSG_ERROR");
		else
			rb_sys_fail(err);
	}
}

static VALUE tcp_stats(struct nogvl_args *args, VALUE addr)
{
	union any_addr query_addr;

	parse_addr(&query_addr, addr);
	gen_bytecode(&args->iov[2], &query_addr);

	memset(&args->stats, 0, sizeof(struct listen_stats));
	nl_errcheck(rd_fd_region(diag, args, args->fd));

	return rb_listen_stats(&args->stats);
}

static int drop_placeholders(st_data_t k, st_data_t v, st_data_t ign)
{
	if ((VALUE)v == Qtrue)
		return ST_DELETE;
	return ST_CONTINUE;
}

/*
 * call-seq:
 *      Raindrops::Linux.tcp_listener_stats([addrs[, sock]]) => hash
 *
 * If specified, +addr+ may be a string or array of strings representing
 * listen addresses to filter for. Returns a hash with given addresses as
 * keys and ListenStats objects as the values or a hash of all addresses.
 *
 *      addrs = %w(0.0.0.0:80 127.0.0.1:8080)
 *
 * If +addr+ is nil or not specified, all (IPv4) addresses are returned.
 * If +sock+ is specified, it should be a Raindrops::InetDiagSock object.
 */
static VALUE tcp_listener_stats(int argc, VALUE *argv, VALUE self)
{
	VALUE rv = rb_hash_new();
	struct nogvl_args args;
	VALUE addrs, sock;

	rb_scan_args(argc, argv, "02", &addrs, &sock);

	/*
	 * allocating page_size instead of OP_LEN since we'll reuse the
	 * buffer for recvmsg() later, we already checked for
	 * OPLEN <= page_size at initialization
	 */
	args.iov[2].iov_len = OPLEN;
	args.iov[2].iov_base = alloca(page_size);
	args.table = NULL;
	if (NIL_P(sock))
		sock = rb_funcall(cIDSock, id_new, 0);
	args.fd = my_fileno(sock);

	switch (TYPE(addrs)) {
	case T_STRING:
		rb_hash_aset(rv, addrs, tcp_stats(&args, addrs));
		return rv;
	case T_ARRAY: {
		long i;
		long len = RARRAY_LEN(addrs);

		if (len == 1) {
			VALUE cur = rb_ary_entry(addrs, 0);

			rb_hash_aset(rv, cur, tcp_stats(&args, cur));
			return rv;
		}
		for (i = 0; i < len; i++) {
			union any_addr check;
			VALUE cur = rb_ary_entry(addrs, i);

			parse_addr(&check, cur);
			rb_hash_aset(rv, cur, Qtrue /* placeholder */);
		}
		/* fall through */
	}
	case T_NIL:
		args.table = st_init_strtable();
		gen_bytecode_all(&args.iov[2]);
		break;
	default:
		rb_raise(rb_eArgError,
		         "addr must be an array of strings, a string, or nil");
	}

	nl_errcheck(rd_fd_region(diag, &args, args.fd));

	st_foreach(args.table, NIL_P(addrs) ? st_to_hash : st_AND_hash, rv);
	st_free_table(args.table);

	if (RHASH_SIZE(rv) > 1)
		rb_hash_foreach(rv, drop_placeholders, Qfalse);

	/* let GC deal with corner cases */
	if (argc < 2) rb_io_close(sock);
	return rv;
}

void Init_raindrops_linux_inet_diag(void)
{
	VALUE cRaindrops = rb_define_class("Raindrops", rb_cObject);
	VALUE mLinux = rb_define_module_under(cRaindrops, "Linux");
	VALUE Socket;

	rb_require("socket");
	Socket = rb_const_get(rb_cObject, rb_intern("Socket"));
	id_new = rb_intern("new");

	/*
	 * Document-class: Raindrops::InetDiagSocket
	 *
	 * This is a subclass of +Socket+ specifically for talking
	 * to the inet_diag facility of Netlink.
	 */
	cIDSock = rb_define_class_under(cRaindrops, "InetDiagSocket", Socket);
	rb_define_singleton_method(cIDSock, "new", ids_s_new, 0);

	cListenStats = rb_const_get(cRaindrops, rb_intern("ListenStats"));

	rb_define_module_function(mLinux, "tcp_listener_stats",
	                          tcp_listener_stats, -1);

	page_size = getpagesize();

	assert(OPLEN <= page_size && "bytecode OPLEN is not <= PAGE_SIZE");
}
#endif /* __linux__ */
