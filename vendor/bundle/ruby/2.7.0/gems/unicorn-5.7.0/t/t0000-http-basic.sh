#!/bin/sh
. ./test-lib.sh
t_plan 8 "simple HTTP connection tests"

t_begin "setup and start" && {
	unicorn_setup
	unicorn -D -c $unicorn_config env.ru
	unicorn_wait_start
}

t_begin "single request" && {
	curl -sSfv http://$listen/
}

t_begin "check stderr has no errors" && {
	check_stderr
}

t_begin "HTTP/0.9 request should not return headers" && {
	(
		printf 'GET /\r\n'
		cat $fifo > $tmp &
		wait
		echo ok > $ok
	) | socat - TCP:$listen > $fifo
}

t_begin "env.inspect should've put everything on one line" && {
	test 1 -eq $(count_lines < $tmp)
}

t_begin "no headers in output" && {
	if grep ^Connection: $tmp
	then
		die "Connection header found in $tmp"
	elif grep ^HTTP/ $tmp
	then
		die "HTTP/ found in $tmp"
	fi
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "check stderr has no errors" && {
	check_stderr
}

t_done
