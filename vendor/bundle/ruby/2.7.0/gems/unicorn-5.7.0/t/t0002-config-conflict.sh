#!/bin/sh
. ./test-lib.sh
t_plan 6 "config variables conflict with preload_app"

t_begin "setup and start" && {
	unicorn_setup
	rtmpfiles ru rutmp

	cat > $ru <<\EOF
use Rack::ContentLength
use Rack::ContentType, "text/plain"
config = ru = { "hello" => "world" }
run lambda { |env| [ 200, {}, [ ru.inspect << "\n" ] ] }
EOF
	echo 'preload_app true' >> $unicorn_config
	unicorn -D -c $unicorn_config $ru
	unicorn_wait_start
}

t_begin "hit with curl" && {
	out=$(curl -sSf http://$listen/)
	test x"$out" = x'{"hello"=>"world"}'
}

t_begin "modify rackup file" && {
	sed -e 's/world/WORLD/' < $ru > $rutmp
	mv $rutmp $ru
}

t_begin "reload signal succeeds" && {
	kill -HUP $unicorn_pid
	while ! egrep '(done|error) reloading' < $r_err >/dev/null
	do
		sleep 1
	done

	grep 'done reloading' $r_err >/dev/null
}

t_begin "hit with curl" && {
	out=$(curl -sSf http://$listen/)
	test x"$out" = x'{"hello"=>"WORLD"}'
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_done
