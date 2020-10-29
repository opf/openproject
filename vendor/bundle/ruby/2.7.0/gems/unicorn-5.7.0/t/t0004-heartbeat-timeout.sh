#!/bin/sh
. ./test-lib.sh

t_plan 11 "heartbeat/timeout test"

t_begin "setup and startup" && {
	unicorn_setup
	echo timeout 3 >> $unicorn_config
	echo preload_app true >> $unicorn_config
	unicorn -D heartbeat-timeout.ru -c $unicorn_config
	unicorn_wait_start
}

t_begin "read worker PID" && {
	worker_pid=$(curl -sSf http://$listen/)
	t_info "worker_pid=$worker_pid"
}

t_begin "sleep for a bit, ensure worker PID does not change" && {
	sleep 4
	test $(curl -sSf http://$listen/) -eq $worker_pid
}

t_begin "block the worker process to force it to die" && {
	rm $ok
	t0=$(unix_time)
	err="$(curl -sSf http://$listen/block-forever 2>&1 || > $ok)"
	t1=$(unix_time)
	elapsed=$(($t1 - $t0))
	t_info "elapsed=$elapsed err=$err"
	test x"$err" != x"Should never get here"
	test x"$err" != x"$worker_pid"
}

t_begin "ensure worker was killed" && {
	test -e $ok
	test 1 -eq $(grep timeout $r_err | grep killing | count_lines)
}

t_begin "ensure timeout took at least 3 seconds" && {
	test $elapsed -ge 3
}

t_begin "we get a fresh new worker process" && {
	new_worker_pid=$(curl -sSf http://$listen/)
	test $new_worker_pid -ne $worker_pid
}

t_begin "truncate the server error log" && {
	> $r_err
}

t_begin "SIGSTOP and SIGCONT on unicorn master does not kill worker" && {
	kill -STOP $unicorn_pid
	sleep 4
	kill -CONT $unicorn_pid
	sleep 2
	test $new_worker_pid -eq $(curl -sSf http://$listen/)
}

t_begin "stop server" && {
	kill -QUIT $unicorn_pid
}

t_begin "check stderr" && check_stderr

dbgcat r_err

t_done
