#!/bin/sh
. ./test-lib.sh

t_plan 15 "reopen rotated logs"

t_begin "setup and startup" && {
	rtmpfiles curl_out curl_err r_rot
	unicorn_setup
	unicorn -D t0006.ru -c $unicorn_config
	unicorn_wait_start
}

t_begin "ensure server is responsive" && {
	test xtrue = x$(curl -sSf http://$listen/ 2> $curl_err)
}

t_begin "ensure stderr log is clean" && check_stderr

t_begin "external log rotation" && {
	rm -f $r_rot
	mv $r_err $r_rot
}

t_begin "send reopen log signal (USR1)" && {
	kill -USR1 $unicorn_pid
}

t_begin "wait for rotated log to reappear" && {
	nr=60
	while ! test -f $r_err && test $nr -ge 0
	do
		sleep 1
		nr=$(( $nr - 1 ))
	done
}

t_begin "ensure server is still responsive" && {
	test xtrue = x$(curl -sSf http://$listen/ 2> $curl_err)
}

t_begin "wait for worker to reopen logs" && {
	nr=60
	re="worker=.* done reopening logs"
	while ! grep "$re" < $r_err >/dev/null && test $nr -ge 0
	do
		sleep 1
		nr=$(( $nr - 1 ))
	done
}

dbgcat r_rot
dbgcat r_err

t_begin "ensure no errors from curl" && {
	test ! -s $curl_err
}

t_begin "current server stderr is clean" && check_stderr

t_begin "rotated stderr is clean" && {
	check_stderr $r_rot
}

t_begin "server is now writing logs to new stderr" && {
	before_rot=$(count_bytes < $r_rot)
	before_err=$(count_bytes < $r_err)
	test xtrue = x$(curl -sSf http://$listen/ 2> $curl_err)
	after_rot=$(count_bytes < $r_rot)
	after_err=$(count_bytes < $r_err)
	test $after_rot -eq $before_rot
	test $after_err -gt $before_err
}

t_begin "stop server" && {
	kill $unicorn_pid
}

dbgcat r_err

t_begin "current server stderr is clean" && check_stderr
t_begin "rotated stderr is clean" && check_stderr $r_rot

t_done
