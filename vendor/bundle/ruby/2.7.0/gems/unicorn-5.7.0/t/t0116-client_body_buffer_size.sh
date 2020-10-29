#!/bin/sh
. ./test-lib.sh
t_plan 12 "client_body_buffer_size settings"

t_begin "setup and start" && {
	unicorn_setup
	rtmpfiles unicorn_config_tmp one_meg
	dd if=/dev/zero bs=1M count=1 of=$one_meg
	cat >> $unicorn_config <<EOF
after_fork do |server, worker|
  File.open("$fifo", "wb") { |fp| fp.syswrite "START" }
end
EOF
	cat $unicorn_config > $unicorn_config_tmp
	echo client_body_buffer_size 0 >> $unicorn_config
	unicorn -D -c $unicorn_config t0116.ru
	unicorn_wait_start
	fs_class=Unicorn::TmpIO
	mem_class=StringIO

	test x"$(cat $fifo)" = xSTART
}

t_begin "class for a zero-byte file should be StringIO" && {
	> $tmp
	test xStringIO = x"$(curl -T $tmp -sSf http://$listen/input_class)"
}

t_begin "class for a 1 byte file should be filesystem-backed" && {
	echo > $tmp
	test x$fs_class = x"$(curl -T $tmp -sSf http://$listen/tmp_class)"
}

t_begin "reload with default client_body_buffer_size" && {
	mv $unicorn_config_tmp $unicorn_config
	kill -HUP $unicorn_pid
	test x"$(cat $fifo)" = xSTART
}

t_begin "class for a 1 byte file should be memory-backed" && {
	echo > $tmp
	test x$mem_class = x"$(curl -T $tmp -sSf http://$listen/tmp_class)"
}

t_begin "class for a random blob file should be filesystem-backed" && {
	resp="$(curl -T random_blob -sSf http://$listen/tmp_class)"
	test x$fs_class = x"$resp"
}

t_begin "one megabyte file should be filesystem-backed" && {
	resp="$(curl -T $one_meg -sSf http://$listen/tmp_class)"
	test x$fs_class = x"$resp"
}

t_begin "reload with a big client_body_buffer_size" && {
	echo "client_body_buffer_size(1024 * 1024)" >> $unicorn_config
	kill -HUP $unicorn_pid
	test x"$(cat $fifo)" = xSTART
}

t_begin "one megabyte file should be memory-backed" && {
	resp="$(curl -T $one_meg -sSf http://$listen/tmp_class)"
	test x$mem_class = x"$resp"
}

t_begin "one megabyte + 1 byte file should be filesystem-backed" && {
	echo >> $one_meg
	resp="$(curl -T $one_meg -sSf http://$listen/tmp_class)"
	test x$fs_class = x"$resp"
}

t_begin "killing succeeds" && {
	kill $unicorn_pid
}

t_begin "check stderr" && {
	check_stderr
}

t_done
