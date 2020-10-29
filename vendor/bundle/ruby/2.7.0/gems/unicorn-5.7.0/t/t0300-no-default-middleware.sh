#!/bin/sh
. ./test-lib.sh
t_plan 3 "test the -N / --no-default-middleware option"

t_begin "setup and start" && {
	unicorn_setup
	unicorn -N -D -c $unicorn_config fails-rack-lint.ru
	unicorn_wait_start
}

t_begin "check exit status with Rack::Lint not present" && {
	test 42 -eq "$(curl -sf -o/dev/null -w'%{http_code}' http://$listen/)"
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
	check_stderr
}

t_done
