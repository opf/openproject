#!/bin/sh
. ./test-lib.sh
t_plan 3 "-N / --no-default-middleware option not supported in config.ru"

t_begin "setup and start" && {
	unicorn_setup
	RACK_ENV=development unicorn -D -c $unicorn_config t0301.ru
	unicorn_wait_start
}

t_begin "check switches parsed as expected and -N ignored for Rack::Lint" && {
	debug=false
	lint=
	eval "$(curl -sf http://$listen/vars)"
	test x"$debug" = xtrue
	test x"$lint" != x
	test -f "$lint"
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
	check_stderr
}

t_done
