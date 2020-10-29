#!/bin/sh
. ./test-lib.sh
t_plan 4 "configurator internals tests (from FAQ)"

t_begin "setup and start" && {
	unicorn_setup
	cat >> $unicorn_config <<EOF
HttpRequest::DEFAULTS["rack.url_scheme"] = "https"
Configurator::DEFAULTS[:logger].formatter = Logger::Formatter.new
EOF
	unicorn -D -c $unicorn_config env.ru
	unicorn_wait_start
}

t_begin "single request" && {
	curl -sSfv http://$listen/ | grep '"rack.url_scheme"=>"https"'
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "no errors" && check_stderr

t_done
