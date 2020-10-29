#!/bin/sh
. ./test-lib.sh
t_plan 4 "rewindable_input toggled to false"

t_begin "setup and start" && {
	unicorn_setup
	echo rewindable_input false >> $unicorn_config
	unicorn -D -c $unicorn_config t0013.ru
	unicorn_wait_start
}

t_begin "ensure worker is started" && {
	test xOK = x$(curl -T t0013.ru -H Expect: -vsSf http://$listen/)
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "check stderr" && {
	check_stderr
}

t_done
