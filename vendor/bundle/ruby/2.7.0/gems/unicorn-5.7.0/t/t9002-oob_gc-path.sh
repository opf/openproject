#!/bin/sh
. ./test-lib.sh
t_plan 12 "OobGC test with limited path"

t_begin "setup and start" && {
	unicorn_setup
	unicorn -D -c $unicorn_config oob_gc_path.ru
	unicorn_wait_start
}

t_begin "test default is noop" && {
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
}

t_begin "4 bad requests to bump counter" && {
	test xfalse = x$(curl -vsSf http://$listen/BAD 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/BAD 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/BAD 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/BAD 2>> $tmp)
}

t_begin "GC-starting request returns immediately" && {
	test xfalse = x$(curl -vsSf http://$listen/BAD 2>> $tmp)
}

t_begin "GC was started after 5 requests" && {
	test xtrue = x$(curl -vsSf http://$listen/ 2>> $tmp)
}

t_begin "reset GC" && {
	test xfalse = x$(curl -vsSf -X POST http://$listen/gc_reset 2>> $tmp)
}

t_begin "test default is noop" && {
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/ 2>> $tmp)
}

t_begin "4 bad requests to bump counter" && {
	test xfalse = x$(curl -vsSf http://$listen/BAD 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/BAD 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/BAD 2>> $tmp)
	test xfalse = x$(curl -vsSf http://$listen/BAD 2>> $tmp)
}

t_begin "GC-starting request returns immediately" && {
	test xfalse = x$(curl -vsSf http://$listen/BAD 2>> $tmp)
}

t_begin "GC was started after 5 requests" && {
	test xtrue = x$(curl -vsSf http://$listen/ 2>> $tmp)
}

t_begin "killing succeeds" && {
	kill -QUIT $unicorn_pid
}

t_begin "check_stderr" && check_stderr

t_done
