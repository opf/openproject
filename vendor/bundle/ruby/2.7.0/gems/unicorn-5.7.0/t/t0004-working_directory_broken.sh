#!/bin/sh
. ./test-lib.sh

t_plan 3 "config.ru is missing inside alt working_directory"

t_begin "setup" && {
	unicorn_setup
	rtmpfiles unicorn_config_tmp ok
	rm -rf $t_pfx.app
	mkdir $t_pfx.app

	# the whole point of this exercise
	echo "working_directory '$t_pfx.app'" >> $unicorn_config_tmp
}

t_begin "fails to start up w/o config.ru" && {
	unicorn -c $unicorn_config_tmp || echo ok > $ok
}

t_begin "fallback code was run" && {
	test x"$(cat $ok)" = xok
}

t_done
