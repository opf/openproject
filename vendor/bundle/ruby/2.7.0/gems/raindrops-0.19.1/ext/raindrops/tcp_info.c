#include <ruby.h>
#include <sys/socket.h>
#include <netinet/in.h>
#if defined(HAVE_LINUX_TCP_H)
#  include <linux/tcp.h>
#else
#  if defined(HAVE_NETINET_TCP_H)
#    include <netinet/tcp.h>
#  endif
#  if defined(HAVE_NETINET_TCP_FSM_H)
#    include <netinet/tcp_fsm.h>
#  endif
#endif

#ifdef HAVE_TYPE_STRUCT_TCP_INFO
#include "my_fileno.h"

CFUNC_tcp_info_tcpi_state
CFUNC_tcp_info_tcpi_ca_state
CFUNC_tcp_info_tcpi_retransmits
CFUNC_tcp_info_tcpi_probes
CFUNC_tcp_info_tcpi_backoff
CFUNC_tcp_info_tcpi_options
CFUNC_tcp_info_tcpi_snd_wscale
CFUNC_tcp_info_tcpi_rcv_wscale
CFUNC_tcp_info_tcpi_rto
CFUNC_tcp_info_tcpi_ato
CFUNC_tcp_info_tcpi_snd_mss
CFUNC_tcp_info_tcpi_rcv_mss
CFUNC_tcp_info_tcpi_unacked
CFUNC_tcp_info_tcpi_sacked
CFUNC_tcp_info_tcpi_lost
CFUNC_tcp_info_tcpi_retrans
CFUNC_tcp_info_tcpi_fackets
CFUNC_tcp_info_tcpi_last_data_sent
CFUNC_tcp_info_tcpi_last_ack_sent
CFUNC_tcp_info_tcpi_last_data_recv
CFUNC_tcp_info_tcpi_last_ack_recv
CFUNC_tcp_info_tcpi_pmtu
CFUNC_tcp_info_tcpi_rcv_ssthresh
CFUNC_tcp_info_tcpi_rtt
CFUNC_tcp_info_tcpi_rttvar
CFUNC_tcp_info_tcpi_snd_ssthresh
CFUNC_tcp_info_tcpi_snd_cwnd
CFUNC_tcp_info_tcpi_advmss
CFUNC_tcp_info_tcpi_reordering
CFUNC_tcp_info_tcpi_rcv_rtt
CFUNC_tcp_info_tcpi_rcv_space
CFUNC_tcp_info_tcpi_total_retrans

static size_t tcpi_memsize(const void *ptr)
{
	return sizeof(struct tcp_info);
}

static const rb_data_type_t tcpi_type = {
	"tcp_info",
	{ NULL, RUBY_TYPED_DEFAULT_FREE, tcpi_memsize, /* reserved */ },
	/* parent, data, [ flags ] */
};

static VALUE alloc(VALUE klass)
{
	struct tcp_info *info;

	return TypedData_Make_Struct(klass, struct tcp_info, &tcpi_type, info);
}

/*
 * call-seq:
 *
 *	Raindrops::TCP_Info.new(tcp_socket)	-> TCP_Info object
 *
 * Reads a TCP_Info object from any given +tcp_socket+.  See the tcp(7)
 * manpage and /usr/include/linux/tcp.h for more details.
 */
static VALUE init(VALUE self, VALUE io)
{
	int fd = my_fileno(io);
	struct tcp_info *info = DATA_PTR(self);
	socklen_t len = (socklen_t)sizeof(struct tcp_info);
	int rc = getsockopt(fd, IPPROTO_TCP, TCP_INFO, info, &len);

	if (rc != 0)
		rb_sys_fail("getsockopt");

	return self;
}

