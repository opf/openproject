#!/bin/sh
. ./test-lib.sh

t_plan 5 "Process.detach on forked background process works"

t_begin "setup and startup" && {
	t_fifos process_detach
	unicorn_setup
	TEST_FIFO=$process_detach \
	  unicorn -E none -D detach.ru -c $unicorn_config
	unicorn_wait_start
}

t_begin "read detached PID with HTTP/1.0" && {
	detached_pid=$(curl -0 -sSf http://$listen/)
	t_info "detached_pid=$detached_pid"
}

t_begin "read background FIFO" && {
	test xHIHI = x"$(cat $process_detach)"
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "check stderr" && check_stderr

t_done
