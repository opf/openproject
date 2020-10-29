#!/bin/sh
. ./test-lib.sh

t_plan 4 "config.ru inside alt working_directory (no embedded switches)"

t_begin "setup and start" && {
	unicorn_setup
	rm -rf $t_pfx.app
	mkdir $t_pfx.app

	cat > $t_pfx.app/config.ru <<EOF
use Rack::ContentLength
use Rack::ContentType, "text/plain"
run lambda { |env| [ 200, {}, [ "#{\$master_ppid}\\n" ] ] }
EOF
	# the whole point of this exercise
	echo "working_directory '$t_pfx.app'" >> $unicorn_config

	# allows ppid to be 1 in before_fork
	echo "preload_app true" >> $unicorn_config
	cat >> $unicorn_config <<\EOF
before_fork do |server,worker|
  $master_ppid = Process.ppid # should be zero to detect daemonization
end
EOF

	cd /
	unicorn -D -c $unicorn_config
	unicorn_wait_start
}

t_begin "hit with curl" && {
	body=$(curl -sSf http://$listen/)
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "response body ppid == 1 (daemonized)" && {
	test "$body" -eq 1
}

t_done
