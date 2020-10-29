#!/bin/sh
. ./test-lib.sh
t_plan 9 "rack.hijack tests (Rack 1.5+ (Rack::VERSION >= [ 1,2]))"

t_begin "setup and start" && {
	unicorn_setup
	unicorn -D -c $unicorn_config hijack.ru
	unicorn_wait_start
}

t_begin "normal env reused between requests" && {
	env_a="$(curl -sSf http://$listen/normal_env_id)"
	b="$(curl -sSf http://$listen/normal_env_id)"
	test x"$env_a" = x"$b"
}

t_begin "check request hijack" && {
	test "xrequest.hijacked" = x"$(curl -sSfv http://$listen/hijack_req)"
}

t_begin "env changed after request hijack" && {
	env_b="$(curl -sSf http://$listen/normal_env_id)"
	test x"$env_a" != x"$env_b"
}

t_begin "check response hijack" && {
	test "xresponse.hijacked" = x"$(curl -sSfv http://$listen/hijack_res)"
}

t_begin "env changed after response hijack" && {
	env_c="$(curl -sSf http://$listen/normal_env_id)"
	test x"$env_b" != x"$env_c"
}

t_begin "env continues to be reused between requests" && {
	b="$(curl -sSf http://$listen/normal_env_id)"
	test x"$env_c" = x"$b"
}

t_begin "killing succeeds after hijack" && {
	kill $unicorn_pid
}

t_begin "check stderr for hijacked body close" && {
	check_stderr
	grep 'closed DieIfUsed 1\>' $r_err
	grep 'closed DieIfUsed 2\>' $r_err
	! grep 'closed DieIfUsed 3\>' $r_err
}

t_done
