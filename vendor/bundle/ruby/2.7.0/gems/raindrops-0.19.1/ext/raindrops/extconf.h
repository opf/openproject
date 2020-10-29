#ifndef EXTCONF_H
#define EXTCONF_H
#define HAVE_MMAP 1
#define HAVE_MUNMAP 1
#define HAVE_MREMAP 1
#define HAVE_LINUX_TCP_H 1
#define HAVE_TYPE_STRUCT_TCP_INFO 1
#define HAVE_STRUCT_TCP_INFO_TCPI_STATE 1
#define HAVE_ST_TCPI_STATE 1
#define CFUNC_tcp_info_tcpi_state static VALUE tcp_info_tcpi_state(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_state);}
#define DEFINE_METHOD_tcp_info_tcpi_state rb_define_method(cTCP_Info,"state",tcp_info_tcpi_state,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_CA_STATE 1
#define HAVE_ST_TCPI_CA_STATE 1
#define CFUNC_tcp_info_tcpi_ca_state static VALUE tcp_info_tcpi_ca_state(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_ca_state);}
#define DEFINE_METHOD_tcp_info_tcpi_ca_state rb_define_method(cTCP_Info,"ca_state",tcp_info_tcpi_ca_state,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_RETRANSMITS 1
#define HAVE_ST_TCPI_RETRANSMITS 1
#define CFUNC_tcp_info_tcpi_retransmits static VALUE tcp_info_tcpi_retransmits(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_retransmits);}
#define DEFINE_METHOD_tcp_info_tcpi_retransmits rb_define_method(cTCP_Info,"retransmits",tcp_info_tcpi_retransmits,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_PROBES 1
#define HAVE_ST_TCPI_PROBES 1
#define CFUNC_tcp_info_tcpi_probes static VALUE tcp_info_tcpi_probes(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_probes);}
#define DEFINE_METHOD_tcp_info_tcpi_probes rb_define_method(cTCP_Info,"probes",tcp_info_tcpi_probes,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_BACKOFF 1
#define HAVE_ST_TCPI_BACKOFF 1
#define CFUNC_tcp_info_tcpi_backoff static VALUE tcp_info_tcpi_backoff(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_backoff);}
#define DEFINE_METHOD_tcp_info_tcpi_backoff rb_define_method(cTCP_Info,"backoff",tcp_info_tcpi_backoff,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_OPTIONS 1
#define HAVE_ST_TCPI_OPTIONS 1
#define CFUNC_tcp_info_tcpi_options static VALUE tcp_info_tcpi_options(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_options);}
#define DEFINE_METHOD_tcp_info_tcpi_options rb_define_method(cTCP_Info,"options",tcp_info_tcpi_options,0)
#define CFUNC_tcp_info_tcpi_snd_wscale static inline void tcp_info_tcpi_snd_wscale(void) {}
#define DEFINE_METHOD_tcp_info_tcpi_snd_wscale rb_define_method(cTCP_Info,"snd_wscale",rb_f_notimplement,0)
#define CFUNC_tcp_info_tcpi_rcv_wscale static inline void tcp_info_tcpi_rcv_wscale(void) {}
#define DEFINE_METHOD_tcp_info_tcpi_rcv_wscale rb_define_method(cTCP_Info,"rcv_wscale",rb_f_notimplement,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_RTO 1
#define HAVE_ST_TCPI_RTO 1
#define CFUNC_tcp_info_tcpi_rto static VALUE tcp_info_tcpi_rto(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_rto);}
#define DEFINE_METHOD_tcp_info_tcpi_rto rb_define_method(cTCP_Info,"rto",tcp_info_tcpi_rto,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_ATO 1
#define HAVE_ST_TCPI_ATO 1
#define CFUNC_tcp_info_tcpi_ato static VALUE tcp_info_tcpi_ato(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_ato);}
#define DEFINE_METHOD_tcp_info_tcpi_ato rb_define_method(cTCP_Info,"ato",tcp_info_tcpi_ato,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_SND_MSS 1
#define HAVE_ST_TCPI_SND_MSS 1
#define CFUNC_tcp_info_tcpi_snd_mss static VALUE tcp_info_tcpi_snd_mss(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_snd_mss);}
#define DEFINE_METHOD_tcp_info_tcpi_snd_mss rb_define_method(cTCP_Info,"snd_mss",tcp_info_tcpi_snd_mss,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_RCV_MSS 1
#define HAVE_ST_TCPI_RCV_MSS 1
#define CFUNC_tcp_info_tcpi_rcv_mss static VALUE tcp_info_tcpi_rcv_mss(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_rcv_mss);}
#define DEFINE_METHOD_tcp_info_tcpi_rcv_mss rb_define_method(cTCP_Info,"rcv_mss",tcp_info_tcpi_rcv_mss,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_UNACKED 1
#define HAVE_ST_TCPI_UNACKED 1
#define CFUNC_tcp_info_tcpi_unacked static VALUE tcp_info_tcpi_unacked(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_unacked);}
#define DEFINE_METHOD_tcp_info_tcpi_unacked rb_define_method(cTCP_Info,"unacked",tcp_info_tcpi_unacked,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_SACKED 1
#define HAVE_ST_TCPI_SACKED 1
#define CFUNC_tcp_info_tcpi_sacked static VALUE tcp_info_tcpi_sacked(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_sacked);}
#define DEFINE_METHOD_tcp_info_tcpi_sacked rb_define_method(cTCP_Info,"sacked",tcp_info_tcpi_sacked,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_LOST 1
#define HAVE_ST_TCPI_LOST 1
#define CFUNC_tcp_info_tcpi_lost static VALUE tcp_info_tcpi_lost(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_lost);}
#define DEFINE_METHOD_tcp_info_tcpi_lost rb_define_method(cTCP_Info,"lost",tcp_info_tcpi_lost,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_RETRANS 1
#define HAVE_ST_TCPI_RETRANS 1
#define CFUNC_tcp_info_tcpi_retrans static VALUE tcp_info_tcpi_retrans(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_retrans);}
#define DEFINE_METHOD_tcp_info_tcpi_retrans rb_define_method(cTCP_Info,"retrans",tcp_info_tcpi_retrans,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_FACKETS 1
#define HAVE_ST_TCPI_FACKETS 1
#define CFUNC_tcp_info_tcpi_fackets static VALUE tcp_info_tcpi_fackets(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_fackets);}
#define DEFINE_METHOD_tcp_info_tcpi_fackets rb_define_method(cTCP_Info,"fackets",tcp_info_tcpi_fackets,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_LAST_DATA_SENT 1
#define HAVE_ST_TCPI_LAST_DATA_SENT 1
#define CFUNC_tcp_info_tcpi_last_data_sent static VALUE tcp_info_tcpi_last_data_sent(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_last_data_sent);}
#define DEFINE_METHOD_tcp_info_tcpi_last_data_sent rb_define_method(cTCP_Info,"last_data_sent",tcp_info_tcpi_last_data_sent,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_LAST_ACK_SENT 1
#define HAVE_ST_TCPI_LAST_ACK_SENT 1
#define CFUNC_tcp_info_tcpi_last_ack_sent static VALUE tcp_info_tcpi_last_ack_sent(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_last_ack_sent);}
#define DEFINE_METHOD_tcp_info_tcpi_last_ack_sent rb_define_method(cTCP_Info,"last_ack_sent",tcp_info_tcpi_last_ack_sent,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_LAST_DATA_RECV 1
#define HAVE_ST_TCPI_LAST_DATA_RECV 1
#define CFUNC_tcp_info_tcpi_last_data_recv static VALUE tcp_info_tcpi_last_data_recv(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_last_data_recv);}
#define DEFINE_METHOD_tcp_info_tcpi_last_data_recv rb_define_method(cTCP_Info,"last_data_recv",tcp_info_tcpi_last_data_recv,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_LAST_ACK_RECV 1
#define HAVE_ST_TCPI_LAST_ACK_RECV 1
#define CFUNC_tcp_info_tcpi_last_ack_recv static VALUE tcp_info_tcpi_last_ack_recv(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_last_ack_recv);}
#define DEFINE_METHOD_tcp_info_tcpi_last_ack_recv rb_define_method(cTCP_Info,"last_ack_recv",tcp_info_tcpi_last_ack_recv,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_PMTU 1
#define HAVE_ST_TCPI_PMTU 1
#define CFUNC_tcp_info_tcpi_pmtu static VALUE tcp_info_tcpi_pmtu(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_pmtu);}
#define DEFINE_METHOD_tcp_info_tcpi_pmtu rb_define_method(cTCP_Info,"pmtu",tcp_info_tcpi_pmtu,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_RCV_SSTHRESH 1
#define HAVE_ST_TCPI_RCV_SSTHRESH 1
#define CFUNC_tcp_info_tcpi_rcv_ssthresh static VALUE tcp_info_tcpi_rcv_ssthresh(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_rcv_ssthresh);}
#define DEFINE_METHOD_tcp_info_tcpi_rcv_ssthresh rb_define_method(cTCP_Info,"rcv_ssthresh",tcp_info_tcpi_rcv_ssthresh,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_RTT 1
#define HAVE_ST_TCPI_RTT 1
#define CFUNC_tcp_info_tcpi_rtt static VALUE tcp_info_tcpi_rtt(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_rtt);}
#define DEFINE_METHOD_tcp_info_tcpi_rtt rb_define_method(cTCP_Info,"rtt",tcp_info_tcpi_rtt,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_RTTVAR 1
#define HAVE_ST_TCPI_RTTVAR 1
#define CFUNC_tcp_info_tcpi_rttvar static VALUE tcp_info_tcpi_rttvar(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_rttvar);}
#define DEFINE_METHOD_tcp_info_tcpi_rttvar rb_define_method(cTCP_Info,"rttvar",tcp_info_tcpi_rttvar,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_SND_SSTHRESH 1
#define HAVE_ST_TCPI_SND_SSTHRESH 1
#define CFUNC_tcp_info_tcpi_snd_ssthresh static VALUE tcp_info_tcpi_snd_ssthresh(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_snd_ssthresh);}
#define DEFINE_METHOD_tcp_info_tcpi_snd_ssthresh rb_define_method(cTCP_Info,"snd_ssthresh",tcp_info_tcpi_snd_ssthresh,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_SND_CWND 1
#define HAVE_ST_TCPI_SND_CWND 1
#define CFUNC_tcp_info_tcpi_snd_cwnd static VALUE tcp_info_tcpi_snd_cwnd(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_snd_cwnd);}
#define DEFINE_METHOD_tcp_info_tcpi_snd_cwnd rb_define_method(cTCP_Info,"snd_cwnd",tcp_info_tcpi_snd_cwnd,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_ADVMSS 1
#define HAVE_ST_TCPI_ADVMSS 1
#define CFUNC_tcp_info_tcpi_advmss static VALUE tcp_info_tcpi_advmss(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_advmss);}
#define DEFINE_METHOD_tcp_info_tcpi_advmss rb_define_method(cTCP_Info,"advmss",tcp_info_tcpi_advmss,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_REORDERING 1
#define HAVE_ST_TCPI_REORDERING 1
#define CFUNC_tcp_info_tcpi_reordering static VALUE tcp_info_tcpi_reordering(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_reordering);}
#define DEFINE_METHOD_tcp_info_tcpi_reordering rb_define_method(cTCP_Info,"reordering",tcp_info_tcpi_reordering,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_RCV_RTT 1
#define HAVE_ST_TCPI_RCV_RTT 1
#define CFUNC_tcp_info_tcpi_rcv_rtt static VALUE tcp_info_tcpi_rcv_rtt(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_rcv_rtt);}
#define DEFINE_METHOD_tcp_info_tcpi_rcv_rtt rb_define_method(cTCP_Info,"rcv_rtt",tcp_info_tcpi_rcv_rtt,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_RCV_SPACE 1
#define HAVE_ST_TCPI_RCV_SPACE 1
#define CFUNC_tcp_info_tcpi_rcv_space static VALUE tcp_info_tcpi_rcv_space(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_rcv_space);}
#define DEFINE_METHOD_tcp_info_tcpi_rcv_space rb_define_method(cTCP_Info,"rcv_space",tcp_info_tcpi_rcv_space,0)
#define HAVE_STRUCT_TCP_INFO_TCPI_TOTAL_RETRANS 1
#define HAVE_ST_TCPI_TOTAL_RETRANS 1
#define CFUNC_tcp_info_tcpi_total_retrans static VALUE tcp_info_tcpi_total_retrans(VALUE self){\
	struct tcp_info *info = DATA_PTR(self);\
	return UINT2NUM((uint32_t)info->tcpi_total_retrans);}