void Init_raindrops_tcp_info(void)
{
	VALUE cRaindrops = rb_define_class("Raindrops", rb_cObject);
	VALUE cTCP_Info;

	/*
	 * Document-class: Raindrops::TCP_Info
	 *
	 * This is used to wrap "struct tcp_info" as described in tcp(7)
	 * and /usr/include/linux/tcp.h.  The following readers methods
	 * are defined corresponding to the "tcpi_" fields in the
	 * tcp_info struct.
	 *
	 * As of raindrops 0.18.0+, this is supported on FreeBSD and OpenBSD
	 * systems as well as Linux, although not all fields exist or
	 * match the documentation, below.
	 *
	 * In particular, the +last_data_recv+ field is useful for measuring
	 * the amount of time a client spent in the listen queue before
	 * +accept()+, but only if +TCP_DEFER_ACCEPT+ is used with the
	 * listen socket (it is on by default in Unicorn).
	 *
	 * - state
	 * - ca_state
	 * - retransmits
	 * - probes
	 * - backoff
	 * - options
	 * - snd_wscale
	 * - rcv_wscale
	 * - rto
	 * - ato
	 * - snd_mss
	 * - rcv_mss
	 * - unacked
	 * - sacked
	 * - lost
	 * - retrans
	 * - fackets
	 * - last_data_sent
	 * - last_ack_sent
	 * - last_data_recv
	 * - last_ack_recv
	 * - pmtu
	 * - rcv_ssthresh
	 * - rtt
	 * - rttvar
	 * - snd_ssthresh
	 * - snd_cwnd
	 * - advmss
	 * - reordering
	 * - rcv_rtt
	 * - rcv_space
	 * - total_retrans
	 *
	 * https://kernel.org/doc/man-pages/online/pages/man7/tcp.7.html
	 */
	cTCP_Info = rb_define_class_under(cRaindrops, "TCP_Info", rb_cObject);
	rb_define_alloc_func(cTCP_Info, alloc);
	rb_define_private_method(cTCP_Info, "initialize", init, 1);

	/*
	 * Document-method: Raindrops::TCP_Info#get!
	 *
	 * call-seq:
	 *
	 *	info = Raindrops::TCP_Info.new(tcp_socket)
	 *	info.get!(tcp_socket)
	 *
	 * Update an existing TCP_Info objects with the latest stats
	 * from the given socket.  This even allows sharing TCP_Info
	 * objects between different sockets to avoid garbage.
	 */
	rb_define_method(cTCP_Info, "get!", init, 1);

	DEFINE_METHOD_tcp_info_tcpi_state;
	DEFINE_METHOD_tcp_info_tcpi_ca_state;
	DEFINE_METHOD_tcp_info_tcpi_retransmits;
	DEFINE_METHOD_tcp_info_tcpi_probes;
	DEFINE_METHOD_tcp_info_tcpi_backoff;
	DEFINE_METHOD_tcp_info_tcpi_options;
	DEFINE_METHOD_tcp_info_tcpi_snd_wscale;
	DEFINE_METHOD_tcp_info_tcpi_rcv_wscale;
	DEFINE_METHOD_tcp_info_tcpi_rto;
	DEFINE_METHOD_tcp_info_tcpi_ato;
	DEFINE_METHOD_tcp_info_tcpi_snd_mss;
	DEFINE_METHOD_tcp_info_tcpi_rcv_mss;
	DEFINE_METHOD_tcp_info_tcpi_unacked;
	DEFINE_METHOD_tcp_info_tcpi_sacked;
	DEFINE_METHOD_tcp_info_tcpi_lost;
	DEFINE_METHOD_tcp_info_tcpi_retrans;
	DEFINE_METHOD_tcp_info_tcpi_fackets;
	DEFINE_METHOD_tcp_info_tcpi_last_data_sent;
	DEFINE_METHOD_tcp_info_tcpi_last_ack_sent;
	DEFINE_METHOD_tcp_info_tcpi_last_data_recv;
	DEFINE_METHOD_tcp_info_tcpi_last_ack_recv;
	DEFINE_METHOD_tcp_info_tcpi_pmtu;
	DEFINE_METHOD_tcp_info_tcpi_rcv_ssthresh;
	DEFINE_METHOD_tcp_info_tcpi_rtt;
	DEFINE_METHOD_tcp_info_tcpi_rttvar;
	DEFINE_METHOD_tcp_info_tcpi_snd_ssthresh;
	DEFINE_METHOD_tcp_info_tcpi_snd_cwnd;
	DEFINE_METHOD_tcp_info_tcpi_advmss;
	DEFINE_METHOD_tcp_info_tcpi_reordering;
	DEFINE_METHOD_tcp_info_tcpi_rcv_rtt;
	DEFINE_METHOD_tcp_info_tcpi_rcv_space;
	DEFINE_METHOD_tcp_info_tcpi_total_retrans;

#ifdef RAINDROPS_TCP_STATES_ALL_KNOWN

	/*
	 * Document-const: Raindrops::TCP
         *
         * This is a frozen hash storing the numeric values
         * maps platform-independent symbol keys to
         * platform-dependent numeric values. These states
         * are all valid values for the Raindrops::TCP_Info#state field.
         *
         * The platform-independent names of the keys in this hash are:
         *
         *  - :ESTABLISHED
         *  - :SYN_SENT
         *  - :SYN_RECV
         *  - :FIN_WAIT1
         *  - :FIN_WAIT2
         *  - :TIME_WAIT
         *  - :CLOSE
         *  - :CLOSE_WAIT
         *  - :LAST_ACK
         *  - :LISTEN
         *  - :CLOSING
         *
         * This is only supported on platforms where TCP_Info is supported,
         * currently FreeBSD, OpenBSD, and Linux-based systems.
         */
	{
#define TCPSET(n,v) rb_hash_aset(tcp, ID2SYM(rb_intern(#n)), INT2NUM(v))
		VALUE tcp = rb_hash_new();
		TCPSET(ESTABLISHED, RAINDROPS_TCP_ESTABLISHED);
		TCPSET(SYN_SENT, RAINDROPS_TCP_SYN_SENT);
		TCPSET(SYN_RECV, RAINDROPS_TCP_SYN_RECV);
		TCPSET(FIN_WAIT1, RAINDROPS_TCP_FIN_WAIT1);
		TCPSET(FIN_WAIT2, RAINDROPS_TCP_FIN_WAIT2);
		TCPSET(TIME_WAIT, RAINDROPS_TCP_TIME_WAIT);
		TCPSET(CLOSE, RAINDROPS_TCP_CLOSE);
		TCPSET(CLOSE_WAIT, RAINDROPS_TCP_CLOSE_WAIT);
		TCPSET(LAST_ACK, RAINDROPS_TCP_LAST_ACK);
		TCPSET(LISTEN, RAINDROPS_TCP_LISTEN);
		TCPSET(CLOSING, RAINDROPS_TCP_CLOSING);
#undef TCPSET
		OBJ_FREEZE(tcp);
		rb_define_const(cRaindrops, "TCP", tcp);
	}
#endif
}
#endif /* HAVE_STRUCT_TCP_INFO */
