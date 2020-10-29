#!/bin/sh
. ./test-lib.sh
t_plan 11 "existing UNIX domain socket check"

read_pid_unix () {
	x=$(printf 'GET / HTTP/1.0\r\n\r\n' | \
	    socat - UNIX:$unix_socket | \
	    tail -1)
	test -n "$x"
	y="$(expr "$x" : '\([0-9][0-9]*\)')"
	test x"$x" = x"$y"
	test -n "$y"
	echo "$y"
}

t_begin "setup and start" && {
	rtmpfiles unix_socket unix_config
	rm -f $unix_socket
	unicorn_setup
	grep -v ^listen < $unicorn_config > $unix_config
	echo "listen '$unix_socket'" >> $unix_config
	unicorn -D -c $unix_config pid.ru
	unicorn_wait_start
	orig_master_pid=$unicorn_pid
}

t_begin "get pid of worker" && {
	worker_pid=$(read_pid_unix)
	t_info "worker_pid=$worker_pid"
}

t_begin "fails to start with existing pid file" && {
	rm -f $ok
	unicorn -D -c $unix_config pid.ru || echo ok > $ok
	test x"$(cat $ok)" = xok
}

t_begin "worker pid unchanged" && {
	test x"$(read_pid_unix)" = x$worker_pid
	> $r_err
}

t_begin "fails to start with listening UNIX domain socket bound" && {
	rm $ok $pid
	unicorn -D -c $unix_config pid.ru || echo ok > $ok
	test x"$(cat $ok)" = xok
	> $r_err
}

t_begin "worker pid unchanged (again)" && {
	test x"$(read_pid_unix)" = x$worker_pid
}

t_begin "nuking the existing Unicorn succeeds" && {
	kill -9 $unicorn_pid
	while kill -0 $unicorn_pid
	do
		sleep 1
	done
	check_stderr
}

t_begin "succeeds in starting with leftover UNIX domain socket bound" && {
	test -S $unix_socket
	unicorn -D -c $unix_config pid.ru
	unicorn_wait_start
}

t_begin "worker pid changed" && {
	test x"$(read_pid_unix)" != x$worker_pid
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "no errors" && check_stderr

t_done
