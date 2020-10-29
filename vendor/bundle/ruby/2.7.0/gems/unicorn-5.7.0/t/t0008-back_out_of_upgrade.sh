#!/bin/sh
. ./test-lib.sh
t_plan 13 "backout of USR2 upgrade"

worker_wait_start () {
	test xSTART = x"$(cat $fifo)"
	unicorn_pid=$(cat $pid)
}

t_begin "setup and start" && {
	unicorn_setup
	rm -f $pid.oldbin

cat >> $unicorn_config <<EOF
after_fork do |server, worker|
  # test script will block while reading from $fifo,
  # so notify the script on the first worker we spawn
  # by opening the FIFO
  if worker.nr == 0
    File.open("$fifo", "wb") { |fp| fp.syswrite "START" }
  end
end
EOF
	unicorn -D -c $unicorn_config pid.ru
	worker_wait_start
	orig_master_pid=$unicorn_pid
}

t_begin "read original worker pid" && {
	orig_worker_pid=$(curl -sSf http://$listen/)
	test -n "$orig_worker_pid" && kill -0 $orig_worker_pid
}

t_begin "upgrade to new master" && {
	kill -USR2 $orig_master_pid
}

t_begin "kill old worker" && {
	kill -WINCH $orig_master_pid
}

t_begin "wait for new worker to start" && {
	worker_wait_start
	test $unicorn_pid -ne $orig_master_pid
	new_master_pid=$unicorn_pid
}

t_begin "old master pid is stashed in $pid.oldbin" && {
	test -s "$pid.oldbin"
	test $orig_master_pid -eq $(cat $pid.oldbin)
}

t_begin "ensure old worker is no longer running" && {
	i=0
	while kill -0 $orig_worker_pid 2>/dev/null
	do
		i=$(( $i + 1 ))
		test $i -lt 600 || die "timed out"
		sleep 1
	done
}

t_begin "capture pid of new worker" && {
	new_worker_pid=$(curl -sSf http://$listen/)
}

t_begin "reload old master process" && {
	kill -HUP $orig_master_pid
	worker_wait_start
}

t_begin "gracefully kill new master and ensure it dies" && {
	kill -QUIT $new_master_pid
	i=0
	while kill -0 $new_worker_pid 2>/dev/null
	do
		i=$(( $i + 1 ))
		test $i -lt 600 || die "timed out"
		sleep 1
	done
}

t_begin "ensure $pid.oldbin does not exist" && {
	i=0
	while test -s $pid.oldbin
	do
		i=$(( $i + 1 ))
		test $i -lt 600 || die "timed out"
		sleep 1
	done
	while ! test -s $pid
	do
		i=$(( $i + 1 ))
		test $i -lt 600 || die "timed out"
		sleep 1
	done
}

t_begin "ensure $pid is correct" && {
	cur_master_pid=$(cat $pid)
	test $orig_master_pid -eq $cur_master_pid
}

t_begin "killing succeeds" && {
	kill $orig_master_pid
}

dbgcat r_err

t_done
