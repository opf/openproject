#!/bin/sh
. ./test-lib.sh
t_plan 9 "OobGC test"

t_begin "setup and start" && {
	unicorn_setup
	unicorn -D -c $unicorn_config oob_gc.ru
	unicorn_wait_start
}

t_begin "test default interval (4 requests)" && {
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
}

t_begin "GC starting-request returns immediately" && {
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
}

t_begin "GC is started after 5 requests" && {
	test xtrue = x$(curl -vsSf http://$listen/ 2>> $tmp)
}

t_begin "reset GC" && {
	test xfalse = x$(curl -vsSf -X POST http://$listen/gc_reset 2>> $tmp)
}

t_begin "test default interval again (3 requests)" && {
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
}

t_begin "GC is started after 5 requests" && {
	test xtrue = x$(curl -vsSf http://$listen/ 2>> $tmp)
}

t_begin "killing succeeds" && {
	kill -QUIT $unicorn_pid
}

t_begin "check_stderr" && check_stderr
dbgcat r_err

t_done