#define DEFINE_METHOD_tcp_info_tcpi_total_retrans rb_define_method(cTCP_Info,"total_retrans",tcp_info_tcpi_total_retrans,0)
#define CFUNC_tcp_info_tcpi_snd_wnd static inline void tcp_info_tcpi_snd_wnd(void) {}
#define DEFINE_METHOD_tcp_info_tcpi_snd_wnd rb_define_method(cTCP_Info,"snd_wnd",rb_f_notimplement,0)
#define CFUNC_tcp_info_tcpi_snd_bwnd static inline void tcp_info_tcpi_snd_bwnd(void) {}
#define DEFINE_METHOD_tcp_info_tcpi_snd_bwnd rb_define_method(cTCP_Info,"snd_bwnd",rb_f_notimplement,0)
#define CFUNC_tcp_info_tcpi_snd_nxt static inline void tcp_info_tcpi_snd_nxt(void) {}
#define DEFINE_METHOD_tcp_info_tcpi_snd_nxt rb_define_method(cTCP_Info,"snd_nxt",rb_f_notimplement,0)
#define CFUNC_tcp_info_tcpi_rcv_nxt static inline void tcp_info_tcpi_rcv_nxt(void) {}
#define DEFINE_METHOD_tcp_info_tcpi_rcv_nxt rb_define_method(cTCP_Info,"rcv_nxt",rb_f_notimplement,0)
#define CFUNC_tcp_info_tcpi_toe_tid static inline void tcp_info_tcpi_toe_tid(void) {}
#define DEFINE_METHOD_tcp_info_tcpi_toe_tid rb_define_method(cTCP_Info,"toe_tid",rb_f_notimplement,0)
#define CFUNC_tcp_info_tcpi_snd_rexmitpack static inline void tcp_info_tcpi_snd_rexmitpack(void) {}
#define DEFINE_METHOD_tcp_info_tcpi_snd_rexmitpack rb_define_method(cTCP_Info,"snd_rexmitpack",rb_f_notimplement,0)
#define CFUNC_tcp_info_tcpi_rcv_ooopack static inline void tcp_info_tcpi_rcv_ooopack(void) {}
#define DEFINE_METHOD_tcp_info_tcpi_rcv_ooopack rb_define_method(cTCP_Info,"rcv_ooopack",rb_f_notimplement,0)
#define CFUNC_tcp_info_tcpi_snd_zerowin static inline void tcp_info_tcpi_snd_zerowin(void) {}
#define DEFINE_METHOD_tcp_info_tcpi_snd_zerowin rb_define_method(cTCP_Info,"snd_zerowin",rb_f_notimplement,0)
#define HAVE_GETPAGESIZE 1
#define HAVE_RB_THREAD_CALL_WITHOUT_GVL 1
#define HAVE_RB_THREAD_IO_BLOCKING_REGION 1
#define HAVE_GCC_ATOMIC_BUILTINS 1
#endif
