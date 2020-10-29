#!/bin/sh
. ./test-lib.sh

# Raindrops::Middleware depends on Unicorn.listener_names,
# ensure we don't break Raindrops::Middleware when preload_app is true

t_plan 4 "Unicorn.listener_names available with preload_app=true"

t_begin "setup and startup" && {
	unicorn_setup
	echo preload_app true >> $unicorn_config
	unicorn -E none -D listener_names.ru -c $unicorn_config
	unicorn_wait_start
}

t_begin "read listener names includes listener" && {
	resp=$(curl -sSf http://$listen/)
	ok=false
	t_info "resp=$resp"
	case $resp in
	*\"$listen\"*) ok=true ;;
	esac
	$ok
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "check stderr" && check_stderr

t_done
