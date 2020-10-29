#!/bin/sh
. ./test-lib.sh
t_plan 4 "rewindable_input toggled to true"

t_begin "setup and start" && {
	unicorn_setup
	echo rewindable_input true >> $unicorn_config
	unicorn -D -c $unicorn_config t0014.ru
	unicorn_wait_start
}

t_begin "ensure worker is started" && {
	test xOK = x$(curl -T t0014.ru -sSf http://$listen/)
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "check stderr" && {
	check_stderr
}

t_done
